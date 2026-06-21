import { Injectable, HttpStatus } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../../common/prisma/prisma.service';
import { AppException } from '../../common/exceptions';
import { normalizePhone, encryptCredential, decryptCredential } from '../../common/utils';
import { CreateStoreDto, UpdateUserDto, UpdateStoreDto } from './dto/platform-admin.dto';
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

  async listUsers() {
    const encryptionKey = this.config.get('credential.encryptionKey', { infer: true });
    const users = await this.prisma.user.findMany({
      select: {
        id: true,
        fullName: true,
        phoneNumber: true,
        address: true,
        accountStatus: true,
        isFirstLogin: true,
        isCredentialSent: true,
        credentialPlainEnc: true,
        createdAt: true,
        lastLoginAt: true,
        passwordChangedAt: true,
      },
      orderBy: { createdAt: 'desc' },
    });
    return users.map(u => {
      let pw: string | null = null;
      if (u.credentialPlainEnc && encryptionKey) {
        try { pw = decryptCredential(u.credentialPlainEnc, encryptionKey); } catch { /* ignore */ }
      }
      return { ...u, plainPassword: pw, credentialPlainEnc: undefined };
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
        credentialPlainEnc: true,
        createdAt: true,
        lastLoginAt: true,
        passwordChangedAt: true,
      },
    });
    if (!user) {
      throw new AppException('NOT_FOUND', 'User not found', 'Pelanggan tidak ditemukan.', HttpStatus.NOT_FOUND);
    }
    const encryptionKey = this.config.get('credential.encryptionKey', { infer: true });
    const plainPassword = user.credentialPlainEnc && encryptionKey
      ? decryptCredential(user.credentialPlainEnc, encryptionKey)
      : null;
    return { ...user, plainPassword, credentialPlainEnc: undefined };
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

  async listStoreAdmins() {
    const encryptionKey = this.config.get('credential.encryptionKey', { infer: true });
    const admins = await this.prisma.storeAdmin.findMany({
      select: {
        id: true,
        fullName: true,
        phoneNumber: true,
        isActive: true,
        isFirstLogin: true,
        credentialPlainEnc: true,
        lastLoginAt: true,
        createdAt: true,
        store: { select: { id: true, storeName: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
    return admins.map(a => {
      let pw: string | null = null;
      if (a.credentialPlainEnc && encryptionKey) {
        try { pw = decryptCredential(a.credentialPlainEnc, encryptionKey); } catch { /* ignore */ }
      }
      return { ...a, plainPassword: pw, credentialPlainEnc: undefined };
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
