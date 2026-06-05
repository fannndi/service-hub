import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: {
        id: true, fullName: true, phoneNumber: true, avatarUrl: true,
        address: true, accountStatus: true, isFirstLogin: true,
        createdAt: true, updatedAt: true,
      },
    });
    return user;
  }

  async updateProfile(userId: string, dto: { fullName?: string; address?: string; avatarUrl?: string }) {
    return this.prisma.user.update({
      where: { id: userId },
      data: dto,
      select: {
        id: true, fullName: true, phoneNumber: true, avatarUrl: true,
        address: true, accountStatus: true, isFirstLogin: true,
        createdAt: true, updatedAt: true,
      },
    });
  }

  async getCoupons(userId: string) {
    return this.prisma.coupon.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }
}
