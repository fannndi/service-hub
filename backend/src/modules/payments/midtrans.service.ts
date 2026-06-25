import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac } from 'crypto';
import { PrismaService } from '../../common/prisma/prisma.service';
import { AppConfig } from '../../config/configuration';

@Injectable()
export class MidtransService {
  constructor(
    private config: ConfigService<AppConfig>,
    private prisma: PrismaService,
  ) {}

  private get snapUrl() {
    return this.config.get('midtrans.snapUrl', { infer: true })!;
  }

  private get serverKey() {
    return this.config.get('midtrans.serverKey', { infer: true })!;
  }

  async createSnapToken(orderId: string, userId: string) {
    const order = await this.prisma.serviceOrder.findUnique({
      where: { id: orderId },
      include: { user: true },
    });
    if (!order || order.userId !== userId) throw new Error('Order not found');

    const grossAmount = Number(order.finalPrice ?? order.totalEstimasi);
    const body = {
      transaction_details: {
        order_id: `ORDER-${order.orderNumber}-${Date.now()}`,
        gross_amount: grossAmount,
      },
      credit_card: { secure: true },
      customer_details: {
        first_name: order.user.fullName,
        phone: order.user.phoneNumber,
      },
      expiry: {
        start_time: new Date().toISOString().replace(/T/, ' ').substring(0, 19) + ' +0700',
        unit: 'hour',
        duration: 24,
      },
    };

    const auth = Buffer.from(`${this.serverKey}:`).toString('base64');
    const res = await fetch(this.snapUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': `Basic ${auth}`,
      },
      body: JSON.stringify(body),
    });
    const data = await res.json() as { token?: string; redirect_url?: string; error_message?: string };
    if (!res.ok || data.error_message) {
      throw new Error(`Midtrans error: ${data.error_message || res.statusText}`);
    }
    return data;
  }

  verifyNotification(payload: Record<string, unknown>): boolean {
    const orderId = payload.order_id as string;
    const statusCode = payload.status_code as string;
    const grossAmount = payload.gross_amount as string;
    const serverKey = this.serverKey;
    const signature = payload.signature_key as string;
    const hash = createHmac('sha512', serverKey)
      .update(`${orderId}${statusCode}${grossAmount}${serverKey}`)
      .digest('hex');
    return hash === signature;
  }

  async processNotification(payload: Record<string, unknown>) {
    if (!this.verifyNotification(payload)) {
      throw new Error('Invalid signature');
    }

    const orderId = payload.order_id as string;
    const transactionStatus = payload.transaction_status as string;
    const fraudStatus = payload.fraud_status as string;
    const paymentType = payload.payment_type as string;

    // Extract actual order ID from prefixed format ORDER-XXXX-TIMESTAMP
    const orderNumber = orderId.replace(/^ORDER-/, '').replace(/-\d+$/, '');
    const order = await this.prisma.serviceOrder.findFirst({
      where: { orderNumber },
    });
    if (!order) throw new Error(`Order not found: ${orderNumber}`);

    let recordStatus: string;
    let paymentStatus: string;

    if (transactionStatus === 'capture') {
      if (fraudStatus === 'accept') {
        recordStatus = 'confirmed';
        paymentStatus = 'paid';
      } else {
        recordStatus = 'failed';
        paymentStatus = 'unpaid';
      }
    } else if (transactionStatus === 'settlement') {
      recordStatus = 'confirmed';
      paymentStatus = 'paid';
    } else if (['deny', 'cancel', 'expire'].includes(transactionStatus)) {
      recordStatus = 'failed';
      paymentStatus = 'unpaid';
    } else if (transactionStatus === 'refund' || transactionStatus === 'partial_refund') {
      recordStatus = 'refunded';
      paymentStatus = 'refunded';
    } else {
      recordStatus = 'pending';
      paymentStatus = 'unpaid';
    }

    if (recordStatus === 'confirmed') {
      const completedAt = new Date();
      await this.prisma.$transaction([
        this.prisma.payment.create({
          data: {
            orderId: order.id,
            userId: order.userId,
            amount: Number(payload.gross_amount ?? 0),
            paymentMethod: 'midtrans_other',
            paymentType: 'final_payment',
            status: 'confirmed',
            confirmedAt: completedAt,
            midtransOrderId: orderId,
            midtransTransactionId: payload.transaction_id as string,
            midtransPaymentType: paymentType,
          },
        }),
        this.prisma.serviceOrder.update({
          where: { id: order.id },
          data: { status: 'completed', paymentStatus: 'paid', completedAt },
        }),
        this.prisma.serviceTracking.create({
          data: {
            orderId: order.id,
            status: 'completed',
            createdByType: 'system',
            createdById: 'midtrans',
            note: `Pembayaran via Midtrans (${paymentType}) — ${transactionStatus}`,
          },
        }),
      ]);
    } else {
      await this.prisma.payment.create({
        data: {
          orderId: order.id,
          userId: order.userId,
          amount: Number(payload.gross_amount ?? 0),
          paymentMethod: 'midtrans_other',
          paymentType: 'final_payment',
          status: recordStatus as 'pending' | 'confirmed' | 'failed' | 'refunded',
          midtransOrderId: orderId,
          midtransTransactionId: payload.transaction_id as string,
          midtransPaymentType: paymentType,
        },
      });
    }

    return { status: recordStatus, paymentStatus };
  }
}
