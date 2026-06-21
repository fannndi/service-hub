import { Injectable, HttpStatus } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../../common/prisma/prisma.service';
import { AppException } from '../../common/exceptions';
import { encryptCredential } from '../../common/utils';
import { RegisterStoreDto } from './dto/register-store.dto';
import { AppConfig } from '../../config/configuration';

@Injectable()
export class StoreRegisterService {
  constructor(
    private prisma: PrismaService,
    private config: ConfigService<AppConfig>,
  ) {}

  async register(dto: RegisterStoreDto) {
    const existing = await this.prisma.storeAdmin.findFirst({
      where: { phoneNumber: dto.applicantPhone },
    });
    if (existing) {
      throw new AppException(
        'PHONE_ALREADY_REGISTERED',
        'Phone already registered as store admin',
        'Nomor HP sudah terdaftar sebagai admin toko.',
        HttpStatus.CONFLICT,
      );
    }

    const passwordHash = await bcrypt.hash(dto.password, 12);
    const encryptionKey = this.config.get('credential.encryptionKey', { infer: true });
    const credentialPlainEnc = encryptionKey ? encryptCredential(dto.password, encryptionKey) : null;

    const result = await this.prisma.$transaction(async (tx) => {
      const store = await tx.store.create({
        data: {
          storeName: dto.storeName,
          address: dto.address,
          phoneNumber: dto.storePhone,
          operationalHours: dto.operationalHours ?? {
            weekdays: '09:00 - 18:00',
            saturday: '09:00 - 15:00',
            sunday: 'Tutup',
          },
          isActive: true,
        },
      });

      const admin = await tx.storeAdmin.create({
        data: {
          storeId: store.id,
          fullName: dto.applicantName,
          phoneNumber: dto.applicantPhone,
          passwordHash,
          credentialPlainEnc,
          isFirstLogin: true,
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
        isActive: result.store.isActive,
      },
      admin: {
        id: result.admin.id,
        fullName: result.admin.fullName,
        phoneNumber: result.admin.phoneNumber,
        isFirstLogin: result.admin.isFirstLogin,
      },
      message: 'Toko berhasil didaftarkan. Silakan login untuk melanjutkan.',
    };
  }
}
