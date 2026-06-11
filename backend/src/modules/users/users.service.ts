import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { OrderStatus } from '@prisma/client';
import { UpdateProfileDto } from './dto/user.dto';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async getProfile(userId: string) {
    return this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: {
        id: true,
        fullName: true,
        phoneNumber: true,
        avatarUrl: true,
        address: true,
        accountStatus: true,
        isFirstLogin: true,
        createdAt: true,
        updatedAt: true,
      },
    });
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    return this.prisma.user.update({
      where: { id: userId },
      data: dto,
      select: {
        id: true,
        fullName: true,
        phoneNumber: true,
        avatarUrl: true,
        address: true,
        accountStatus: true,
        isFirstLogin: true,
        createdAt: true,
        updatedAt: true,
      },
    });
  }

  async getCoupons(userId: string) {
    return this.prisma.coupon.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getSummary(userId: string) {
    const activeStatuses: OrderStatus[] = [
      'waiting_device',
      'device_received',
      'diagnosing',
      'waiting_approval',
      'waiting_sparepart',
      'repairing',
      'quality_check',
      'waiting_payment',
      'disputed',
    ];
    const [activeOrders, activeCoupons, activeWarranty] = await Promise.all([
      this.prisma.serviceOrder.count({
        where: { userId, status: { in: activeStatuses } },
      }),
      this.prisma.coupon.count({
        where: { userId, isUsed: false, expiredAt: { gt: new Date() } },
      }),
      this.prisma.serviceOrder.count({
        where: { userId, status: 'completed', warrantyExpiredAt: { gt: new Date() } },
      }),
    ]);
    return { activeOrders, activeCoupons, activeWarranty };
  }

  async getNotifications(userId: string) {
    return this.prisma.serviceTracking.findMany({
      where: {
        order: { userId },
        createdAt: { gt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) },
      },
      include: { order: { select: { orderNumber: true } } },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }
}
