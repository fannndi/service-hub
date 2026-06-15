import { Injectable, HttpStatus } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../../common/prisma/prisma.service';
import { AppException } from '../../common/exceptions';
import { normalizePhone } from '../../common/utils';
import { CreateStoreDto } from './dto/platform-admin.dto';
import { JwtPayload } from '../../common/types/jwt-payload.type';
import { AppConfig } from '../../config/configuration';

interface StoreConfig {
  service_fee: Record<string, number>;
  warranty_days: number;
  diagnosis_fee: number;
  device_types: { android: boolean; ios: boolean };
}

@Injectable()
export class PlatformAdminService {
  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
    private config: ConfigService<AppConfig>,
  ) {}

  async login(username: string, password: string) {
    const admin = await this.prisma.platformAdmin.findFirst({
      where: { username, isActive: true },
    });
    if (!admin || !(await bcrypt.compare(password, admin.passwordHash))) {
      throw new AppException(
        'INVALID_CREDENTIALS',
        'Invalid credentials',
        'Username atau password salah.',
        HttpStatus.UNAUTHORIZED,
      );
    }

    await this.prisma.platformAdmin.update({
      where: { id: admin.id },
      data: { lastLoginAt: new Date() },
    });

    const payload: JwtPayload = { sub: admin.id, role: 'platform_admin', username: admin.username };
    const token = this.jwt.sign(payload, {
      secret: this.config.get('jwt.platformAdminSecret', { infer: true }),
      expiresIn: '12h',
    });

    return {
      accessToken: token,
      admin: { id: admin.id, username: admin.username, fullName: admin.fullName },
    };
  }

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
}
