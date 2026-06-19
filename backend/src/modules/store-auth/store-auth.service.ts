import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../common/prisma/prisma.service';
import * as bcrypt from 'bcrypt';
import { createHash } from 'crypto';
import {
  InvalidCredentialsException,
  PasswordSameAsOldException,
  StoreNotActiveException,
} from '../../common/exceptions';
import { normalizePhone } from '../../common/utils';
import { JwtPayload } from '../../common/types/jwt-payload.type';
import { AppConfig } from '../../config/configuration';

@Injectable()
export class StoreAuthService {
  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
    private config: ConfigService<AppConfig>,
  ) {}

  async login(rawPhone: string, password: string, ip: string) {
    const phone = normalizePhone(rawPhone);
    const admin = await this.prisma.storeAdmin.findFirst({
      where: { phoneNumber: phone, isActive: true },
      include: { store: { select: { id: true, storeName: true, isActive: true } } },
    });
    if (!admin) throw new InvalidCredentialsException();
    if (!admin.store.isActive) throw new StoreNotActiveException();
    if (!(await bcrypt.compare(password, admin.passwordHash))) throw new InvalidCredentialsException();

    await this.prisma.storeAdmin.update({
      where: { id: admin.id },
      data: { lastLoginAt: new Date() },
    });

    const payload: JwtPayload = {
      sub: admin.id,
      role: 'store_admin',
      storeId: admin.storeId,
      isFirstLogin: admin.isFirstLogin,
    };
    const tokens = {
      accessToken: this.jwt.sign(payload, {
        secret: this.config.get('jwt.storeAccessSecret', { infer: true }),
        expiresIn: '1h',
      }),
      refreshToken: this.jwt.sign(payload, {
        secret: this.config.get('jwt.storeRefreshSecret', { infer: true }),
        expiresIn: '30d',
      }),
    };

    await this.createAdminSession(admin.id, tokens.refreshToken, ip);

    return {
      ...tokens,
      isFirstLogin: admin.isFirstLogin,
      storeAdmin: {
        id: admin.id,
        storeId: admin.storeId,
        storeName: admin.store.storeName,
        fullName: admin.fullName,
      },
    };
  }

  async changePassword(adminId: string, oldPassword: string, newPassword: string) {
    const admin = await this.prisma.storeAdmin.findUniqueOrThrow({ where: { id: adminId } });
    if (!(await bcrypt.compare(oldPassword, admin.passwordHash))) throw new InvalidCredentialsException();
    if (await bcrypt.compare(newPassword, admin.passwordHash)) throw new PasswordSameAsOldException();
    const hash = await bcrypt.hash(newPassword, 12);
    await this.prisma.$transaction([
      this.prisma.storeAdmin.update({
        where: { id: adminId },
        data: { passwordHash: hash, isFirstLogin: false },
      }),
      this.prisma.storeAdminSession.updateMany({
        where: { adminId, isActive: true },
        data: { isActive: false },
      }),
    ]);
    return { message: 'Password berhasil diubah.' };
  }

  async logout(adminId: string, refreshToken: string) {
    const tokenHash = createHash('sha256').update(refreshToken).digest('hex');
    await this.prisma.storeAdminSession.updateMany({
      where: { adminId, tokenHash, isActive: true },
      data: { isActive: false },
    });
    return { message: 'Logout berhasil.' };
  }

  async refresh(refreshToken: string, ip: string) {
    let payload: JwtPayload;
    try {
      payload = this.jwt.verify<JwtPayload>(refreshToken, {
        secret: this.config.get('jwt.storeRefreshSecret', { infer: true }),
      });
    } catch {
      throw new InvalidCredentialsException();
    }
    const tokenHash = createHash('sha256').update(refreshToken).digest('hex');
    const session = await this.prisma.storeAdminSession.findFirst({
      where: { tokenHash, isActive: true, expiresAt: { gt: new Date() } },
    });
    if (!session) throw new InvalidCredentialsException();

    await this.prisma.storeAdminSession.update({
      where: { id: session.id },
      data: { isActive: false },
    });

    const admin = await this.prisma.storeAdmin.findUniqueOrThrow({ where: { id: payload.sub } });
    const newPayload: JwtPayload = {
      sub: admin.id,
      role: 'store_admin',
      storeId: admin.storeId,
      isFirstLogin: admin.isFirstLogin,
    };
    const tokens = {
      accessToken: this.jwt.sign(newPayload, {
        secret: this.config.get('jwt.storeAccessSecret', { infer: true }),
        expiresIn: '1h',
      }),
      refreshToken: this.jwt.sign(newPayload, {
        secret: this.config.get('jwt.storeRefreshSecret', { infer: true }),
        expiresIn: '30d',
      }),
    };
    await this.createAdminSession(admin.id, tokens.refreshToken, ip);
    return tokens;
  }

  private async createAdminSession(adminId: string, refreshToken: string, ip: string) {
    const tokenHash = createHash('sha256').update(refreshToken).digest('hex');
    await this.prisma.storeAdminSession.create({
      data: {
        adminId,
        tokenHash,
        ipAddress: ip,
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      },
    });
  }
}
