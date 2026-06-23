import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { OrderNotFoundException } from '../../common/exceptions';
import { OrderTrackingService } from './order-tracking.service';

@Injectable()
export class OrderQueryService {
  constructor(
    private prisma: PrismaService,
    private trackingService: OrderTrackingService,
  ) {}

  async findMyOrders(userId: string) {
    return this.prisma.serviceOrder.findMany({
      where: { userId },
      include: {
        items: true,
        store: { select: { id: true, storeName: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findMyOrderById(userId: string, orderId: string) {
    const order = await this.prisma.serviceOrder.findFirst({
      where: { id: orderId, userId },
      include: {
        items: { include: { sparepart: true } },
        store: {
          select: {
            id: true,
            storeName: true,
            phoneNumber: true,
            address: true,
          },
        },
        tracking: { orderBy: { createdAt: 'asc' } },
        payments: true,
        shipments: true,
        review: true,
        dispute: true,
      },
    });
    if (!order) throw new OrderNotFoundException();
    return order;
  }

  async findStoreOrders(storeId: string, status?: string) {
    const where: Record<string, unknown> = { storeId };
    if (status) where.status = status;
    const orders = await this.prisma.serviceOrder.findMany({
      where,
      include: {
        items: true,
        user: { select: { id: true, fullName: true, phoneNumber: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
    return orders.map((order) => this.trackingService.withAllowedActions(order));
  }

  async findStoreOrderById(storeId: string, orderId: string) {
    const order = await this.prisma.serviceOrder.findFirst({
      where: { id: orderId, storeId },
      include: {
        items: { include: { sparepart: true } },
        user: {
          select: {
            id: true,
            fullName: true,
            phoneNumber: true,
            address: true,
            createdAt: true,
            isCredentialSent: true,
            credentialPlainEnc: true,
          },
        },
        tracking: { orderBy: { createdAt: 'asc' } },
        payments: true,
        shipments: true,
        review: true,
        dispute: true,
      },
    });
    if (!order) throw new OrderNotFoundException();

    const credentialPanel = this.trackingService.buildCredentialPanel(order.user);
    return this.trackingService.withAllowedActions({ ...order, credentialPanel });
  }

  async getOrderProgress(userId: string, orderId: string) {
    const order = await this.prisma.serviceOrder.findFirst({
      where: { id: orderId, userId },
      select: { id: true },
    });
    if (!order) throw new OrderNotFoundException();

    const tracking = await this.prisma.serviceTracking.findMany({
      where: { orderId },
      orderBy: { createdAt: 'desc' },
    });

    return {
      orderId,
      status: tracking[0]?.status ?? 'waiting_device',
      timeline: tracking.map((t) => ({
        status: t.status,
        note: t.note,
        createdAt: t.createdAt,
      })),
    };
  }

  async getStoreOrderTracking(storeId: string, orderId: string) {
    const order = await this.prisma.serviceOrder.findFirst({
      where: { id: orderId, storeId },
      select: { id: true },
    });
    if (!order) throw new OrderNotFoundException();

    const tracking = await this.prisma.serviceTracking.findMany({
      where: { orderId },
      orderBy: { createdAt: 'desc' },
    });

    return {
      orderId,
      status: tracking[0]?.status ?? 'waiting_device',
      timeline: tracking.map((t) => ({
        status: t.status,
        note: t.note,
        createdAt: t.createdAt,
      })),
    };
  }
}
