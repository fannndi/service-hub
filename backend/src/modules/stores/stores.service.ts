import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';

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
export class StoresService {
  constructor(private prisma: PrismaService) {}

  async findAll(includeInactive = false, brand?: string, deviceModel?: string) {
    const sparepartFilter: Record<string, unknown> = {};
    if (brand) sparepartFilter.brand = brand;
    if (deviceModel) sparepartFilter.deviceModel = deviceModel;

    const hasSparepartFilter = Object.keys(sparepartFilter).length > 0;

    return this.prisma.store.findMany({
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

  async getDashboard(storeId: string) {
    const store = await this.prisma.store.findUniqueOrThrow({ where: { id: storeId } });
    const orders = await this.prisma.serviceOrder.findMany({
      where: { storeId, status: { notIn: ['completed', 'cancelled'] } },
      select: { status: true },
    });

    const byStatus: Record<string, number> = {};
    for (const o of orders) {
      byStatus[o.status] = (byStatus[o.status] ?? 0) + 1;
    }

    const pendingPayments = await this.prisma.payment.count({
      where: { order: { storeId }, status: 'pending' },
    });
    const openDisputes = await this.prisma.dispute.count({
      where: { storeId, status: { notIn: ['resolved', 'closed'] } },
    });
    const monthStart = new Date();
    monthStart.setDate(1);
    monthStart.setHours(0, 0, 0, 0);
    const totalCompletedThisMonth = await this.prisma.serviceOrder.count({
      where: { storeId, status: 'completed', completedAt: { gte: monthStart } },
    });

    return {
      activeOrders: orders.length,
      byStatus,
      pendingPayments,
      openDisputes,
      ratingAvg: Number(store.ratingAvg),
      totalCompletedThisMonth,
    };
  }

  async updateConfig(storeId: string, config: Record<string, unknown>) {
    return this.prisma.store.update({
      where: { id: storeId },
      data: { config },
      select: { id: true, config: true },
    });
  }

  async getCustomers(storeId: string, search?: string) {
    const distinctUserIds = await this.prisma.serviceOrder.findMany({
      where: { storeId },
      select: { userId: true },
      distinct: ['userId'],
    });
    const ids = distinctUserIds.map((d) => d.userId);
    const where: Record<string, unknown> = { id: { in: ids } };
    if (search) {
      where.OR = [
        { fullName: { contains: search, mode: 'insensitive' } },
        { phoneNumber: { contains: search } },
      ];
    }
    return this.prisma.user.findMany({
      where,
      select: { id: true, fullName: true, phoneNumber: true, createdAt: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getPayments(storeId: string, status?: string) {
    return this.prisma.payment.findMany({
      where: {
        order: { storeId },
        ...(status ? { status: status as 'pending' | 'confirmed' | 'failed' | 'refunded' } : {}),
      },
      include: {
        order: { select: { id: true, orderNumber: true } },
        user: { select: { id: true, fullName: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getReviews(storeId: string) {
    return this.prisma.review.findMany({
      where: { storeId },
      include: {
        user: { select: { id: true, fullName: true } },
        order: { select: { id: true, orderNumber: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getStoreNotifications(storeId: string) {
    return this.prisma.serviceTracking.findMany({
      where: { order: { storeId }, createdByType: { not: 'store_admin' } },
      include: { order: { select: { id: true, orderNumber: true } } },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  async getStoreProfile(adminId: string) {
    const admin = await this.prisma.storeAdmin.findUniqueOrThrow({
      where: { id: adminId },
      include: { store: true },
    });
    return {
      id: admin.id,
      fullName: admin.fullName,
      phoneNumber: admin.phoneNumber,
      store: {
        id: admin.store.id,
        storeName: admin.store.storeName,
        address: admin.store.address,
        phoneNumber: admin.store.phoneNumber,
        operationalHours: admin.store.operationalHours,
        config: admin.store.config,
        isActive: admin.store.isActive,
      },
    };
  }

  async updateStoreProfile(adminId: string, storeId: string, dto: Record<string, unknown>) {
    const adminData: Record<string, unknown> = {};
    if (typeof dto.fullName === 'string') adminData.fullName = dto.fullName;

    const storeData: Record<string, unknown> = {};
    if (typeof dto.storeName === 'string') storeData.storeName = dto.storeName;
    if (dto.operationalHours !== undefined) storeData.operationalHours = dto.operationalHours;
    if (typeof dto.address === 'string') storeData.address = dto.address;
    if (typeof dto.phoneNumber === 'string') storeData.phoneNumber = dto.phoneNumber;

    await this.prisma.$transaction([
      this.prisma.storeAdmin.update({ where: { id: adminId }, data: adminData }),
      ...(Object.keys(storeData).length > 0
        ? [this.prisma.store.update({ where: { id: storeId }, data: storeData })]
        : []),
    ]);

    return this.getStoreProfile(adminId);
  }

  async getAnalytics(storeId: string) {
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

    const [totalOrders, completedOrders, cancelledOrders, avgRating, totalRevenue] = await Promise.all([
      this.prisma.serviceOrder.count({ where: { storeId, createdAt: { gte: thirtyDaysAgo } } }),
      this.prisma.serviceOrder.count({ where: { storeId, status: 'completed', completedAt: { gte: thirtyDaysAgo } } }),
      this.prisma.serviceOrder.count({ where: { storeId, status: 'cancelled', cancelledAt: { gte: thirtyDaysAgo } } }),
      this.prisma.review.aggregate({ where: { storeId, createdAt: { gte: thirtyDaysAgo } }, _avg: { rating: true } }),
      this.prisma.payment.aggregate({
        where: { order: { storeId }, status: 'confirmed', createdAt: { gte: thirtyDaysAgo } },
        _sum: { amount: true },
      }),
    ]);

    return {
      period: '30d',
      totalOrders,
      completedOrders,
      cancelledOrders,
      avgRating: avgRating._avg.rating ?? 0,
      totalRevenue: totalRevenue._sum.amount ?? 0,
    };
  }
}
