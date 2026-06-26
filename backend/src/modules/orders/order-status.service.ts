import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { InAppNotificationsService } from '../notifications/in-app-notifications.service';
import {
  OrderNotFoundException,
  InvalidStatusTransitionException,
} from '../../common/exceptions';
import { assertValidTransition } from './utils/state-machine.util';
import { UpdateOrderStatusDto } from './dto';
import { GuestOrdersService } from './guest-orders.service';

@Injectable()
export class OrderStatusService {
  constructor(
    private prisma: PrismaService,
    private notif: NotificationsService,
    private appNotif: InAppNotificationsService,
    private guestOrders: GuestOrdersService,
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
      if (dto.status === 'repairing' && ['waiting_sparepart', 'waiting_approval'].includes(order.status)) {
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

    const fullOrder = await this.prisma.serviceOrder.findUniqueOrThrow({
      where: { id: orderId },
      include: { user: true, store: true },
    });

    if (dto.status === 'device_received') {
      await this.guestOrders.activateGuestAccount(orderId, storeId);
      await this.appNotif.create({
        userId: fullOrder.user.id,
        role: 'customer',
        title: 'Perangkat Diterima Toko',
        message: `Toko ${fullOrder.store.storeName} sudah menerima perangkat kamu. Mereka akan segera melakukan diagnosa.`,
        type: 'device_received',
        linkTo: `/orders/${orderId}`,
      });
    }

    if (dto.status === 'waiting_payment') {
      await this.notif.sendWaitingPayment(
        fullOrder.user.phoneNumber,
        fullOrder.user.fullName,
        fullOrder.orderNumber,
        Number(fullOrder.finalPrice),
      );
      await this.appNotif.create({
        userId: fullOrder.user.id,
        role: 'customer',
        title: 'Tagihan Tersedia',
        message: `Pesanan #${fullOrder.orderNumber} sudah selesai diperbaiki. Total: Rp ${Number(fullOrder.finalPrice).toLocaleString('id-ID')}. Silakan lakukan pembayaran.`,
        type: 'waiting_payment',
        linkTo: `/orders/${orderId}/payment`,
      });
    }

    if (dto.status === 'diagnosing') {
      await this.appNotif.create({
        userId: fullOrder.user.id,
        role: 'customer',
        title: 'Sedang Diagnosa',
        message: `Toko sedang melakukan diagnosa untuk perangkat kamu.`,
        type: 'diagnosing',
        linkTo: `/orders/${orderId}`,
      });
    }

    if (dto.status === 'repairing') {
      await this.appNotif.create({
        userId: fullOrder.user.id,
        role: 'customer',
        title: 'Perbaikan Dimulai',
        message: `Perangkat kamu sedang dalam perbaikan. Kami akan kabari jika sudah selesai.`,
        type: 'repairing',
        linkTo: `/orders/${orderId}`,
      });
    }

    if (dto.status === 'quality_check') {
      await this.appNotif.create({
        userId: fullOrder.user.id,
        role: 'customer',
        title: 'Quality Check',
        message: `Perangkat sedang dalam tahap quality check sebelum dikembalikan.`,
        type: 'quality_check',
        linkTo: `/orders/${orderId}`,
      });
    }

    if (dto.status === 'cancelled') {
      await this.appNotif.create({
        userId: fullOrder.user.id,
        role: 'customer',
        title: 'Pesanan Dibatalkan',
        message: `Pesanan #${fullOrder.orderNumber} telah dibatalkan.`,
        type: 'cancelled',
        linkTo: `/orders/${orderId}`,
      });
    }

    return { status: dto.status };
  }
}
