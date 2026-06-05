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
          store: { select: { phoneNumber: true, storeName: true } },
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
    } catch (err) {
      this.logger.error('SLA monitor error', err);
    }
  }
}
