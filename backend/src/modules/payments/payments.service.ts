import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { InAppNotificationsService } from '../notifications/in-app-notifications.service';
import {
  OrderNotFoundException,
  InvalidStatusTransitionException,
  ProofRequiredException,
} from '../../common/exceptions';
import { CreatePaymentDto } from './dto/payment.dto';

interface StoreConfig {
  warranty_days?: number;
}

@Injectable()
export class PaymentsService {
  constructor(
    private prisma: PrismaService,
    private notif: NotificationsService,
    private appNotif: InAppNotificationsService,
  ) {}

  async createPayment(orderId: string, userId: string, dto: CreatePaymentDto) {
    if (dto.paymentMethod === 'transfer_bank' && !dto.proofUrl)
      throw new ProofRequiredException();

    const order = await this.prisma.serviceOrder.findFirst({
      where: { id: orderId, userId, status: 'waiting_payment' },
    });
    if (!order) throw new OrderNotFoundException();

    return this.prisma.payment.create({
      data: {
        orderId,
        userId,
        amount: dto.amount,
        paymentMethod: dto.paymentMethod as 'transfer_bank' | 'qris' | 'cash' | 'ewallet' | 'midtrans_va' | 'midtrans_qris' | 'midtrans_wallet' | 'midtrans_other',
        paymentType: dto.paymentType as 'deposit' | 'final_payment',
        proofUrl: dto.proofUrl,
        status: 'pending',
      },
    });
  }

  async confirmPayment(orderId: string, paymentId: string, adminId: string, storeId: string) {
    const payment = await this.prisma.payment.findFirst({
      where: { id: paymentId, orderId },
      include: { order: { include: { store: true, user: true } } },
    });
    if (!payment || payment.order.storeId !== storeId) throw new OrderNotFoundException();
    if (payment.order.status !== 'waiting_payment')
      throw new InvalidStatusTransitionException(payment.order.status, 'completed');

    const config = payment.order.store.config as StoreConfig;
    const warrantyDays: number = config.warranty_days ?? 30;
    const completedAt = new Date();
    const warrantyExpiredAt = new Date(completedAt.getTime() + warrantyDays * 24 * 60 * 60 * 1000);

    await this.prisma.$transaction(async (tx) => {
      const updated = await tx.payment.updateMany({
        where: { id: paymentId, status: 'pending' },
        data: { status: 'confirmed', confirmedBy: adminId, confirmedAt: new Date() },
      });
      if (updated.count === 0) return;
      await tx.serviceOrder.update({
        where: { id: orderId },
        data: { status: 'completed', paymentStatus: 'paid', completedAt, warrantyDays, warrantyExpiredAt },
      });
      await tx.store.update({
        where: { id: storeId },
        data: { totalCompleted: { increment: 1 } },
      });
      await tx.serviceTracking.create({
        data: {
          orderId,
          status: 'completed',
          createdByType: 'store_admin',
          createdById: adminId,
          note: 'Pembayaran dikonfirmasi. Order selesai.',
        },
      });
    });

    await this.notif.sendOrderCompleted(
      payment.order.user.phoneNumber,
      payment.order.user.fullName,
      payment.order.orderNumber,
      payment.order.deliveryMethod,
    );
    await this.appNotif.create({
      userId: payment.order.user.id,
      role: 'customer',
      title: 'Pesanan Selesai',
      message: `Pesanan #${payment.order.orderNumber} selesai! Terima kasih sudah menggunakan ServisGadget.`,
      type: 'completed',
      linkTo: `/orders/${orderId}`,
    });
    await this.appNotif.create({
      storeId,
      role: 'store_admin',
      title: 'Pembayaran Dikonfirmasi',
      message: `Pembayaran #${payment.order.orderNumber} dikonfirmasi. Order selesai.`,
      type: 'payment_confirmed',
      linkTo: `/store/orders/${orderId}`,
    });

    return { status: 'completed', warrantyDays, warrantyExpiredAt };
  }
}
