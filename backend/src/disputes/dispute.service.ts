import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class DisputeService {
  constructor(private prisma: PrismaService) {}

  async createDispute(orderId: string, userId: string, disputeType: string, description: string, evidenceUrls: string[]) {
    const order = await this.prisma.serviceOrder.findUnique({ where: { id: orderId } });
    if (!order) throw new NotFoundException('Order tidak ditemukan');
    if (!order.warrantyExpiredAt || order.warrantyExpiredAt < new Date()) {
      throw new ConflictException({ code: 'WARRANTY_EXPIRED', message: 'Masa garansi sudah berakhir.' });
    }

    const active = await this.prisma.dispute.findFirst({ where: { orderId, status: { notIn: ['closed', 'resolved', 'store_rejected'] } } });
    if (active) throw new ConflictException({ code: 'DISPUTE_ALREADY_ACTIVE', message: 'Sudah ada klaim aktif.' });

    return this.prisma.dispute.create({
      data: {
        orderId,
        userId,
        storeId: order.storeId,
        disputeType: disputeType as any,
        description,
        evidenceUrls,
        status: 'open',
      },
    });
  }

  async respondDispute(disputeId: string, storeAdminId: string, accept: boolean, reason?: string) {
    return this.prisma.$transaction(async (tx) => {
      const dispute = await tx.dispute.findUnique({ where: { id: disputeId } });
      if (!dispute) throw new NotFoundException('Dispute tidak ditemukan');

      if (!accept) {
        if (!reason || reason.length < 10) throw new ConflictException('Alasan penolakan minimal 10 karakter');
        return tx.dispute.update({ where: { id: disputeId }, data: { status: 'store_rejected', resolutionNote: reason } });
      }

      await tx.dispute.update({ where: { id: disputeId }, data: { status: 'store_accepted', resolutionNote: reason } });
      await tx.serviceOrder.update({ where: { id: dispute.orderId }, data: { status: 'disputed' } });

      return dispute;
    });
  }
}
