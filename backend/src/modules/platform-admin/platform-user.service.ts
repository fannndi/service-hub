import { Injectable, HttpStatus } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../../common/prisma/prisma.service';
import { AppException } from '../../common/exceptions';
import { normalizePhone, decryptCredential } from '../../common/utils';
import { UpdateUserDto } from './dto/platform-admin.dto';
import { AppConfig } from '../../config/configuration';

@Injectable()
export class PlatformUserService {
  constructor(
    private prisma: PrismaService,
    private config: ConfigService<AppConfig>,
  ) {}

  async listUsers() {
    const encryptionKey = this.config.get('credential.encryptionKey', { infer: true });
    const users = await this.prisma.user.findMany({
      select: {
        id: true,
        fullName: true,
        phoneNumber: true,
        address: true,
        accountStatus: true,
        isFirstLogin: true,
        isCredentialSent: true,
        credentialPlainEnc: true,
        createdAt: true,
        lastLoginAt: true,
        passwordChangedAt: true,
      },
      orderBy: { createdAt: 'desc' },
    });
    return users.map(u => {
      let pw: string | null = null;
      if (u.credentialPlainEnc && encryptionKey) {
        try { pw = decryptCredential(u.credentialPlainEnc, encryptionKey); } catch { /* ignore */ }
      }
      return { ...u, plainPassword: pw, credentialPlainEnc: undefined };
    });
  }

  async getUser(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        fullName: true,
        phoneNumber: true,
        accountStatus: true,
        address: true,
        isFirstLogin: true,
        isCredentialSent: true,
        credentialPlainEnc: true,
        createdAt: true,
        lastLoginAt: true,
        passwordChangedAt: true,
      },
    });
    if (!user) {
      throw new AppException('NOT_FOUND', 'User not found', 'Pelanggan tidak ditemukan.', HttpStatus.NOT_FOUND);
    }
    const encryptionKey = this.config.get('credential.encryptionKey', { infer: true });
    const plainPassword = user.credentialPlainEnc && encryptionKey
      ? decryptCredential(user.credentialPlainEnc, encryptionKey)
      : null;
    return { ...user, plainPassword, credentialPlainEnc: undefined };
  }

  async updateUser(id: string, dto: UpdateUserDto) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) {
      throw new AppException('NOT_FOUND', 'User not found', 'Pelanggan tidak ditemukan.', HttpStatus.NOT_FOUND);
    }
    const data: any = {};
    if (dto.fullName !== undefined) data.fullName = dto.fullName;
    if (dto.phoneNumber !== undefined) data.phoneNumber = normalizePhone(dto.phoneNumber);
    if (dto.address !== undefined) data.address = dto.address;
    if (dto.accountStatus !== undefined) data.accountStatus = dto.accountStatus;
    if (dto.isFirstLogin !== undefined) data.isFirstLogin = dto.isFirstLogin;
    if (dto.isCredentialSent !== undefined) data.isCredentialSent = dto.isCredentialSent;
    await this.prisma.user.update({ where: { id }, data });
    return { message: 'Pelanggan berhasil diupdate.' };
  }

  async changeUserPassword(id: string, newPassword: string) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) {
      throw new AppException('NOT_FOUND', 'User not found', 'Pelanggan tidak ditemukan.', HttpStatus.NOT_FOUND);
    }
    const passwordHash = await bcrypt.hash(newPassword, 12);
    await this.prisma.user.update({
      where: { id },
      data: {
        passwordHash,
        isFirstLogin: false,
        passwordChangedAt: new Date(),
        credentialPlainEnc: null,
      },
    });
    return { message: 'Password berhasil diubah.' };
  }
}
