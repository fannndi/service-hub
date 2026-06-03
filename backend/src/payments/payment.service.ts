import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class PaymentService {
  constructor(private prisma: PrismaService) {}

  async createPayment(orderId: string, amount: number, method: string, type: string, proofUrl?: string) {
    return this.prisma.payment.create({
      data: {
        orderId,
        amount,
        paymentMethod: method as any,
        paymentType: type as any,
        proofUrl,
        status: 'pending',
      },
    });
  }

  async confirmPayment(paymentId: string, orderId: string, storeAdminId: string) {
    return this.prisma.$transaction(async (tx) => {
      const payment = await tx.payment.findUnique({ where: { id: paymentId } });
      if (!payment) throw new NotFoundException('Payment tidak ditemukan');
      if (payment.status !== 'pending') throw new BadRequestException('Payment sudah diproses');

      const order = await tx.serviceOrder.findUnique({ where: { id: orderId }, include: { store: true } });
      if (!order) throw new NotFoundException('Order tidak ditemukan');

      // Update payment
      await tx.payment.update({ where: { id: paymentId }, data: { status: 'confirmed', confirmedById: storeAdminId } });

      // Bug B7 fix: warrantyDays dari store config
      const storeConfig = order.store.config as any;
      const warrantyDays = storeConfig?.warranty_days ?? 30;
      const warrantyExpiredAt = new Date(Date.now() + warrantyDays * 24 * 60 * 60 * 1000);

      // Complete order
      return tx.serviceOrder.update({
        where: { id: orderId },
        data: {
          paymentStatus: 'paid',
          status: 'completed',
          warrantyDays,
          warrantyExpiredAt,
        },
      });
    });
  }
}
