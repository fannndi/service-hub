import { Injectable, UnauthorizedException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { Role } from '../../common/types/auth.types';

@Injectable()
export class StoreAuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private config: ConfigService,
  ) {}

  async login(phoneNumber: string, passwordPlain: string) {
    const admin = await this.prisma.storeAdmin.findUnique({ where: { phoneNumber } });
    if (!admin) {
      throw new UnauthorizedException({ code: 'INVALID_CREDENTIALS', message: 'Nomor HP atau password salah.' });
    }

    if (admin.lockedUntil && admin.lockedUntil > new Date()) {
      throw new ForbiddenException({ code: 'ACCOUNT_LOCKED', message: 'Akun terkunci sementara.' });
    }

    const isMatch = await bcrypt.compare(passwordPlain, admin.passwordHash);
    if (!isMatch) {
      const attempts = admin.loginAttemptCount + 1;
      const lockedUntil = attempts >= 5 ? new Date(Date.now() + 15 * 60 * 1000) : null;
      await this.prisma.storeAdmin.update({
        where: { id: admin.id },
        data: { loginAttemptCount: attempts, lockedUntil },
      });
      if (attempts >= 5) {
        throw new ForbiddenException({ code: 'ACCOUNT_LOCKED', message: 'Akun terkunci sementara.' });
      }
      throw new UnauthorizedException({ code: 'INVALID_CREDENTIALS', message: 'Nomor HP atau password salah.' });
    }

    await this.prisma.storeAdmin.update({
      where: { id: admin.id },
      data: { loginAttemptCount: 0, lockedUntil: null, lastLoginAt: new Date() },
    });

    const payload = { sub: admin.id, role: Role.STORE_ADMIN, storeId: admin.storeId };
    return {
      access_token: this.jwtService.sign(payload, {
        secret: this.config.get<string>('app.jwt.storeSecret'),
        expiresIn: this.config.get<string>('app.jwt.expiresIn'),
      }),
      store_admin: {
        id: admin.id,
        full_name: admin.fullName,
        phone_number: admin.phoneNumber,
        store_id: admin.storeId,
      },
    };
  }
}
