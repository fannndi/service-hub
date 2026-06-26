import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import {
  OrderNotFoundException,
  WarrantyExpiredException,
  DisputeAlreadyActiveException,
  StockUnavailableException,
} from '../../common/exceptions';
import { generateOrderNumber } from '../../common/utils';
import { CreateDisputeDto, RespondDisputeDto } from './dto/dispute.dto';

@Injectable()
export class DisputesService {
  constructor(
    private prisma: PrismaService,
    private notif: NotificationsService,
  ) {}

  async createDispute(orderId: string, userId: string, dto: CreateDisputeDto) {
    const order = await this.prisma.serviceOrder.findFirst({
      where: { id: orderId, userId, status: 'completed' },
      include: { store: true },
    });
    if (!order) throw new OrderNotFoundException();
    if (!order.warrantyExpiredAt || new Date() >= order.warrantyExpiredAt)
      throw new WarrantyExpiredException();

    const activeDispute = await this.prisma.dispute.findFirst({
      where: { orderId, status: { notIn: ['resolved', 'closed'] } },
    });
    if (activeDispute) throw new DisputeAlreadyActiveException();

    const dispute = await this.prisma.$transaction(async (tx) => {
      const d = await tx.dispute.create({
        data: {
          orderId,
          userId,
          storeId: order.storeId,
          disputeType: dto.disputeType as 'warranty_claim' | 'service_quality' | 'wrong_diagnosis' | 'other',
          description: dto.description,
          evidenceUrls: dto.evidenceUrls ?? [],
          slaDeadline: new Date(Date.now() + 24 * 60 * 60 * 1000),
        },
      });
      await tx.serviceOrder.update({
        where: { id: orderId },
        data: { status: 'disputed', slaDeadline: new Date(Date.now() + 24 * 60 * 60 * 1000) },
      });
      await tx.serviceTracking.create({
        data: {
          orderId,
          status: 'disputed',
          createdByType: 'customer',
          createdById: userId,
          note: `Klaim ${dto.disputeType} diajukan oleh pelanggan.`,
        },
      });
      return d;
    });

    await this.notif.send(
      order.store.phoneNumber,
      `Klaim garansi masuk untuk order ${order.orderNumber}. Respons dalam 24 jam.`,
      'dispute_created',
    );
    return dispute;
  }

  async respondDispute(disputeId: string, storeId: string, dto: RespondDisputeDto) {
    const dispute = await this.prisma.dispute.findFirst({
      where: { id: disputeId, storeId, status: 'open' },
      include: { order: { include: { user: true, store: true, items: true } } },
    });
    if (!dispute) throw new OrderNotFoundException();

    const newStatus = dto.decision === 'store_accepted' ? 'store_accepted' : 'store_rejected';

    await this.prisma.$transaction(async (tx) => {
      await tx.dispute.update({
        where: { id: disputeId },
        data: { status: newStatus as 'store_accepted' | 'store_rejected', storeResponse: dto.storeResponse, resolvedAt: new Date() },
      });

      if (dto.decision === 'store_accepted') {
        const orderNumber = generateOrderNumber();
        const warrantyOrderItems = dispute.order.items
          .filter((i) => i.status === 'confirmed' || i.status === 'replaced')
          .map((i) => ({
            serviceType: i.serviceType,
            complaint: 'Perbaikan ulang dalam garansi',
            sparepartId: i.sparepartId,
            itemPrice: 0,
          }));

        const warrantyOrder = await tx.serviceOrder.create({
          data: {
            userId: dispute.order.userId,
            storeId,
            orderNumber,
            deviceType: dispute.order.deviceType,
            brand: dispute.order.brand,
            deviceModel: dispute.order.deviceModel,
            deliveryMethod: dispute.order.deliveryMethod,
            deliveryAddress: dispute.order.deliveryAddress,
            totalEstimasi: 0,
            finalPrice: 0,
            isWarrantyOrder: true,
            parentOrderId: dispute.orderId,
            status: 'waiting_device',
            slaDeadline: new Date(Date.now() + 24 * 60 * 60 * 1000),
            items: { create: warrantyOrderItems },
          },
        });

        for (const item of warrantyOrderItems) {
          if (!item.sparepartId) continue;
          const result = await tx.$queryRawUnsafe<Array<{ id: string }>>(
            `UPDATE spareparts SET qty_reserved = qty_reserved + 1 WHERE id = $1 AND qty - qty_reserved > 0 RETURNING id`,
            item.sparepartId,
          );
          if (result.length === 0) {
            throw new StockUnavailableException();
          }
        }
        await tx.dispute.update({
          where: { id: disputeId },
          data: { warrantyOrderId: warrantyOrder.id },
        });
        await tx.serviceTracking.create({
          data: {
            orderId: warrantyOrder.id,
            status: 'waiting_device',
            createdByType: 'system',
            createdById: 'system',
            note: `Warranty order dari dispute ${disputeId}.`,
          },
        });
        await tx.serviceOrder.update({
          where: { id: dispute.orderId },
          data: { status: 'completed' },
        });
      }
    });

    await this.notif.send(
      dispute.order.user.phoneNumber,
      dto.decision === 'store_accepted'
        ? 'Klaim garansimu diterima! Order perbaikan ulang sudah dibuat.'
        : `Klaim garansimu ditolak. Alasan: ${dto.storeResponse}`,
      'dispute_responded',
    );

    return { status: newStatus };
  }

  async findMyDisputes(userId: string) {
    return this.prisma.dispute.findMany({
      where: { userId },
      include: { order: { select: { id: true, orderNumber: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findStoreDisputes(storeId: string) {
    return this.prisma.dispute.findMany({
      where: { storeId },
      include: {
        order: { select: { id: true, orderNumber: true } },
        user: { select: { id: true, fullName: true, phoneNumber: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }
}
