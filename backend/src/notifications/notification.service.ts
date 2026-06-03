import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class NotificationService {
  constructor(private prisma: PrismaService) {}

  async createNotification(userId: string, title: string, message: string, data?: any) {
    // Phase 1 scope: Insert into DB, would push to BullMQ queue here
    return this.prisma.notification.create({
      data: {
        userId,
        title,
        message,
        data: data || {},
      },
    });
  }

  async getMyNotifications(userId: string) {
    return this.prisma.notification.findMany({ where: { userId }, orderBy: { createdAt: 'desc' } });
  }

  async markAsRead(id: string) {
    return this.prisma.notification.update({ where: { id }, data: { isRead: true } });
  }
}
