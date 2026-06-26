import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../common/prisma/prisma.service';
import { CredentialService } from '../auth/credential.service';
import { NotificationsService } from '../notifications/notifications.service';
import { OrderNotFoundException, ForbiddenException } from '../../common/exceptions';
import { AppConfig } from '../../config/configuration';
import axios from 'axios';
import { normalizePhone } from '../../common/utils';

@Injectable()
export class GuestOrdersService {
  private readonly logger = new Logger(GuestOrdersService.name);

  constructor(
    private prisma: PrismaService,
    private credentialService: CredentialService,
    private config: ConfigService<AppConfig>,
    private notif: NotificationsService,
  ) {}

  async verifyAndTrack(orderNumber: string, rawPhone: string) {
    const phone = normalizePhone(rawPhone);
    const order = await this.prisma.serviceOrder.findUnique({
      where: { orderNumber },
      include: {
        user: { select: { phoneNumber: true } },
        tracking: { orderBy: { createdAt: 'asc' } },
        store: { select: { storeName: true } },
      },
    });
    if (!order || order.user.phoneNumber !== phone) throw new OrderNotFoundException();

    return {
      orderNumber: order.orderNumber,
      status: order.status,
      storeName: order.store.storeName,
      deviceType: order.deviceType,
      brand: order.brand,
      deviceModel: order.deviceModel,
      deliveryMethod: order.deliveryMethod,
      createdAt: order.createdAt,
      tracking: order.tracking.map((t) => ({
        status: t.status,
        note: t.note,
        createdAt: t.createdAt,
      })),
    };
  }

  async getCredentials(orderId: string, rawPhone: string) {
    const phone = normalizePhone(rawPhone);
    const order = await this.prisma.serviceOrder.findUnique({
      where: { id: orderId },
      include: { user: true },
    });
    if (!order || order.user.phoneNumber !== phone) throw new OrderNotFoundException();

    const user = order.user;
    const canActivate = this._isAtLeastDeviceReceived(order.status);
    const isActivated = user.accountStatus === 'active' && !user.credentialPlainEnc;
    const rawPass = user.credentialPlainEnc
      ? this.credentialService.getDecryptedCredential(user.credentialPlainEnc)
      : null;

    return {
      orderNumber: order.orderNumber,
      status: order.status,
      canActivate,
      isActivated,
      phoneNumber: user.phoneNumber,
      hasCredential: !!rawPass,
      maskedPassword: rawPass ? this._maskPassword(rawPass) : null,
      fullName: user.fullName,
    };
  }

  async activateGuestAccount(orderId: string, storeId: string) {
    const order = await this.prisma.serviceOrder.findFirst({
      where: { id: orderId, storeId },
      include: { user: true },
    });
    if (!order) throw new OrderNotFoundException();

    const user = order.user;
    if (!user.credentialPlainEnc) return { message: 'Akun sudah diaktifkan sebelumnya.' };
    if (user.accountStatus !== 'suspended') throw new ForbiddenException('Account not suspended', 'Akun tidak dalam status suspended');

    const rawPass = this.credentialService.getDecryptedCredential(user.credentialPlainEnc);
    if (!rawPass) throw new Error('Failed to decrypt credential');

    await this._createSupabaseAuthUser(user, rawPass);

    await this.prisma.user.update({
      where: { id: user.id },
      data: { accountStatus: 'active', credentialPlainEnc: null, isCredentialSent: true },
    });

    await this.notif.send(
      user.phoneNumber,
      [
        `Halo ${user.fullName}!`,
        `Akun ServisGadget kamu sekarang aktif!`,
        `Login dengan:`,
        `Username: ${user.phoneNumber}`,
        `Password: ${rawPass}`,
        `Jangan lupa ganti password setelah login.`,
      ].join('\n'),
      'account_activated',
    );

    return { message: 'Akun berhasil diaktifkan. Cek WhatsApp untuk info login.' };
  }

  private _isAtLeastDeviceReceived(status: string): boolean {
    const order = ['device_received', 'diagnosing', 'waiting_approval', 'waiting_sparepart', 'repairing', 'quality_check', 'waiting_payment', 'completed'];
    return order.includes(status);
  }

  private _maskPassword(pass: string): string {
    if (pass.length <= 2) return '••';
    return pass[0] + '•'.repeat(pass.length - 2) + pass[pass.length - 1];
  }

  private async _createSupabaseAuthUser(
    user: { id: string; phoneNumber: string; fullName: string },
    password: string,
  ) {
    const projectRef = this.config.get('supabase.projectRef', { infer: true });
    const serviceRoleKey = this.config.get('supabase.serviceRoleKey', { infer: true });
    if (!projectRef || !serviceRoleKey) {
      this.logger.warn('Supabase Admin API not configured — skipping auth user creation');
      return;
    }

    const email = `${user.phoneNumber}@customer.servisgadget.com`;
    try {
      await axios.post(
        `https://${projectRef}.supabase.co/auth/v1/admin/users`,
        {
          email,
          password,
          email_confirm: true,
          user_metadata: {
            role: 'customer',
            phone: user.phoneNumber,
            full_name: user.fullName,
            is_first_login: true,
          },
        },
        {
          headers: {
            apikey: serviceRoleKey,
            Authorization: `Bearer ${serviceRoleKey}`,
            'Content-Type': 'application/json',
          },
          timeout: 15_000,
        },
      );
      this.logger.log(`Supabase Auth user created for ${email}`);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      this.logger.error(`Failed to create Supabase Auth user for ${email}: ${msg}`);
    }
  }
}
