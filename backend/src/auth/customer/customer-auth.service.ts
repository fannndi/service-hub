import { Injectable, UnauthorizedException, ForbiddenException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { Role } from '../../common/types/auth.types';

@Injectable()
export class CustomerAuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private config: ConfigService,
  ) {}

  async login(phoneNumber: string, passwordPlain: string) {
    const user = await this.prisma.user.findUnique({ where: { phoneNumber } });
    if (!user) {
      throw new UnauthorizedException({ code: 'INVALID_CREDENTIALS', message: 'Nomor HP atau password salah.' });
    }

    if (user.lockedUntil && user.lockedUntil > new Date()) {
      throw new ForbiddenException({ code: 'ACCOUNT_LOCKED', message: 'Akun terkunci sementara.' });
    }

    const isMatch = await bcrypt.compare(passwordPlain, user.passwordHash);
    if (!isMatch) {
      const attempts = user.loginAttemptCount + 1;
      const lockedUntil = attempts >= 5 ? new Date(Date.now() + 15 * 60 * 1000) : null;
      await this.prisma.user.update({
        where: { id: user.id },
        data: { loginAttemptCount: attempts, lockedUntil },
      });
      if (attempts >= 5) {
        throw new ForbiddenException({ code: 'ACCOUNT_LOCKED', message: 'Akun terkunci sementara.' });
      }
      throw new UnauthorizedException({ code: 'INVALID_CREDENTIALS', message: 'Nomor HP atau password salah.' });
    }

    await this.prisma.user.update({
      where: { id: user.id },
      data: { loginAttemptCount: 0, lockedUntil: null, lastLoginAt: new Date() },
    });

    const payload = { sub: user.id, role: Role.CUSTOMER };
    return {
      access_token: this.jwtService.sign(payload, {
        secret: this.config.get<string>('app.jwt.customerSecret'),
        expiresIn: this.config.get<string>('app.jwt.expiresIn'),
      }),
      refresh_token: this.jwtService.sign(payload, {
        secret: this.config.get<string>('app.jwt.customerSecret'),
        expiresIn: '30d',
      }),
      user: {
        id: user.id,
        full_name: user.fullName,
        phone_number: user.phoneNumber,
        is_first_login: user.isFirstLogin,
      },
    };
  }

  async changePassword(phoneNumber: string, oldPasswordPlain: string, newPasswordPlain: string) {
    const user = await this.prisma.user.findUnique({ where: { phoneNumber } });
    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    const isMatch = await bcrypt.compare(oldPasswordPlain, user.passwordHash);
    if (!isMatch) {
      throw new UnauthorizedException('Password lama salah');
    }

    const isSameAsOld = await bcrypt.compare(newPasswordPlain, user.passwordHash);
    if (isSameAsOld) {
      throw new ConflictException({ code: 'PASSWORD_SAME_AS_OLD', message: 'Password baru tidak boleh sama dengan yang lama.' });
    }

    const cost = this.config.get<number>('app.bcryptCost');
    const passwordHash = await bcrypt.hash(newPasswordPlain, cost);

    await this.prisma.user.update({
      where: { id: user.id },
      data: { passwordHash, isFirstLogin: false, passwordChangedAt: new Date() },
    });

    return { status: 'success' };
  }
}
