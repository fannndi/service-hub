import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { AuthService } from '../auth/auth.service';
import { NotificationsService } from '../notifications/notifications.service';
import {
  DeliveryAddressRequiredException,
  StoreNotActiveException,
  StockUnavailableException,
  CouponAlreadyUsedException,
  CouponExpiredException,
  CouponNotOwnedException,
  OrderNotFoundException,
  InvalidStatusTransitionException,
} from '../../common/exceptions';
import { assertValidTransition } from './utils/state-machine.util';
import { customAlphabet } from 'nanoid';
import { normalizePhone } from '../auth/utils/password.util';

const nid = customAlphabet('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ', 6);

interface CreateOrderItemDto {
  serviceType: string;
  complaint: string;
  sparepartId?: string;
}

interface CreateOrderDto {
  storeId: string;
  deviceType: string;
  brand: string;
  deviceModel: string;
  deliveryMethod: string;
  deliveryAddress?: string;
  customerName: string;
  phoneNumber: string;
  items: CreateOrderItemDto[];
  couponCode?: string;
}

interface UpdateOrderStatusDto {
  status: string;
  note?: string;
}

interface DiagnosisItemDto {
  orderItemId: string;
  status: string;
  finalItemPrice: number;
  technicianNote?: string;
  replacedSparepartId?: string;
}

interface SubmitDiagnosisDto {
  serviceFee: number;
  diagnosisNote?: string;
  items: DiagnosisItemDto[];
}

@Injectable()
export class OrdersService {
  constructor(
    private prisma: PrismaService,
    private authService: AuthService,
    private notif: NotificationsService,
  ) {}

  async createOrder(dto: CreateOrderDto): Promise<any> {
    if (dto.deliveryMethod === 'courier_pickup' && !dto.deliveryAddress)
      throw new DeliveryAddressRequiredException();

    const store = await this.prisma.store.findUnique({ where: { id: dto.storeId } });
    if (!store || !store.isActive) throw new StoreNotActiveException();
    const config = store.config as any;

    const itemData: Array<{
      serviceType: string; complaint: string; sparepartId?: string; itemPrice: number;
    }> = [];
    for (const item of dto.items) {
      let itemPrice = 0;
      if (item.sparepartId) {
        const sp = await this.prisma.sparePart.findUnique({ where: { id: item.sparepartId } });
        if (!sp || sp.storeId !== dto.storeId) throw new StockUnavailableException();
        if (sp.qty - sp.qtyReserved <= 0) throw new StockUnavailableException();
        itemPrice = Number(sp.price);
      }
      itemPrice += Number(config.service_fee?.[item.serviceType] ?? 0);
      itemData.push({
        serviceType: item.serviceType, complaint: item.complaint,
        sparepartId: item.sparepartId, itemPrice,
      });
    }

    let discountAmount = 0;
    let couponId: string | undefined;
    if (dto.couponCode) {
      const phone = normalizePhone(dto.phoneNumber);
      const user = await this.prisma.user.findUnique({ where: { phoneNumber: phone } });
      const coupon = await this.prisma.coupon.findFirst({ where: { code: dto.couponCode } });
      if (!coupon) throw new CouponAlreadyUsedException();
      if (coupon.isUsed) throw new CouponAlreadyUsedException();
      if (coupon.expiredAt <= new Date()) throw new CouponExpiredException();
      if (!user || coupon.userId !== user.id) throw new CouponNotOwnedException();
      discountAmount = Number(coupon.amount);
      couponId = coupon.id;
    }

    const { user, isNew, rawPass } =
      await this.authService.autoCreateAccount(dto.customerName, dto.phoneNumber);

    const totalEstimasi = Math.max(
      0,
      itemData.reduce((sum, i) => sum + i.itemPrice, 0) - discountAmount,
    );

    const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const orderNumber = `SG-${dateStr}-${nid()}`;

    const order = await this.prisma.$transaction(async (tx) => {
      for (const item of dto.items) {
        if (!item.sparepartId) continue;
        const sp = await tx.sparePart.findUniqueOrThrow({ where: { id: item.sparepartId } });
        if (sp.qty - sp.qtyReserved <= 0) throw new StockUnavailableException();
        await tx.sparePart.update({
          where: { id: item.sparepartId },
          data: { qtyReserved: { increment: 1 } },
        });
      }

      const o = await tx.serviceOrder.create({
        data: {
          userId: user.id, storeId: dto.storeId, orderNumber,
          deviceType: dto.deviceType as any, brand: dto.brand, deviceModel: dto.deviceModel,
          deliveryMethod: dto.deliveryMethod as any, deliveryAddress: dto.deliveryAddress,
          totalEstimasi, discountAmount, couponId,
          slaDeadline: new Date(Date.now() + 24 * 60 * 60 * 1000),
          items: { create: itemData },
        },
        include: { items: true },
      });

      await tx.serviceTracking.create({
        data: {
          orderId: o.id, status: 'waiting_device',
          createdByType: 'customer', createdById: user.id,
          note: 'Order berhasil dibuat.',
        },
      });

      if (couponId) {
        await tx.coupon.update({
          where: { id: couponId },
          data: { isUsed: true, usedAt: new Date(), usedOnOrderId: o.id },
        });
      }

      if (dto.deliveryMethod === 'courier_pickup') {
        await tx.shipment.create({
          data: {
            orderId: o.id, shipmentType: 'pickup',
            pickupAddress: dto.deliveryAddress!, destinationAddress: store.address,
            status: 'scheduled',
          },
        });
      }
      return o;
    });

    await this.notif.sendNewOrderToStore(store, order, user, isNew, rawPass);

    return {
      id: order.id,
      orderNumber: order.orderNumber,
      status: order.status,
      totalEstimasi: order.totalEstimasi,
      isNewCustomer: isNew,
      message: isNew
        ? 'Order berhasil dibuat. Cek WhatsApp untuk info akun ServisGadget.'
        : 'Order berhasil dibuat.',
    };
  }

