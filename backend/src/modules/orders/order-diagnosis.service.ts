import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { InAppNotificationsService } from '../notifications/in-app-notifications.service';
import {
  OrderNotFoundException,
  InvalidStatusTransitionException,
  StockUnavailableException,
} from '../../common/exceptions';
import { assertValidTransition } from './utils/state-machine.util';
import { SubmitDiagnosisDto } from './dto';

@Injectable()
export class OrderDiagnosisService {
  constructor(
    private prisma: PrismaService,
    private notif: NotificationsService,
    private appNotif: InAppNotificationsService,
  ) {}

  async approveOrder(orderId: string, userId: string) {
    const order = await this.prisma.serviceOrder.findFirst({
      where: { id: orderId, userId },
      include: { items: true, store: true },
    });
    if (!order) throw new OrderNotFoundException();
    assertValidTransition(order.status, 'repairing');

    await this.prisma.$transaction(async (tx) => {
      for (const item of order.items) {
        if (!item.sparepartId) continue;
        if (item.status === 'cancelled') continue;
        const result = await tx.$queryRawUnsafe<Array<{ id: string }>>(
          `UPDATE spareparts SET qty = qty - 1, qty_reserved = qty_reserved - 1 WHERE id = $1 AND qty_reserved > 0 RETURNING id`,
          item.sparepartId,
        );
        if (result.length === 0) throw new StockUnavailableException();
      }
      await tx.serviceOrder.update({
        where: { id: orderId },
        data: { status: 'repairing', slaDeadline: null, slaWarnedAt: null },
      });
      await tx.serviceTracking.create({
        data: {
          orderId,
          status: 'repairing',
          createdByType: 'customer',
          createdById: userId,
          note: 'Pelanggan menyetujui diagnosa.',
        },
      });
    });

    await this.notif.send(
      order.store.phoneNumber,
      `Pelanggan menyetujui order ${order.orderNumber}. Segera mulai perbaikan!`,
      'order_approved',
    );
    await this.appNotif.create({
      storeId: order.store.id,
      role: 'store_admin',
      title: 'Pesanan Disetujui',
      message: `Pelanggan menyetujui diagnosa untuk #${order.orderNumber}. Segera mulai perbaikan!`,
      type: 'order_approved',
      linkTo: `/store/orders/${orderId}`,
    });
    return { status: 'repairing' };
  }

  async rejectOrder(orderId: string, userId: string) {
    const order = await this.prisma.serviceOrder.findFirst({
      where: { id: orderId, userId },
      include: { items: true },
    });
    if (!order) throw new OrderNotFoundException();
    assertValidTransition(order.status, 'cancelled');

    await this.prisma.$transaction(async (tx) => {
      for (const item of order.items) {
        if (!item.sparepartId) continue;
        await tx.sparePart.update({
          where: { id: item.sparepartId },
          data: { qtyReserved: { decrement: 1 } },
        });
      }
      await tx.serviceOrder.update({
        where: { id: orderId },
        data: { status: 'cancelled', cancelledAt: new Date() },
      });
      await tx.serviceTracking.create({
        data: {
          orderId,
          status: 'cancelled',
          createdByType: 'customer',
          createdById: userId,
          note: 'Pelanggan menolak diagnosa.',
        },
      });
    });
    return { status: 'cancelled' };
  }

  async submitDiagnosis(
    orderId: string,
    adminId: string,
    storeId: string,
    dto: SubmitDiagnosisDto,
  ) {
    const order = await this.prisma.serviceOrder.findFirst({
      where: { id: orderId, storeId, status: 'diagnosing' },
      include: { items: true, user: true },
    });
    if (!order) throw new OrderNotFoundException();

    const orderItemIds = new Set(order.items.map((i) => i.id));
    for (const diagItem of dto.items) {
      if (!orderItemIds.has(diagItem.orderItemId)) {
        throw new OrderNotFoundException();
      }
      if (diagItem.status === 'replaced' && !diagItem.replacedSparepartId) {
        throw new InvalidStatusTransitionException(
          'diagnosing',
          'waiting_approval',
        );
      }
    }

    if (dto.items.length !== order.items.length) {
      throw new InvalidStatusTransitionException(
        'diagnosing',
        'waiting_approval',
      );
    }

    let finalPrice = Number(dto.serviceFee);
    for (const diagItem of dto.items) {
      if (diagItem.status !== 'cancelled') {
        finalPrice += Number(diagItem.finalItemPrice);
      }
    }

    await this.prisma.$transaction(async (tx) => {
      for (const diagItem of dto.items) {
        const updateData: {
          status: 'confirmed' | 'replaced' | 'cancelled';
          finalItemPrice: number;
          technicianNote: string | null;
          sparepartId?: string;
        } = {
          status: diagItem.status as 'confirmed' | 'replaced' | 'cancelled',
          finalItemPrice: diagItem.finalItemPrice,
          technicianNote: diagItem.technicianNote ?? null,
        };

        if (diagItem.status === 'replaced' && diagItem.replacedSparepartId) {
          const oldItem = order.items.find(
            (i) => i.id === diagItem.orderItemId,
          );
          if (oldItem?.sparepartId) {
            await tx.$queryRawUnsafe(
              `UPDATE spareparts SET qty_reserved = qty_reserved - 1 WHERE id = $1 AND qty_reserved > 0`,
              oldItem.sparepartId,
            );
          }
          const result = await tx.$queryRawUnsafe<Array<{ id: string }>>(
            `UPDATE spareparts SET qty_reserved = qty_reserved + 1 WHERE id = $1 AND qty - qty_reserved > 0 RETURNING id`,
            diagItem.replacedSparepartId,
          );
          if (result.length === 0) throw new StockUnavailableException();
          updateData.sparepartId = diagItem.replacedSparepartId;
        }

        if (diagItem.status === 'cancelled') {
          const oldItem = order.items.find(
            (i) => i.id === diagItem.orderItemId,
          );
          if (oldItem?.sparepartId) {
            await tx.$queryRawUnsafe(
              `UPDATE spareparts SET qty_reserved = qty_reserved - 1 WHERE id = $1 AND qty_reserved > 0`,
              oldItem.sparepartId,
            );
          }
        }

        await tx.orderItem.update({
          where: { id: diagItem.orderItemId },
          data: updateData,
        });
      }

      await tx.serviceOrder.update({
        where: { id: orderId },
        data: {
          status: 'waiting_approval',
          finalPrice,
          serviceFee: dto.serviceFee,
          diagnosisNote: dto.diagnosisNote ?? null,
          slaDeadline: new Date(Date.now() + 24 * 60 * 60 * 1000),
          slaWarnedAt: null,
        },
      });
      await tx.serviceTracking.create({
        data: {
          orderId,
          status: 'waiting_approval',
          createdByType: 'store_admin',
          createdById: adminId,
          note: 'Diagnosa selesai, menunggu persetujuan pelanggan.',
        },
      });
    });

    await this.notif.sendDiagnosisResult(
      order.user.phoneNumber,
      order.user.fullName,
      order.orderNumber,
      finalPrice,
    );
    await this.appNotif.create({
      userId: order.user.id,
      role: 'customer',
      title: 'Diagnosa Selesai',
      message: `Diagnosa untuk #${order.orderNumber} sudah selesai. Total: Rp ${finalPrice.toLocaleString('id-ID')}. Silakan cek dan setujui di aplikasi.`,
      type: 'diagnosis_result',
      linkTo: `/orders/${orderId}`,
    });
    return { status: 'waiting_approval', finalPrice };
  }
}
