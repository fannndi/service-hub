import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { CredentialService } from '../auth/credential.service';
import { NotificationsService } from '../notifications/notifications.service';
import { InAppNotificationsService } from '../notifications/in-app-notifications.service';
import {
  DeliveryAddressRequiredException,
  StoreNotActiveException,
  StockUnavailableException,
  CouponAlreadyUsedException,
  CouponExpiredException,
  CouponNotOwnedException,
} from '../../common/exceptions';
import { generateOrderNumber, normalizePhone } from '../../common/utils';
import { CreateOrderDto } from './dto';

@Injectable()
export class OrderCreationService {
  constructor(
    private prisma: PrismaService,
    private credentialService: CredentialService,
    private notif: NotificationsService,
    private appNotif: InAppNotificationsService,
  ) {}

  async createOrder(dto: CreateOrderDto) {
    if (dto.deliveryMethod === 'courier_pickup' && !dto.deliveryAddress)
      throw new DeliveryAddressRequiredException();

    const store = await this.prisma.store.findUnique({
      where: { id: dto.storeId },
    });
    if (!store || !store.isActive) throw new StoreNotActiveException();

    const itemData: Array<{
      serviceType: string;
      complaint: string;
      sparepartId?: string;
      itemPrice: number;
    }> = [];

    for (const item of dto.items) {
      let itemPrice = 0;
      if (item.sparepartId) {
        const sp = await this.prisma.sparePart.findUnique({
          where: { id: item.sparepartId },
        });
        if (!sp || sp.storeId !== dto.storeId)
          throw new StockUnavailableException();
        if (sp.qty - sp.qtyReserved <= 0) throw new StockUnavailableException();
        itemPrice = Number(sp.price);
      }
      itemData.push({
        serviceType: item.serviceType,
        complaint: item.complaint,
        sparepartId: item.sparepartId,
        itemPrice,
      });
    }

    let discountAmount = 0;
    let couponId: string | undefined;
    if (dto.couponCode) {
      const phone = normalizePhone(dto.phoneNumber);
      const user = await this.prisma.user.findUnique({
        where: { phoneNumber: phone },
      });
      const coupon = await this.prisma.coupon.findFirst({
        where: { code: dto.couponCode },
      });
      if (!coupon) throw new CouponAlreadyUsedException();
      if (coupon.isUsed) throw new CouponAlreadyUsedException();
      if (coupon.expiredAt <= new Date()) throw new CouponExpiredException();
      if (!user || coupon.userId !== user.id)
        throw new CouponNotOwnedException();
      discountAmount = Number(coupon.amount);
      couponId = coupon.id;
    }

    const { user, isNew, rawPass } = await this.credentialService.autoCreateAccount(
      dto.customerName,
      dto.phoneNumber,
    );

    const totalEstimasi = Math.max(
      0,
      itemData.reduce((sum, i) => sum + i.itemPrice, 0) - discountAmount,
    );

    const orderNumber = generateOrderNumber();

    const order = await this.prisma.$transaction(async (tx) => {
      for (const item of dto.items) {
        if (!item.sparepartId) continue;
        const result = await tx.$queryRawUnsafe<Array<{ id: string }>>(
          `UPDATE spareparts SET qty_reserved = qty_reserved + 1 WHERE id = $1 AND qty - qty_reserved > 0 RETURNING id`,
          item.sparepartId,
        );
        if (result.length === 0) throw new StockUnavailableException();
      }

      const o = await tx.serviceOrder.create({
        data: {
          userId: user.id,
          storeId: dto.storeId,
          orderNumber,
          deviceType: dto.deviceType as 'android' | 'ios',
          brand: dto.brand,
          deviceModel: dto.deviceModel,
          deliveryMethod: dto.deliveryMethod as 'walk_in' | 'courier_pickup',
          deliveryAddress: dto.deliveryAddress,
          totalEstimasi,
          discountAmount,
          couponId,
          slaDeadline: new Date(Date.now() + 24 * 60 * 60 * 1000),
          items: { create: itemData },
        },
        include: { items: true },
      });

      await tx.serviceTracking.create({
        data: {
          orderId: o.id,
          status: 'waiting_device',
          createdByType: 'customer',
          createdById: user.id,
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
            orderId: o.id,
            shipmentType: 'pickup',
            pickupAddress: dto.deliveryAddress!,
            destinationAddress: store.address,
            status: 'scheduled',
          },
        });
      }
      return o;
    });

    await this.notif.sendNewOrderToStore(store, order, user, isNew, rawPass);
    await this.appNotif.create({
      storeId: store.id,
      role: 'store_admin',
      title: 'Pesanan Baru',
      message: `Pesanan #${order.orderNumber} dari ${user.fullName}. ${order.deviceType} ${order.brand} ${order.deviceModel}.`,
      type: 'new_order',
      linkTo: `/store/orders/${order.id}`,
    });

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
}
