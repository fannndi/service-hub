import { Injectable, HttpStatus } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../../common/prisma/prisma.service';
import { AppException } from '../../common/exceptions';
import { decryptCredential } from '../../common/utils';
import { AppConfig } from '../../config/configuration';

@Injectable()
export class PlatformAdminMgmtService {
  constructor(
    private prisma: PrismaService,
    private config: ConfigService<AppConfig>,
  ) {}

  async listStoreAdmins() {
    const encryptionKey = this.config.get('credential.encryptionKey', { infer: true });
    const admins = await this.prisma.storeAdmin.findMany({
      select: {
        id: true,
        fullName: true,
        phoneNumber: true,
        isActive: true,
        isFirstLogin: true,
        credentialPlainEnc: true,
        lastLoginAt: true,
        createdAt: true,
        store: { select: { id: true, storeName: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
    return admins.map(a => {
      let pw: string | null = null;
      if (a.credentialPlainEnc && encryptionKey) {
        try { pw = decryptCredential(a.credentialPlainEnc, encryptionKey); } catch { /* ignore */ }
      }
      return { ...a, plainPassword: pw, credentialPlainEnc: undefined };
    });
  }

  async changeStoreAdminPassword(id: string, newPassword: string) {
    const admin = await this.prisma.storeAdmin.findUnique({ where: { id } });
    if (!admin) {
      throw new AppException('NOT_FOUND', 'Admin not found', 'Admin toko tidak ditemukan.', HttpStatus.NOT_FOUND);
    }
    const passwordHash = await bcrypt.hash(newPassword, 12);
    await this.prisma.storeAdmin.update({
      where: { id },
      data: { passwordHash, isFirstLogin: false, credentialPlainEnc: null },
    });
    return { message: 'Password admin berhasil diubah.' };
  }
}
