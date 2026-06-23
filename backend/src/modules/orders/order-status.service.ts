import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import {
  OrderNotFoundException,
  InvalidStatusTransitionException,
} from '../../common/exceptions';
import { assertValidTransition } from './utils/state-machine.util';
import { UpdateOrderStatusDto } from './dto';

@Injectable()
export class OrderStatusService {
  constructor(
    private prisma: PrismaService,
    private notif: NotificationsService,
  ) {}

  async updateStatus(
    orderId: string,
    adminId: string,
    storeId: string,
    dto: UpdateOrderStatusDto,
  ) {
    const order = await this.prisma.serviceOrder.findFirst({
      where: { id: orderId, storeId },
    });
    if (!order) throw new OrderNotFoundException();
    assertValidTransition(order.status, dto.status);

    if (dto.status === 'completed')
      throw new InvalidStatusTransitionException(order.status, 'completed');

    const newSla = [
      'device_received',
      'diagnosing',
      'waiting_approval',
    ].includes(dto.status)
      ? new Date(Date.now() + 24 * 60 * 60 * 1000)
      : dto.status === 'waiting_payment'
        ? new Date(Date.now() + 48 * 60 * 60 * 1000)
        : null;

    await this.prisma.$transaction(async (tx) => {
      if (dto.status === 'repairing' && order.status === 'waiting_sparepart') {
        const items = await tx.orderItem.findMany({
          where: { orderId, status: { in: ['confirmed', 'replaced'] } },
        });
        for (const item of items) {
          if (!item.sparepartId) continue;
          await tx.$queryRawUnsafe(
            `UPDATE spareparts SET qty = qty - 1, qty_reserved = qty_reserved - 1 WHERE id = $1 AND qty_reserved > 0`,
            item.sparepartId,
          );
        }
      }

      await tx.serviceOrder.update({
        where: { id: orderId },
        data: {
          status: dto.status as
            | 'device_received'
            | 'diagnosing'
            | 'waiting_approval'
            | 'waiting_sparepart'
            | 'repairing'
            | 'quality_check'
            | 'waiting_payment'
            | 'cancelled',
          ...(newSla && { slaDeadline: newSla, slaWarnedAt: null }),
        },
      });
      await tx.serviceTracking.create({
        data: {
          orderId,
          status: dto.status as
            | 'device_received'
            | 'diagnosing'
            | 'waiting_approval'
            | 'waiting_sparepart'
            | 'repairing'
            | 'quality_check'
            | 'waiting_payment'
            | 'cancelled',
          createdByType: 'store_admin',
          createdById: adminId,
          note: dto.note ?? null,
        },
      });
    });

    if (dto.status === 'waiting_payment') {
      const fullOrder = await this.prisma.serviceOrder.findUniqueOrThrow({
        where: { id: orderId },
        include: { user: true },
      });
      await this.notif.sendWaitingPayment(
        fullOrder.user.phoneNumber,
        fullOrder.user.fullName,
        fullOrder.orderNumber,
        Number(fullOrder.finalPrice),
      );
    }

    return { status: dto.status };
  }
}