  async approveOrder(orderId: string, userId: string) {
    const order = await this.prisma.serviceOrder.findFirst({
      where: { id: orderId, userId },
      include: { items: { where: { status: 'confirmed' } }, store: true },
    });
    if (!order) throw new OrderNotFoundException();
    assertValidTransition(order.status, 'repairing');

    await this.prisma.$transaction(async (tx) => {
      for (const item of order.items) {
        if (!item.sparepartId) continue;
        const sp = await tx.sparePart.findUniqueOrThrow({ where: { id: item.sparepartId } });
        if (sp.qty < 1) throw new StockUnavailableException();
        await tx.sparePart.update({
          where: { id: item.sparepartId },
          data: { qty: { decrement: 1 }, qtyReserved: { decrement: 1 } },
        });
      }
      await tx.serviceOrder.update({
        where: { id: orderId },
        data: { status: 'repairing', slaDeadline: null, slaWarnedAt: null },
      });
      await tx.serviceTracking.create({
        data: {
          orderId, status: 'repairing', createdByType: 'customer',
          createdById: userId, note: 'Pelanggan menyetujui diagnosa.',
        },
      });
    });

    await this.notif.send(
      order.store.phoneNumber,
      `✅ Pelanggan menyetujui order ${order.orderNumber}. Segera mulai perbaikan!`,
      'order_approved',
    );
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
          orderId, status: 'cancelled', createdByType: 'customer',
          createdById: userId, note: 'Pelanggan menolak diagnosa.',
        },
      });
    });
    return { status: 'cancelled' };
  }

  async updateStatus(orderId: string, adminId: string, storeId: string, dto: UpdateOrderStatusDto) {
    const order = await this.prisma.serviceOrder.findFirst({
      where: { id: orderId, storeId },
    });
    if (!order) throw new OrderNotFoundException();
    assertValidTransition(order.status, dto.status);

    if (dto.status === 'completed')
      throw new InvalidStatusTransitionException(order.status, 'completed');

    const newSla = ['device_received', 'diagnosing', 'waiting_approval'].includes(dto.status)
      ? new Date(Date.now() + 24 * 60 * 60 * 1000)
      : dto.status === 'waiting_payment'
        ? new Date(Date.now() + 48 * 60 * 60 * 1000)
        : null;

    await this.prisma.$transaction(async (tx) => {
      if (dto.status === 'repairing' && order.status === 'waiting_sparepart') {
        const items = await tx.orderItem.findMany({
          where: { orderId, status: 'confirmed' },
        });
        for (const item of items) {
          if (!item.sparepartId) continue;
          await tx.sparePart.update({
            where: { id: item.sparepartId },
            data: { qty: { decrement: 1 }, qtyReserved: { decrement: 1 } },
          });
        }
      }

      await tx.serviceOrder.update({
        where: { id: orderId },
        data: {
          status: dto.status as any,
          ...(newSla && { slaDeadline: newSla, slaWarnedAt: null }),
        },
      });
      await tx.serviceTracking.create({
        data: {
          orderId, status: dto.status as any,
          createdByType: 'store_admin', createdById: adminId,
          note: dto.note ?? null,
        },
      });
    });

    if (dto.status === 'waiting_payment') {
      const fullOrder = await this.prisma.serviceOrder.findUniqueOrThrow({
        where: { id: orderId }, include: { user: true },
      });
      await this.notif.sendWaitingPayment(
        fullOrder.user.phoneNumber, fullOrder.user.fullName,
        fullOrder.orderNumber, Number(fullOrder.finalPrice));
    }

    return { status: dto.status };
  }

  async submitDiagnosis(
    orderId: string, adminId: string, storeId: string, dto: SubmitDiagnosisDto,
  ) {
    const order = await this.prisma.serviceOrder.findFirst({
      where: { id: orderId, storeId, status: 'diagnosing' },
      include: { items: true, user: true },
    });
    if (!order) throw new OrderNotFoundException();

    for (const diagItem of dto.items) {
      if (diagItem.status === 'replaced' && !diagItem.replacedSparepartId) {
        throw new InvalidStatusTransitionException(
          'diagnosing', 'waiting_approval');
      }
    }

    let finalPrice = Number(dto.serviceFee);
    for (const diagItem of dto.items) {
      if (diagItem.status !== 'cancelled') {
        finalPrice += Number(diagItem.finalItemPrice);
      }
    }

    await this.prisma.$transaction(async (tx) => {
      for (const diagItem of dto.items) {
        const updateData: any = {
          status: diagItem.status,
          finalItemPrice: diagItem.finalItemPrice,
          technicianNote: diagItem.technicianNote ?? null,
        };
        if (diagItem.status === 'replaced' && diagItem.replacedSparepartId) {
          const oldItem = order.items.find((i) => i.id === diagItem.orderItemId);
          if (oldItem?.sparepartId) {
            await tx.sparePart.update({
              where: { id: oldItem.sparepartId },
              data: { qtyReserved: { decrement: 1 } },
            });
          }
          const newSp = await tx.sparePart.findUniqueOrThrow({
            where: { id: diagItem.replacedSparepartId },
          });
          if (newSp.qty - newSp.qtyReserved <= 0) throw new StockUnavailableException();
          await tx.sparePart.update({
            where: { id: diagItem.replacedSparepartId },
            data: { qtyReserved: { increment: 1 } },
          });
          updateData.sparepartId = diagItem.replacedSparepartId;
        }
        if (diagItem.status === 'cancelled') {
          const oldItem = order.items.find((i) => i.id === diagItem.orderItemId);
          if (oldItem?.sparepartId) {
            await tx.sparePart.update({
              where: { id: oldItem.sparepartId },
              data: { qtyReserved: { decrement: 1 } },
            });
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
          orderId, status: 'waiting_approval', createdByType: 'store_admin',
          createdById: adminId, note: 'Diagnosa selesai, menunggu persetujuan pelanggan.',
        },
      });
    });

    await this.notif.sendDiagnosisResult(
      order.user.phoneNumber, order.user.fullName, order.orderNumber, finalPrice);
    return { status: 'waiting_approval', finalPrice };
  }

  async findMyOrders(userId: string) {
    return this.prisma.serviceOrder.findMany({
      where: { userId },
      include: { items: true, store: { select: { id: true, storeName: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findMyOrderById(userId: string, orderId: string) {
    const order = await this.prisma.serviceOrder.findFirst({
      where: { id: orderId, userId },
      include: {
        items: { include: { sparepart: true } },
        store: { select: { id: true, storeName: true, phoneNumber: true, address: true } },
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
    const where: any = { storeId };
    if (status) where.status = status;
    return this.prisma.serviceOrder.findMany({
      where,
      include: { items: true, user: { select: { id: true, fullName: true, phoneNumber: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findStoreOrderById(storeId: string, orderId: string) {
    const order = await this.prisma.serviceOrder.findFirst({
      where: { id: orderId, storeId },
      include: {
        items: { include: { sparepart: true } },
        user: { select: { id: true, fullName: true, phoneNumber: true, address: true, createdAt: true, isCredentialSent: true, credentialPlainEnc: true } },
        tracking: { orderBy: { createdAt: 'asc' } },
        payments: true,
        shipments: true,
        review: true,
        dispute: true,
      },
    });
    if (!order) throw new OrderNotFoundException();

    const credentialPanel = this.buildCredentialPanel(order.user);
    return { ...order, credentialPanel };
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
        createdByType: t.createdByType,
      })),
    };
  }

  async addStoreOrderTracking(orderId: string, adminId: string, storeId: string, status: string, note?: string) {
    const order = await this.prisma.serviceOrder.findFirst({
      where: { id: orderId, storeId },
    });
    if (!order) throw new OrderNotFoundException();

    return this.prisma.serviceTracking.create({
      data: {
        orderId,
        status: status as any,
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

  private buildCredentialPanel(user: any) {
    const isNewCustomer = user.credentialPlainEnc !== null && user.isCredentialSent === false;
    const credential = isNewCustomer
      ? {
          phone: user.phoneNumber,
          password: this.authService.getDecryptedCredential(user.credentialPlainEnc),
          expiresAt: new Date(user.createdAt.getTime() + 24 * 60 * 60 * 1000).toISOString(),
        }
      : null;

    return {
      isNewCustomer: !!user.credentialPlainEnc,
      isCredentialSent: user.isCredentialSent,
      credential,
    };
  }
}
