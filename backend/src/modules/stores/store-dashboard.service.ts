import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';

@Injectable()
export class StoreDashboardService {
  constructor(private prisma: PrismaService) {}

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
      data: { config: config as any },
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
