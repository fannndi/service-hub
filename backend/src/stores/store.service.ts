import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class StoreService {
  constructor(private prisma: PrismaService) {}

  async findAll() {
    return this.prisma.store.findMany({ where: { isActive: true } });
  }

  async findById(id: string) {
    const store = await this.prisma.store.findUnique({ where: { id } });
    if (!store) throw new NotFoundException('Toko tidak ditemukan');
    return store;
  }

  async findByAdminId(adminId: string) {
    const admin = await this.prisma.storeAdmin.findUnique({ where: { id: adminId } });
    if (!admin) throw new NotFoundException('Admin tidak ditemukan');
    return this.findById(admin.storeId);
  }

  async update(id: string, data: { storeName?: string; address?: string; phoneNumber?: string; config?: any }) {
    return this.prisma.store.update({ where: { id }, data });
  }
}
