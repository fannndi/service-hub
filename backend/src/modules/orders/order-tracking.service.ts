import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { OrderNotFoundException } from '../../common/exceptions';
import { allowedActionsForStatus } from './utils/state-machine.util';

@Injectable()
export class OrderTrackingService {
  constructor(private prisma: PrismaService) {}

  async addStoreOrderTracking(
    orderId: string,
    adminId: string,
    storeId: string,
    status: string,
    note?: string,
  ) {
    const order = await this.prisma.serviceOrder.findFirst({
      where: { id: orderId, storeId },
    });
    if (!order) throw new OrderNotFoundException();

    return this.prisma.serviceTracking.create({
      data: {
        orderId,
        status: status as
          | 'waiting_device'
          | 'device_received'
          | 'diagnosing'
          | 'waiting_approval'
          | 'waiting_sparepart'
          | 'repairing'
          | 'quality_check'
          | 'waiting_payment'
          | 'completed'
          | 'cancelled'
          | 'disputed',
        createdByType: 'store_admin',
        createdById: adminId,
        note: note ?? null,
      },
    });
  }

  async markCredentialSent(orderId: string, storeId: string) {
    const order = await this.prisma.serviceOrder.findFirst({
      where: { id: orderId, storeId },
      include: { user: { select: { id: true } } },
    });
    if (!order) throw new OrderNotFoundException();

    await this.prisma.user.update({
      where: { id: order.user.id },
      data: { isCredentialSent: true, credentialPlainEnc: null },
    });

    return { message: 'Credential marked as sent.' };
  }

  buildCredentialPanel(user: {
    phoneNumber: string;
    credentialPlainEnc: string | null;
    isCredentialSent: boolean;
    createdAt: Date;
  }) {
    const isNewCustomer =
      user.credentialPlainEnc !== null && user.isCredentialSent === false;

    return {
      isNewCustomer: !!user.credentialPlainEnc,
      isCredentialSent: user.isCredentialSent,
      phoneNumber: user.phoneNumber,
      hasCredential: isNewCustomer,
      expiresAt: isNewCustomer
        ? new Date(user.createdAt.getTime() + 24 * 60 * 60 * 1000).toISOString()
        : null,
    };
  }

  withAllowedActions<T extends { status: string }>(
    order: T,
  ): T & { allowedActions: string[] } {
    return { ...order, allowedActions: allowedActionsForStatus(order.status) };
  }
}
