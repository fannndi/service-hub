import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';

@Injectable()
export class StoresService {
  constructor(private prisma: PrismaService) {}

  async findAll(includeInactive = false) {
    return this.prisma.store.findMany({
      where: includeInactive ? {} : { isActive: true },
      select: {
        id: true, storeName: true, address: true, phoneNumber: true,
        operationalHours: true, config: true, isActive: true,
        ratingAvg: true, totalCompleted: true,
      },
      orderBy: { ratingAvg: 'desc' },
    });
  }

  async findById(id: string) {
    return this.prisma.store.findUniqueOrThrow({
      where: { id },
      select: {
        id: true, storeName: true, address: true, phoneNumber: true,
        operationalHours: true, config: true, isActive: true,
        ratingAvg: true, totalCompleted: true, penaltyPoints: true,
        verifiedAt: true, createdAt: true,
      },
    });
  }

  async findSpareparts(storeId: string, brand?: string, deviceModel?: string, partType?: string) {
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

  async updateConfig(storeId: string, config: Record<string, any>) {
    return this.prisma.store.update({
      where: { id: storeId },
      data: { config },
      select: { id: true, config: true },
    });
  }
}
