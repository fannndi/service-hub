import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { RedisService } from '../redis/redis.service';

export interface StoreMatchResult {
  storeId: string;
  storeName: string;
  address: string;
  phoneNumber: string;
  ratingAvg: number;
  totalCompleted: number;
  spareparts: Array<{
    id: string;
    partName: string;
    partType: string;
    price: number;
    availableQty: number;
    status: string;
  }>;
  estimatedCost: number;
}

interface StoreConfig {
  service_fee?: Record<string, number>;
  warranty_days?: number;
  diagnosis_fee?: number;
  low_stock_threshold?: number;
  deposit_required?: boolean;
  device_types?: { android: boolean; ios: boolean };
}

@Injectable()
export class StoreDiscoveryService {
  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
  ) {}

  async findAll(includeInactive = false, brand?: string, deviceModel?: string) {
    const cacheKey = `stores:all:${includeInactive}:${brand ?? '*'}:${deviceModel ?? '*'}`;
    const cached = await this.redis.get<any[]>(cacheKey);
    if (cached) return cached;

    const sparepartFilter: Record<string, unknown> = {};
    if (brand) sparepartFilter.brand = brand;
    if (deviceModel) sparepartFilter.deviceModel = deviceModel;

    const hasSparepartFilter = Object.keys(sparepartFilter).length > 0;

    const result = await this.prisma.store.findMany({
      where: {
        ...(includeInactive ? {} : { isActive: true }),
        ...(hasSparepartFilter ? { spareparts: { some: sparepartFilter } } : {}),
      },
      select: {
        id: true,
        storeName: true,
        address: true,
        phoneNumber: true,
        operationalHours: true,
        config: true,
        isActive: true,
        ratingAvg: true,
        totalCompleted: true,
      },
      orderBy: { ratingAvg: 'desc' },
    });

    await this.redis.set(cacheKey, result, 300);
    return result;
  }

  async matchStores(brand: string, deviceModel: string, partType?: string): Promise<StoreMatchResult[]> {
    const sparepartWhere: Record<string, unknown> = {
      brand,
      deviceModel,
      status: { not: 'discontinued' },
    };
    if (partType) sparepartWhere.partType = partType;

    const stores = await this.prisma.store.findMany({
      where: { isActive: true },
      select: {
        id: true,
        storeName: true,
        address: true,
        phoneNumber: true,
        ratingAvg: true,
        totalCompleted: true,
        config: true,
        spareparts: {
          where: sparepartWhere,
          select: {
            id: true,
            partName: true,
            partType: true,
            price: true,
            qty: true,
            qtyReserved: true,
            status: true,
          },
        },
      },
      orderBy: { ratingAvg: 'desc' },
    });

    const results: StoreMatchResult[] = [];
    for (const store of stores) {
      const availableParts = store.spareparts
        .filter((sp) => sp.qty - sp.qtyReserved > 0)
        .map((sp) => ({
          id: sp.id,
          partName: sp.partName,
          partType: sp.partType,
          price: Number(sp.price),
          availableQty: sp.qty - sp.qtyReserved,
          status: sp.status as string,
        }));

      if (availableParts.length === 0) continue;

      const config = store.config as StoreConfig;
      const serviceFee = partType ? Number(config?.service_fee?.[partType] ?? 0) : 0;

      results.push({
        storeId: store.id,
        storeName: store.storeName,
        address: store.address,
        phoneNumber: store.phoneNumber,
        ratingAvg: Number(store.ratingAvg),
        totalCompleted: store.totalCompleted,
        spareparts: availableParts,
        estimatedCost: availableParts[0].price + serviceFee,
      });
    }

    return results;
  }

  async getDeviceModels() {
    const results = await this.prisma.sparePart.findMany({
      where: { status: { not: 'discontinued' } },
      select: { brand: true, deviceModel: true },
      distinct: ['brand', 'deviceModel'],
      orderBy: [{ brand: 'asc' }, { deviceModel: 'asc' }],
    });

    const map = new Map<string, string[]>();
    for (const result of results) {
      if (!map.has(result.brand)) map.set(result.brand, []);
      map.get(result.brand)!.push(result.deviceModel);
    }

    return Array.from(map.entries()).map(([brand, models]) => ({ brand, models }));
  }

  async findById(id: string) {
    return this.prisma.store.findUniqueOrThrow({
      where: { id },
      select: {
        id: true,
        storeName: true,
        address: true,
        phoneNumber: true,
        operationalHours: true,
        config: true,
        isActive: true,
        ratingAvg: true,
        totalCompleted: true,
        penaltyPoints: true,
        verifiedAt: true,
        createdAt: true,
        reviews: {
          include: { user: { select: { id: true, fullName: true } } },
          orderBy: { createdAt: 'desc' },
          take: 10,
        },
      },
    });
  }

  async findSpareparts(storeId: string, brand?: string, deviceModel?: string, partType?: string) {
    const where: Record<string, unknown> = { storeId, status: { not: 'discontinued' } };
    if (brand) where.brand = brand;
    if (deviceModel) where.deviceModel = deviceModel;
    if (partType) where.partType = partType;

    return this.prisma.sparePart.findMany({ where, orderBy: { createdAt: 'desc' } });
  }
}
