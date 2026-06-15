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
import { generatePassword, normalizePhone, encryptCredential, decryptCredential } from '../../common/utils';
import { JwtPayload } from '../../common/types/jwt-payload.type';
import { AppConfig } from '../../config/configuration';

interface AutoCreateAccountResult {
  user: { id: string; phoneNumber: string; fullName: string; isFirstLogin: boolean };
  isNew: boolean;
  rawPass?: string;
}

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
    private config: ConfigService<AppConfig>,
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

    const tokens = this.generateCustomerTokens(user.id, user.isFirstLogin);
    await this.createUserSession(user.id, tokens.refreshToken, ip);
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
    const tokens = this.generateCustomerTokens(user.id, user.isFirstLogin);
    await this.createUserSession(user.id, tokens.refreshToken, ip);
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

  async autoCreateAccount(fullName: string, rawPhone: string): Promise<AutoCreateAccountResult> {
    const phone = normalizePhone(rawPhone);
    const existing = await this.prisma.user.findUnique({ where: { phoneNumber: phone } });
    if (existing) return { user: existing, isNew: false };

    const rawPass = generatePassword(fullName, phone);
    const passwordHash = await bcrypt.hash(rawPass, 12);
    const encryptionKey = this.config.get('credential.encryptionKey', { infer: true });
    if (!encryptionKey) throw new Error('CREDENTIAL_ENCRYPTION_KEY not configured');
    const credentialPlainEnc = encryptCredential(rawPass, encryptionKey);
    const user = await this.prisma.user.create({
      data: {
        fullName,
        phoneNumber: phone,
        passwordHash,
        credentialPlainEnc,
        isFirstLogin: true,
        isCredentialSent: false,
      },
    });
    return { user, isNew: true, rawPass };
  }

  getDecryptedCredential(enc: string | null): string | null {
    if (!enc) return null;
    try {
      const encryptionKey = this.config.get('credential.encryptionKey', { infer: true });
      if (!encryptionKey) return null;
      return decryptCredential(enc, encryptionKey);
    } catch {
      return null;
    }
  }

  private generateCustomerTokens(userId: string, isFirstLogin: boolean) {
    const payload: JwtPayload = { sub: userId, role: 'customer', isFirstLogin };
    return {
      accessToken: this.jwt.sign(payload, {
        secret: this.config.get('jwt.accessSecret', { infer: true }),
        expiresIn: this.config.get('jwt.accessExpiresIn', { infer: true }) ?? '1h',
      }),
      refreshToken: this.jwt.sign(payload, {
        secret: this.config.get('jwt.refreshSecret', { infer: true }),
        expiresIn: this.config.get('jwt.refreshExpiresIn', { infer: true }) ?? '30d',
      }),
    };
  }

  private async createUserSession(userId: string, refreshToken: string, ip: string) {
    const tokenHash = createHash('sha256').update(refreshToken).digest('hex');
    await this.prisma.userSession.create({
      data: {
        userId,
        tokenHash,
        ipAddress: ip,
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      },
    });
  }
}
