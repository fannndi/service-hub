import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';

@Injectable()
export class InAppNotificationsService {
  constructor(private prisma: PrismaService) {}

  async create(data: {
    userId?: string;
    supabaseUserId?: string;
    storeId?: string;
    role: string;
    title: string;
    message: string;
    type?: string;
    linkTo?: string;
  }) {
    let targetUserId = data.userId;
    if (data.role === 'customer' && data.supabaseUserId) {
      targetUserId = data.supabaseUserId;
    } else if (data.role === 'customer' && data.userId) {
      const user = await this.prisma.user.findUnique({ where: { id: data.userId }, select: { supabaseUserId: true } });
      if (user?.supabaseUserId) targetUserId = user.supabaseUserId;
    }
    return this.prisma.notification.create({
      data: {
        userId: targetUserId ?? null,
        storeId: data.storeId ?? null,
        role: data.role,
        title: data.title,
        message: data.message,
        type: data.type ?? 'info',
        linkTo: data.linkTo ?? null,
      },
    });
  }

  async findForUser(userId: string, role: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      this.prisma.notification.findMany({
        where: { userId, role },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.notification.count({ where: { userId, role } }),
    ]);
    return { items, total, page, limit };
  }

  async findForStore(storeId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      this.prisma.notification.findMany({
        where: { storeId },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.notification.count({ where: { storeId } }),
    ]);
    return { items, total, page, limit };
  }

  async broadcast(role: string, title: string, message: string, type = 'broadcast') {
    return this.prisma.notification.create({
      data: { role, title, message, type },
    });
  }

  async unreadCount(userId: string, role: string): Promise<number> {
    return this.prisma.notification.count({
      where: { userId, role, isRead: false },
    });
  }

  async unreadCountByStore(storeId: string): Promise<number> {
    return this.prisma.notification.count({
      where: { storeId, isRead: false },
    });
  }

  async markAsRead(id: string, userId: string) {
    await this.prisma.notification.updateMany({
      where: { id, userId },
      data: { isRead: true },
    });
  }

  async markStoreNotificationAsRead(id: string, storeId: string) {
    await this.prisma.notification.updateMany({
      where: { id, storeId },
      data: { isRead: true },
    });
  }

  async markAllRead(userId: string, role: string) {
    await this.prisma.notification.updateMany({
      where: { userId, role, isRead: false },
      data: { isRead: true },
    });
  }

  async markAllStoreRead(storeId: string) {
    await this.prisma.notification.updateMany({
      where: { storeId, isRead: false },
      data: { isRead: true },
    });
  }
}
