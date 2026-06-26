import { Injectable, HttpStatus } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../../common/prisma/prisma.service';
import { AppException } from '../../common/exceptions';

@Injectable()
export class PlatformAdminMgmtService {
  constructor(
    private prisma: PrismaService,
  ) {}

  async listStoreAdmins() {
    return this.prisma.storeAdmin.findMany({
      select: {
        id: true,
        fullName: true,
        phoneNumber: true,
        isActive: true,
        isFirstLogin: true,
        lastLoginAt: true,
        createdAt: true,
        store: { select: { id: true, storeName: true } },
      },
      orderBy: { createdAt: 'desc' },
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
