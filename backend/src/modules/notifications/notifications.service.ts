import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../common/prisma/prisma.service';
import axios from 'axios';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private config: ConfigService,
    private prisma: PrismaService,
  ) {}

  async send(target: string, message: string, messageType: string): Promise<void> {
    const delays = [60_000, 300_000, 900_000];
    for (let attempt = 1; attempt <= 3; attempt++) {
      try {
        await axios.post(
          this.config.get<string>('wa.gatewayUrl')!,
          { target, message, countryCode: '62' },
          { headers: { Authorization: this.config.get('wa.token') }, timeout: 10_000 },
        );
        return;
      } catch (err: any) {
        this.logger.warn(`WA attempt ${attempt}/3 gagal -> ${target}: ${err.message}`);
        if (attempt < 3) await new Promise((r) => setTimeout(r, delays[attempt - 1]));
        else {
          await this.prisma.failedNotification
            .create({
              data: {
                recipientType: 'whatsapp',
                recipientId: target,
                messageType,
                payload: { target, message },
                attemptCount: 3,
                lastError: err.message,
              },
            })
            .catch((e) => this.logger.error('Log failed notif error:', e));
        }
      }
    }
  }

  async sendNewOrderToStore(
    store: any,
    order: any,
    user: any,
    isNew: boolean,
    rawPass?: string,
  ) {
    const lines = [
      `🔔 *Order Baru!*`,
      `No: ${order.orderNumber}`,
      `Pelanggan: ${user.fullName} (${user.phoneNumber})`,
      `Device: ${order.deviceType} ${order.brand} ${order.deviceModel}`,
      `Metode: ${order.deliveryMethod === 'walk_in' ? 'Walk-in' : 'Kurir'}`,
      `Estimasi: Rp ${Number(order.totalEstimasi).toLocaleString('id-ID')}`,
    ];
    if (order.deliveryAddress) lines.push(`Alamat: ${order.deliveryAddress}`);
    lines.push(`---`);
    lines.push(`Segera cek dashboard untuk detail.`);
    await this.send(store.phoneNumber, lines.join('\n'), 'new_order');

    if (isNew && rawPass) {
      const customerMsg = [
        `Halo ${user.fullName}!`,
        `Akun ServisGadget kamu sudah dibuat otomatis.`,
        `Nomor HP: ${user.phoneNumber}`,
        `Password sementara: ${rawPass}`,
        `---`,
        `Segera login dan ganti passwordmu.`,
        `Order #${order.orderNumber} akan segera diproses.`,
      ].join('\n');
      await this.send(user.phoneNumber, customerMsg, 'stealth_account');
    }
  }

  async sendWaitingPayment(phone: string, name: string, orderNumber: string, finalPrice: number) {
    const msg = [
      `Halo ${name}!`,
      `Pesanan #${orderNumber} sudah selesai diperbaiki.`,
      `Total biaya: Rp ${finalPrice.toLocaleString('id-ID')}`,
      `---`,
      `Silakan lakukan pembayaran untuk menyelesaikan pesanan.`,
    ].join('\n');
    await this.send(phone, msg, 'waiting_payment');
  }

  async sendDiagnosisResult(
    phone: string,
    name: string,
    orderNumber: string,
    finalPrice: number,
  ) {
    const msg = [
      `Halo ${name}!`,
      `Diagnosa untuk #${orderNumber} sudah berhasil.`,
      `Total biaya: Rp ${finalPrice.toLocaleString('id-ID')}`,
      `---`,
      `Silakan cek aplikasi untuk menyetujui atau menolak diagnosa.`,
    ].join('\n');
    await this.send(phone, msg, 'diagnosis_result');
  }

  async sendOrderCompleted(phone: string, name: string, orderNumber: string, deliveryMethod: string) {
    const msg = [
      `Halo ${name}!`,
      `Pembayaran untuk #${orderNumber} dikonfirmasi. Pesanan selesai.`,
      deliveryMethod === 'walk_in'
        ? `Silakan ambil perangkatmu di toko.`
        : `Perangkat akan segera dikirim ke alamatmu.`,
      `---`,
      `Terima kasih sudah menggunakan ServisGadget! Beri ulasan ya.`,
    ].join('\n');
    await this.send(phone, msg, 'order_completed');
  }
}
