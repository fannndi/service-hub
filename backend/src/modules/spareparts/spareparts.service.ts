import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { StoreNotActiveException, NotFoundException } from '../../common/exceptions';
import { CreateSparepartDto, UpdateSparepartDto } from './dto/sparepart.dto';

@Injectable()
export class SparepartsService {
  constructor(private prisma: PrismaService) {}

  async findAvailable(storeId: string, brand?: string, deviceModel?: string, partType?: string) {
    const where: Record<string, unknown> = { storeId, status: { not: 'discontinued' } };
    if (brand) where.brand = brand;
    if (deviceModel) where.deviceModel = deviceModel;
    if (partType) where.partType = partType;

    return this.prisma.sparePart.findMany({ where, orderBy: { createdAt: 'desc' } });
  }

  async create(storeId: string, dto: CreateSparepartDto) {
    const store = await this.prisma.store.findUnique({ where: { id: storeId } });
    if (!store || !store.isActive) throw new StoreNotActiveException();

    return this.prisma.sparePart.create({
      data: {
        storeId,
        brand: dto.brand,
        deviceModel: dto.deviceModel,
        partType: dto.partType,
        partName: dto.partName,
        price: dto.price,
        qty: dto.qty,
        status: (dto.status as 'available' | 'preorder' | 'discontinued') ?? 'available',
      },
    });
  }

  async update(id: string, storeId: string, dto: UpdateSparepartDto) {
    const sp = await this.prisma.sparePart.findFirst({ where: { id, storeId } });
    if (!sp) throw new NotFoundException('Sparepart not found', 'Sparepart tidak ditemukan.');
    if (dto.qty !== undefined && dto.qty < sp.qtyReserved) {
      throw new NotFoundException('Stock below reserved', 'Stok tidak boleh kurang dari jumlah yang sedang direservasi.');
    }

    return this.prisma.sparePart.update({
      where: { id },
      data: {
        ...(dto.price !== undefined && { price: dto.price }),
        ...(dto.qty !== undefined && { qty: dto.qty }),
        ...(dto.status !== undefined && { status: dto.status as 'available' | 'preorder' | 'discontinued' }),
        ...(dto.partName !== undefined && { partName: dto.partName }),
      },
    });
  }

  async delete(id: string, storeId: string) {
    const sp = await this.prisma.sparePart.findFirst({ where: { id, storeId } });
    if (!sp) throw new NotFoundException('Sparepart not found', 'Sparepart tidak ditemukan.');

    const referencedInOrders = await this.prisma.orderItem.findFirst({
      where: { sparepartId: id },
    });
    if (referencedInOrders) {
      return this.prisma.sparePart.update({
        where: { id },
        data: { status: 'discontinued' },
      });
    }

    return this.prisma.sparePart.delete({ where: { id } });
  }
}
