import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class SparepartService {
  constructor(private prisma: PrismaService) {}

  async findByStore(storeId: string) {
    return this.prisma.sparepart.findMany({ where: { storeId } });
  }

  async findById(id: string) {
    const item = await this.prisma.sparepart.findUnique({ where: { id } });
    if (!item) throw new NotFoundException('Sparepart tidak ditemukan');
    return item;
  }

  async create(storeId: string, data: { name: string; description?: string; price: number; qty: number; imageUrl?: string }) {
    return this.prisma.sparepart.create({ data: { ...data, storeId } });
  }

  async update(id: string, data: { name?: string; price?: number; qty?: number; lowStockThreshold?: number }) {
    return this.prisma.sparepart.update({ where: { id }, data });
  }

  async delete(id: string) {
    const activeOrders = await this.prisma.orderItem.count({
      where: { sparepartId: id, status: { in: ['pending', 'confirmed'] }, order: { status: { notIn: ['completed', 'cancelled'] } } },
    });
    if (activeOrders > 0) {
      throw new Error('Sparepart masih digunakan di order aktif');
    }
    return this.prisma.sparepart.delete({ where: { id } });
  }
}
