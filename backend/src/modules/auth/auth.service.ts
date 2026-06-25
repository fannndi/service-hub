import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../common/prisma/prisma.service';
import * as bcrypt from 'bcrypt';
import { createHash } from 'crypto';
import {
  InvalidCredentialsException,
  AccountLockedException,
  AccountSuspendedException,
  PasswordSameAsOldException,
  TokenInvalidException,
} from '../../common/exceptions';
import { normalizePhone } from '../../common/utils';
import { JwtPayload } from '../../common/types/jwt-payload.type';
import { AppConfig } from '../../config/configuration';
import { CredentialService } from './credential.service';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
    private config: ConfigService<AppConfig>,
    private credentialService: CredentialService,
  ) {}

  async login(rawPhone: string, password: string, ip: string) {
    const phone = normalizePhone(rawPhone);
    const user = await this.prisma.user.findUnique({ where: { phoneNumber: phone } });
    if (!user) throw new InvalidCredentialsException();
    if (user.accountStatus === 'suspended') throw new AccountSuspendedException();
    if (user.lockedUntil && user.lockedUntil > new Date())
      throw new AccountLockedException(user.lockedUntil);

    const match = await bcrypt.compare(password, user.passwordHash);
    if (!match) {
      const attempts = user.loginAttemptCount + 1;
      const updateData: { loginAttemptCount: number; lockedUntil?: Date } = { loginAttemptCount: attempts };
      if (attempts >= 3 && attempts < 5) {
        console.warn(`[RATE_LIMIT] ${phone}: ${attempts} failed attempts — monitoring`);
      }
      if (attempts >= 5) {
        updateData.lockedUntil = new Date(Date.now() + 30 * 60 * 1000);
        updateData.loginAttemptCount = 0;
      }
      await this.prisma.user.update({ where: { id: user.id }, data: updateData });
      throw new InvalidCredentialsException();
    }

    await this.prisma.user.update({
      where: { id: user.id },
      data: { loginAttemptCount: 0, lockedUntil: null, lastLoginAt: new Date() },
    });

    const tokens = this.credentialService.generateCustomerTokens(user.id, user.isFirstLogin);
    await this.credentialService.createUserSession(user.id, tokens.refreshToken, ip);
    return {
      ...tokens,
      isFirstLogin: user.isFirstLogin,
      user: { id: user.id, fullName: user.fullName, phoneNumber: user.phoneNumber },
    };
  }

  async changePassword(userId: string, oldPassword: string, newPassword: string) {
    const user = await this.prisma.user.findUniqueOrThrow({ where: { id: userId } });
    if (!(await bcrypt.compare(oldPassword, user.passwordHash)))
      throw new InvalidCredentialsException();
    if (await bcrypt.compare(newPassword, user.passwordHash))
      throw new PasswordSameAsOldException();

    const hash = await bcrypt.hash(newPassword, 12);
    const updateData: { passwordHash: string; isFirstLogin: boolean; passwordChangedAt: Date; credentialPlainEnc?: string | null } = {
      passwordHash: hash,
      isFirstLogin: false,
      passwordChangedAt: new Date(),
    };

    if (user.isFirstLogin) {
      updateData.credentialPlainEnc = null;
    }

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: userId },
        data: updateData,
      }),
      this.prisma.userSession.updateMany({
        where: { userId, isActive: true },
        data: { isActive: false },
      }),
    ]);
    return { message: 'Password berhasil diubah.' };
  }

  async refresh(refreshToken: string, ip: string) {
    let payload: JwtPayload;
    try {
      payload = this.jwt.verify<JwtPayload>(refreshToken, {
        secret: this.config.get('jwt.refreshSecret', { infer: true }),
      });
    } catch {
      throw new TokenInvalidException();
    }
    const tokenHash = createHash('sha256').update(refreshToken).digest('hex');
    const session = await this.prisma.userSession.findFirst({
      where: { tokenHash, isActive: true, expiresAt: { gt: new Date() } },
    });
    if (!session) throw new TokenInvalidException();

    await this.prisma.userSession.update({ where: { id: session.id }, data: { isActive: false } });

    const user = await this.prisma.user.findUniqueOrThrow({ where: { id: payload.sub } });
    const tokens = this.credentialService.generateCustomerTokens(user.id, user.isFirstLogin);
    await this.credentialService.createUserSession(user.id, tokens.refreshToken, ip);
    return tokens;
  }

  async logout(userId: string, rawRefreshToken: string) {
    const tokenHash = createHash('sha256').update(rawRefreshToken).digest('hex');
    await this.prisma.userSession.updateMany({
      where: { userId, tokenHash, isActive: true },
      data: { isActive: false },
    });
  }

  async logoutAll(userId: string) {
    await this.prisma.userSession.updateMany({
      where: { userId, isActive: true },
      data: { isActive: false },
    });
  }
}
