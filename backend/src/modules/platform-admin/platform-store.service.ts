import { Injectable, HttpStatus } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../../common/prisma/prisma.service';
import { AppException } from '../../common/exceptions';
import { normalizePhone, encryptCredential } from '../../common/utils';
import { CreateStoreDto, UpdateStoreDto } from './dto/platform-admin.dto';
import { AppConfig } from '../../config/configuration';

interface StoreConfig {
  service_fee: Record<string, number>;
  warranty_days: number;
  diagnosis_fee: number;
  device_types: { android: boolean; ios: boolean };
}

@Injectable()
export class PlatformStoreService {
  constructor(
    private prisma: PrismaService,
    private config: ConfigService<AppConfig>,
  ) {}

  async createStore(dto: CreateStoreDto) {
    const existing = await this.prisma.storeAdmin.findFirst({
      where: { phoneNumber: normalizePhone(dto.adminPhone) },
    });
    if (existing) {
      throw new AppException(
        'PHONE_ALREADY_REGISTERED',
        'Phone already registered',
        'Nomor HP sudah terdaftar sebagai admin toko.',
        HttpStatus.CONFLICT,
      );
    }

    const passwordHash = await bcrypt.hash(dto.password, 12);
    const encryptionKey = this.config.get('credential.encryptionKey', { infer: true });
    const credentialPlainEnc = encryptionKey ? encryptCredential(dto.password, encryptionKey) : null;

    const config: StoreConfig = {
      service_fee: {
        screen_replacement: 50000,
        battery_replacement: 30000,
        charging_port: 25000,
        camera: 40000,
        other: 20000,
      },
      warranty_days: 30,
      diagnosis_fee: 20000,
      device_types: {
        android: dto.handlesAndroid,
        ios: dto.handlesIos,
      },
    };

    const result = await this.prisma.$transaction(async (tx) => {
      const store = await tx.store.create({
        data: {
          storeName: dto.storeName,
          address: dto.address,
          phoneNumber: normalizePhone(dto.storePhone),
          operationalHours: dto.operationalHours ?? {
            mon: '09:00-18:00',
            tue: '09:00-18:00',
            wed: '09:00-18:00',
            thu: '09:00-18:00',
            fri: '09:00-18:00',
            sat: '09:00-15:00',
            sun: 'closed',
          },
          config: config as any,
          isActive: true,
        },
      });

      const admin = await tx.storeAdmin.create({
        data: {
          storeId: store.id,
          fullName: dto.adminName,
          phoneNumber: normalizePhone(dto.adminPhone),
          passwordHash,
          credentialPlainEnc,
          isFirstLogin: false,
        },
      });

      return { store, admin };
    });

    return {
      store: {
        id: result.store.id,
        storeName: result.store.storeName,
        address: result.store.address,
        phoneNumber: result.store.phoneNumber,
        deviceTypes: { android: dto.handlesAndroid, ios: dto.handlesIos },
      },
      admin: {
        id: result.admin.id,
        fullName: result.admin.fullName,
        phoneNumber: result.admin.phoneNumber,
      },
      message: 'Toko berhasil dibuat.',
    };
  }

  async listStores() {
    return this.prisma.store.findMany({
      where: { isActive: true },
      select: {
        id: true,
        storeName: true,
        address: true,
        phoneNumber: true,
        config: true,
        ratingAvg: true,
        totalCompleted: true,
        createdAt: true,
        admins: {
          select: { id: true, fullName: true, phoneNumber: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async updateStore(id: string, dto: UpdateStoreDto) {
    const store = await this.prisma.store.findUnique({ where: { id } });
    if (!store) {
      throw new AppException('NOT_FOUND', 'Store not found', 'Toko tidak ditemukan.', HttpStatus.NOT_FOUND);
    }
    const data: any = {};
    if (dto.storeName !== undefined) data.storeName = dto.storeName;
    if (dto.address !== undefined) data.address = dto.address;
    if (dto.phoneNumber !== undefined) data.phoneNumber = normalizePhone(dto.phoneNumber);
    if (dto.isActive !== undefined) data.isActive = dto.isActive;
    if (dto.operationalHours !== undefined) data.operationalHours = dto.operationalHours;
    await this.prisma.store.update({ where: { id }, data });
    return { message: 'Toko berhasil diupdate.' };
  }
}
