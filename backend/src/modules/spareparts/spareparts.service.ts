import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { StoreNotActiveException } from '../../common/exceptions';

@Injectable()
export class SparepartsService {
  constructor(private prisma: PrismaService) {}

  async findByStore(storeId: string) {
    return this.prisma.sparePart.findMany({
      where: { storeId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findAvailable(storeId: string, brand?: string, deviceModel?: string, partType?: string) {
    const where: any = {
      storeId,
      status: { not: 'discontinued' },
    };
    if (brand) where.brand = brand;
    if (deviceModel) where.deviceModel = deviceModel;
    if (partType) where.partType = partType;

    return this.prisma.sparePart.findMany({
      where,
      orderBy: { createdAt: 'desc' },
    });
  }

  async create(storeId: string, dto: {
    brand: string; deviceModel: string; partType: string;
    partName: string; price: number; qty: number; status?: string;
  }) {
    const store = await this.prisma.store.findUnique({ where: { id: storeId } });
    if (!store || !store.isActive) throw new StoreNotActiveException();

    return this.prisma.sparePart.create({
      data: {
        storeId, brand: dto.brand, deviceModel: dto.deviceModel,
        partType: dto.partType, partName: dto.partName,
        price: dto.price, qty: dto.qty,
        status: (dto.status as any) ?? 'available',
      },
    });
  }

  async update(id: string, storeId: string, dto: {
    price?: number; qty?: number; status?: string; partName?: string;
  }) {
    const sp = await this.prisma.sparePart.findFirst({ where: { id, storeId } });
    if (!sp) throw new StoreNotActiveException();

    return this.prisma.sparePart.update({
      where: { id },
      data: dto as any,
    });
  }

  async delete(id: string, storeId: string) {
    const sp = await this.prisma.sparePart.findFirst({ where: { id, storeId } });
    if (!sp) throw new StoreNotActiveException();

    return this.prisma.sparePart.delete({ where: { id } });
  }
}
