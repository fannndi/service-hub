import { Injectable, ConflictException, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { nanoid } from 'nanoid';
import * as bcrypt from 'bcrypt';
import { ConfigService } from '@nestjs/config';
import { OrderStatus } from '@prisma/client';

@Injectable()
export class OrderService {
  constructor(private prisma: PrismaService, private config: ConfigService) {}

  async createOrder(dto: {
    storeId: string;
    fullName: string;
    phoneNumber: string;
    deviceType: string;
    brand: string;
    deviceModel: string;
    deliveryMethod: string;
    deliveryAddress?: string;
    credentialPlain?: string;
    items: { sparepartId: string; serviceType: string; complaint: string }[];
  }) {
    return this.prisma.$transaction(async (tx) => {
      // Stealth account: find or create user
      let user = await tx.user.findUnique({ where: { phoneNumber: dto.phoneNumber } });
      if (!user) {
        const cost = this.config.get<number>('app.bcryptCost');
        const defaultPass = dto.credentialPlain || 'default123';
        const passwordHash = await bcrypt.hash(defaultPass, cost);
        user = await tx.user.create({
          data: {
            fullName: dto.fullName,
            phoneNumber: dto.phoneNumber,
            passwordHash,
            isFirstLogin: true,
            credentialPlainEnc: dto.credentialPlain ? Buffer.from(dto.credentialPlain).toString('base64') : null,
          },
        });
      }

      // Validate stock & reserve (Bug B2: qtyReserved += 1 per item)
      const orderNumber = `SG-${nanoid(6).toUpperCase()}`;
      let totalEstimasi = 0;
      const orderItems = [];

      for (const item of dto.items) {
        const sparepart = await tx.sparepart.findUnique({ where: { id: item.sparepartId } });
        if (!sparepart) throw new NotFoundException(`Sparepart ${item.sparepartId} tidak ditemukan`);
        if (sparepart.qty - sparepart.qtyReserved <= 0) {
          throw new ConflictException({ code: 'STOCK_UNAVAILABLE', message: `Stok ${sparepart.name} habis.` });
        }

        // Bug B1 fix: itemPrice dari sparepart.price, bukan 0
        totalEstimasi += sparepart.price;

        // Bug B2 fix: qtyReserved += 1
        await tx.sparepart.update({
          where: { id: item.sparepartId },
          data: { qtyReserved: { increment: 1 } },
        });

        orderItems.push({
          sparepartId: item.sparepartId,
          sparepartName: sparepart.name,
          serviceType: item.serviceType,
          complaint: item.complaint,
          itemPrice: sparepart.price,
          status: 'pending',
        });
      }

      const order = await tx.serviceOrder.create({
        data: {
          orderNumber,
          userId: user.id,
          storeId: dto.storeId,
          deviceType: dto.deviceType as any,
          brand: dto.brand,
          deviceModel: dto.deviceModel,
          deliveryMethod: dto.deliveryMethod as any,
          deliveryAddress: dto.deliveryAddress,
          totalEstimasi,
          status: 'waiting_device',
          paymentStatus: 'unpaid',
          items: { create: orderItems },
        },
        include: { items: true, user: true },
      });

      return { order, isNewCustomer: user.isFirstLogin };
    });
  }

  async approveOrder(orderId: string) {
    return this.prisma.$transaction(async (tx) => {
      const order = await tx.serviceOrder.findUnique({ where: { id: orderId }, include: { items: true } });
      if (!order) throw new NotFoundException('Order tidak ditemukan');
      if (order.status !== 'waiting_approval') throw new BadRequestException('Order tidak dalam status waiting_approval');

      // Bug B3 fix: decrement qty DAN qtyReserved
      for (const item of order.items) {
        if (item.status === 'confirmed' || item.status === 'replaced') {
          await tx.sparepart.update({
            where: { id: item.sparepartId },
            data: { qty: { decrement: 1 }, qtyReserved: { decrement: 1 } },
          });
        } else {
          // cancelled items: only decrement qtyReserved
          await tx.sparepart.update({
            where: { id: item.sparepartId },
            data: { qtyReserved: { decrement: 1 } },
          });
        }
      }

      return tx.serviceOrder.update({
        where: { id: orderId },
        data: { status: 'repairing', finalPrice: order.estimatedTotal ?? order.totalEstimasi },
        include: { items: true },
      });
    });
  }

  async rejectOrder(orderId: string) {
    return this.prisma.$transaction(async (tx) => {
      const order = await tx.serviceOrder.findUnique({ where: { id: orderId }, include: { items: true } });
      if (!order) throw new NotFoundException('Order tidak ditemukan');
      if (order.status !== 'waiting_approval') throw new BadRequestException('Order tidak dalam status waiting_approval');

      // Bug B3: reject hanya decrement qtyReserved, qty TIDAK berubah
      for (const item of order.items) {
        await tx.sparepart.update({
          where: { id: item.sparepartId },
          data: { qtyReserved: { decrement: 1 } },
        });
      }

      return tx.serviceOrder.update({
        where: { id: orderId },
        data: { status: 'cancelled' },
        include: { items: true },
      });
    });
  }

  async submitDiagnosis(orderId: string, dto: { diagnosisItems: { sparepartId: string; status: string; replacedSparepartId?: string }[]; serviceFee: number; note?: string }) {
    return this.prisma.$transaction(async (tx) => {
      const order = await tx.serviceOrder.findUnique({ where: { id: orderId } });
      if (!order) throw new NotFoundException('Order tidak ditemukan');
      if (order.status !== 'diagnosing') throw new BadRequestException('Order harus dalam status diagnosing');

      // Bug B11 fix: replaced wajib ada replacedSparepartId
      for (const item of dto.diagnosisItems) {
        if (item.status === 'replaced' && !item.replacedSparepartId) {
          throw new BadRequestException('Status replaced wajib memilih sparepart pengganti');
        }
        await tx.orderItem.update({
          where: { id: item.sparepartId },
          data: { status: item.status as any, replacedSparepartId: item.replacedSparepartId },
        });
      }

      // Hitung finalPrice
      const items = await tx.orderItem.findMany({ where: { orderId } });
      const itemTotal = items
        .filter((i) => i.status === 'confirmed' || i.status === 'replaced')
        .reduce((sum, i) => sum + i.itemPrice, 0);
      const finalPrice = itemTotal + dto.serviceFee;

      return tx.serviceOrder.update({
        where: { id: orderId },
        data: { status: 'waiting_approval', serviceFee: dto.serviceFee, finalPrice, diagnosisNote: dto.note },
        include: { items: true },
      });
    });
  }

  async updateStatus(orderId: string, status: OrderStatus) {
    if (status === 'completed') throw new BadRequestException('Tidak bisa langsung complete, gunakan confirmPayment');
    return this.prisma.serviceOrder.update({ where: { id: orderId }, data: { status }, include: { items: true } });
  }

  async getOrdersByStore(storeId: string) {
    return this.prisma.serviceOrder.findMany({ where: { storeId }, include: { items: true, user: true }, orderBy: { createdAt: 'desc' } });
  }

  async getOrdersByUser(userId: string) {
    return this.prisma.serviceOrder.findMany({ where: { userId }, include: { items: true }, orderBy: { createdAt: 'desc' } });
  }

  async getOrderDetail(orderId: string) {
    return this.prisma.serviceOrder.findUnique({ where: { id: orderId }, include: { items: true, user: true, payments: true, reviews: true } });
  }
}
