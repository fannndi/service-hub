import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import {
  OrderNotFoundException,
  InvalidStatusTransitionException,
  ProofRequiredException,
} from '../../common/exceptions';

interface CreatePaymentDto {
  amount: number;
  paymentMethod: string;
  paymentType: string;
  proofUrl?: string;
}

@Injectable()
export class PaymentsService {
  constructor(
    private prisma: PrismaService,
    private notif: NotificationsService,
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
        orderId, userId,
        amount: dto.amount,
        paymentMethod: dto.paymentMethod as any,
        paymentType: dto.paymentType as any,
        proofUrl: dto.proofUrl,
        status: 'pending',
      },
    });
  }

  async confirmPayment(
    orderId: string, paymentId: string, adminId: string, storeId: string,
  ) {
    const payment = await this.prisma.payment.findFirst({
      where: { id: paymentId, orderId },
      include: {
        order: {
          include: { store: true, user: true },
        },
      },
    });
    if (!payment || payment.order.storeId !== storeId)
      throw new OrderNotFoundException();
    if (payment.order.status !== 'waiting_payment')
      throw new InvalidStatusTransitionException(payment.order.status, 'completed');

    const config = payment.order.store.config as any;
    const warrantyDays: number = config.warranty_days ?? 30;
    const completedAt = new Date();
    const warrantyExpiredAt = new Date(
      completedAt.getTime() + warrantyDays * 24 * 60 * 60 * 1000);

    await this.prisma.$transaction([
      this.prisma.payment.update({
        where: { id: paymentId },
        data: { status: 'confirmed', confirmedBy: adminId, confirmedAt: new Date() },
      }),
      this.prisma.serviceOrder.update({
        where: { id: orderId },
        data: {
          status: 'completed',
          paymentStatus: 'paid',
          completedAt,
          warrantyDays,
          warrantyExpiredAt,
        },
      }),
      this.prisma.store.update({
        where: { id: storeId },
        data: { totalCompleted: { increment: 1 } },
      }),
      this.prisma.serviceTracking.create({
        data: {
          orderId, status: 'completed', createdByType: 'store_admin',
          createdById: adminId, note: 'Pembayaran dikonfirmasi. Order selesai.',
        },
      }),
    ]);

    await this.notif.sendOrderCompleted(
      payment.order.user.phoneNumber, payment.order.user.fullName,
      payment.order.orderNumber, payment.order.deliveryMethod);

    return { status: 'completed', warrantyDays, warrantyExpiredAt };
  }
}
