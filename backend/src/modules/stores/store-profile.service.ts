import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';

@Injectable()
export class StoreProfileService {
  constructor(private prisma: PrismaService) {}

  async getStoreProfile(adminId: string) {
    const admin = await this.prisma.storeAdmin.findUniqueOrThrow({
      where: { id: adminId },
      include: { store: true },
    });
    return {
      id: admin.id,
      fullName: admin.fullName,
      phoneNumber: admin.phoneNumber,
      store: {
        id: admin.store.id,
        storeName: admin.store.storeName,
        address: admin.store.address,
        phoneNumber: admin.store.phoneNumber,
        operationalHours: admin.store.operationalHours,
        config: admin.store.config,
        isActive: admin.store.isActive,
      },
    };
  }

  async updateStoreProfile(adminId: string, storeId: string, dto: Record<string, unknown>) {
    const adminData: Record<string, unknown> = {};
    if (typeof dto.fullName === 'string') adminData.fullName = dto.fullName;

    const storeData: Record<string, unknown> = {};
    if (typeof dto.storeName === 'string') storeData.storeName = dto.storeName;
    if (dto.operationalHours !== undefined) storeData.operationalHours = dto.operationalHours;
    if (typeof dto.address === 'string') storeData.address = dto.address;
    if (typeof dto.phoneNumber === 'string') storeData.phoneNumber = dto.phoneNumber;

    await this.prisma.$transaction([
      this.prisma.storeAdmin.update({ where: { id: adminId }, data: adminData }),
      ...(Object.keys(storeData).length > 0
        ? [this.prisma.store.update({ where: { id: storeId }, data: storeData })]
        : []),
    ]);

    return this.getStoreProfile(adminId);
  }
}
