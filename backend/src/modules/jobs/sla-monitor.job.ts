import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { PrismaService } from '../../common/prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class SlaMonitorJob {
  private readonly logger = new Logger(SlaMonitorJob.name);

  constructor(
    private prisma: PrismaService,
    private notif: NotificationsService,
  ) {}

  @Cron('*/30 * * * * *')
  async monitorSla() {
    try {
      const now = new Date();
      const breached = await this.prisma.serviceOrder.findMany({
        where: {
          slaDeadline: { lt: now },
          slaWarnedAt: null,
          status: { notIn: ['completed', 'cancelled'] },
        },
        include: {
          store: { select: { phoneNumber: true, storeName: true, id: true } },
          user: { select: { phoneNumber: true, fullName: true } },
        },
      });

      for (const order of breached) {
        await this.prisma.$transaction(async (tx) => {
          await tx.serviceOrder.update({
            where: { id: order.id },
            data: { slaWarnedAt: now, slaBreachCount: { increment: 1 } },
          });

          await tx.serviceTracking.create({
            data: {
              orderId: order.id,
              status: order.status,
              createdByType: 'system',
              createdById: 'sla-monitor',
              note: `SLA breached. Breach count: ${order.slaBreachCount + 1}`,
            },
          });
        });

        await this.notif.send(
          order.store.phoneNumber,
          `⚠️ SLA untuk order ${order.orderNumber} sudah terlewati!`,
          'sla_breach',
        );

        if (order.user) {
          await this.notif.send(
            order.user.phoneNumber,
            `Maaf, proses order #${order.orderNumber} mengalami keterlambatan. Tim sedang menindaklanjuti.`,
            'sla_breach_customer',
          );
        }

        this.logger.warn(`SLA breached: ${order.orderNumber}`);
      }

      if (breached.length > 0) {
        this.logger.log(`SLA monitor: ${breached.length} orders breached`);
      }

      // Auto-cancel: T+24h post-deadline (BR-20, AC-29)
      const cancelThreshold = new Date(now.getTime() - 24 * 60 * 60 * 1000);
      const toCancel = await this.prisma.serviceOrder.findMany({
        where: {
          slaDeadline: { lt: cancelThreshold },
          slaWarnedAt: { not: null },
          status: { notIn: ['completed', 'cancelled', 'waiting_approval', 'disputed'] },
        },
        include: {
          items: true,
          store: { select: { phoneNumber: true, storeName: true } },
          user: { select: { phoneNumber: true, fullName: true } },
        },
      });

      for (const order of toCancel) {
        await this.prisma.$transaction(async (tx) => {
          for (const item of order.items) {
            if (!item.sparepartId) continue;
            if (['repairing', 'quality_check', 'waiting_payment'].includes(order.status)) {
              await tx.sparePart.update({
                where: { id: item.sparepartId },
                data: { qty: { increment: 1 } },
              });
            } else {
              await tx.sparePart.update({
                where: { id: item.sparepartId },
                data: { qtyReserved: { decrement: 1 } },
              });
            }
          }

          await tx.store.update({
            where: { id: order.storeId },
            data: { penaltyPoints: { increment: 1 } },
          });

          await tx.serviceOrder.update({
            where: { id: order.id },
            data: { status: 'cancelled', cancelledAt: now },
          });

          await tx.serviceTracking.create({
            data: {
              orderId: order.id,
              status: 'cancelled',
              createdByType: 'system',
              createdById: 'sla-monitor',
              note: 'Auto-cancelled: SLA expired +24h.',
            },
          });
        });

        await this.notif.send(
          order.store.phoneNumber,
          `🚫 Order ${order.orderNumber} auto-cancelled. SLA expired >24h. Penalti +1.`,
          'sla_auto_cancel',
        );

        this.logger.warn(`Auto-cancelled: ${order.orderNumber}`);
      }

      if (toCancel.length > 0) {
        this.logger.log(`SLA auto-cancel: ${toCancel.length} orders cancelled`);
      }
    } catch (err) {
      this.logger.error('SLA monitor error', err);
    }
  }
}
