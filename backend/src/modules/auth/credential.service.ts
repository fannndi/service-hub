import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../common/prisma/prisma.service';
import * as bcrypt from 'bcrypt';
import { createHash } from 'crypto';
import { generatePassword, normalizePhone, encryptCredential, decryptCredential } from '../../common/utils';
import { JwtPayload } from '../../common/types/jwt-payload.type';
import { AppConfig } from '../../config/configuration';

interface AutoCreateAccountResult {
  user: { id: string; phoneNumber: string; fullName: string; isFirstLogin: boolean };
  isNew: boolean;
  rawPass?: string;
}

@Injectable()
export class CredentialService {
  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
    private config: ConfigService<AppConfig>,
  ) {}

  async autoCreateAccount(fullName: string, rawPhone: string): Promise<AutoCreateAccountResult> {
    const phone = normalizePhone(rawPhone);
    const existing = await this.prisma.user.findUnique({ where: { phoneNumber: phone } });
    if (existing) return { user: existing, isNew: false };

    const rawPass = generatePassword();
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
        accountStatus: 'suspended',
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

  generateCustomerTokens(userId: string, isFirstLogin: boolean) {
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

  async createUserSession(userId: string, refreshToken: string, ip: string) {
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
