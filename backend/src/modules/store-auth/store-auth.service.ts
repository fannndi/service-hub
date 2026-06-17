import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../common/prisma/prisma.service';
import * as bcrypt from 'bcrypt';
import { InvalidCredentialsException, PasswordSameAsOldException, StoreNotActiveException } from '../../common/exceptions';
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

  async login(rawPhone: string, password: string) {
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
    await this.prisma.storeAdmin.update({
      where: { id: adminId },
      data: { passwordHash: hash, isFirstLogin: false },
    });
    return { message: 'Password berhasil diubah.' };
  }
}
