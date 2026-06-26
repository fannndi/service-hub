import { Injectable, HttpStatus } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../../common/prisma/prisma.service';
import { AppException } from '../../common/exceptions';
import { normalizePhone } from '../../common/utils';
import { UpdateUserDto } from './dto/platform-admin.dto';

@Injectable()
export class PlatformUserService {
  constructor(
    private prisma: PrismaService,
  ) {}

  async listUsers() {
    return this.prisma.user.findMany({
      select: {
        id: true,
        fullName: true,
        phoneNumber: true,
        address: true,
        accountStatus: true,
        isFirstLogin: true,
        isCredentialSent: true,
        createdAt: true,
        lastLoginAt: true,
        passwordChangedAt: true,
      },
      orderBy: { createdAt: 'desc' },
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
        createdAt: true,
        lastLoginAt: true,
        passwordChangedAt: true,
      },
    });
    if (!user) {
      throw new AppException('NOT_FOUND', 'User not found', 'Pelanggan tidak ditemukan.', HttpStatus.NOT_FOUND);
    }
    return user;
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
    if (dto.accountStatus === 'suspended' || dto.accountStatus === 'deleted') {
      await this.prisma.userSession.updateMany({
        where: { userId: id, isActive: true },
        data: { isActive: false },
      });
    }
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
