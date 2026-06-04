# Phase 1 — Foundation & Backend Core
**Branch:** `feature/fase-1-foundation`
**PIC:** Developer Utama
**Estimasi:** 5–7 hari kerja

---

## Objective

Menyediakan seluruh infrastruktur backend + Flutter shared layer yang dibutuhkan Fase 2 dan 3.
Fase lain **tidak boleh mulai** sebelum branch ini di-merge ke `develop`.

---

## Deliverables

- [ ] PostgreSQL + Redis berjalan via Docker
- [ ] Prisma schema + migration sukses + seed berjalan
- [ ] Customer Auth (login, refresh, change password, logout, stealth account)
- [ ] Store Admin Auth (login terpisah, JWT dengan storeId)
- [ ] Store & Sparepart CRUD
- [ ] Order service inti: createOrder + approveOrder + rejectOrder + updateStatus + submitDiagnosis
- [ ] Payment service: createPayment + confirmPayment
- [ ] Review service: createReview + update ratingAvg + buat kupon
- [ ] Dispute service: createDispute + respondDispute + buat warranty order
- [ ] Notification service (WA + retry)
- [ ] File upload presigned URL endpoint
- [ ] Background jobs: SLA Monitor + Credential Cleaner
- [ ] Flutter shared layer: core + models + repositories + widgets

---

## Bug PRD Asli — Wajib Dibaca Sebelum Coding

| # | Bug | Fix yang Benar |
|---|---|---|
| B1 | `itemPrice: 0` di createOrder | Isi dari `sparepart.price`, bukan 0 |
| B2 | Tidak ada `qtyReserved` increment saat booking | `qtyReserved += 1` per item saat createOrder |
| B3 | `approveOrder` hanya decrement `qty` | Decrement `qty` DAN `qtyReserved` |
| B4 | `POST /v1/orders` butuh JWT | Endpoint ini PUBLIC |
| B5 | Satu auth service untuk dua entitas | Buat `StoreAuthService` terpisah, tabel `store_admins` |
| B6 | Kupon tidak cek ownership | Tambah `coupon.userId === user.id` |
| B7 | `warrantyDays` tidak di-set saat payment confirm | Baca `store.config.warranty_days`, set ke order |
| B8 | `ratingAvg` tidak pernah update | Hitung ulang AVG setiap review baru |
| B9 | Kupon reward tidak dibuat setelah review | Buat kupon dalam transaction yang sama |
| B10 | Order number pakai `count()+1` → race condition | Pakai `nanoid` dengan @unique constraint |
| B11 | `DiagnosisItemDto` tidak ada field `replacedSparepartId` | Tambahkan field + validasi wajib jika status=replaced |

---

## Folder Structure Backend

```
servisgadget-api/
├── prisma/
│   ├── schema.prisma          ← copy dari Master PRD section 3
│   └── seed.ts
├── src/
│   ├── main.ts
│   ├── app.module.ts
│   ├── config/
│   │   └── configuration.ts
│   ├── common/
│   │   ├── constants/sla.constant.ts
│   │   ├── decorators/
│   │   │   ├── get-user.decorator.ts
│   │   │   └── roles.decorator.ts
│   │   ├── exceptions/index.ts
│   │   ├── filters/global-exception.filter.ts
│   │   ├── guards/
│   │   │   ├── jwt-auth.guard.ts
│   │   │   ├── store-jwt-auth.guard.ts
│   │   │   ├── roles.guard.ts
│   │   │   └── first-login.guard.ts
│   │   ├── interceptors/response.interceptor.ts
│   │   └── types/
│   │       ├── enums.ts
│   │       └── jwt-payload.type.ts
│   ├── prisma/
│   │   ├── prisma.module.ts
│   │   └── prisma.service.ts
│   └── modules/
│       ├── auth/
│       │   ├── auth.module.ts
│       │   ├── auth.controller.ts
│       │   ├── auth.service.ts
│       │   ├── strategies/
│       │   │   ├── jwt-access.strategy.ts
│       │   │   └── jwt-refresh.strategy.ts
│       │   └── utils/
│       │       ├── password.util.ts
│       │       └── encryption.util.ts
│       ├── store-auth/
│       │   ├── store-auth.module.ts
│       │   ├── store-auth.controller.ts
│       │   ├── store-auth.service.ts
│       │   └── strategies/
│       │       ├── store-jwt-access.strategy.ts
│       │       └── store-jwt-refresh.strategy.ts
│       ├── users/
│       │   ├── users.module.ts
│       │   ├── users.controller.ts
│       │   └── users.service.ts
│       ├── stores/
│       │   ├── stores.module.ts
│       │   ├── stores.controller.ts
│       │   └── stores.service.ts
│       ├── spareparts/
│       │   ├── spareparts.module.ts
│       │   ├── spareparts.controller.ts
│       │   └── spareparts.service.ts
│       ├── orders/
│       │   ├── orders.module.ts
│       │   ├── orders.controller.ts
│       │   ├── store-orders.controller.ts
│       │   ├── orders.service.ts
│       │   ├── matching.service.ts
│       │   └── utils/state-machine.util.ts
│       ├── payments/
│       │   ├── payments.module.ts
│       │   ├── payments.controller.ts
│       │   └── payments.service.ts
│       ├── reviews/
│       │   ├── reviews.module.ts
│       │   ├── reviews.controller.ts
│       │   └── reviews.service.ts
│       ├── disputes/
│       │   ├── disputes.module.ts
│       │   ├── disputes.controller.ts
│       │   └── disputes.service.ts
│       ├── uploads/
│       │   ├── uploads.module.ts
│       │   ├── uploads.controller.ts
│       │   └── uploads.service.ts
│       ├── notifications/
│       │   ├── notifications.module.ts
│       │   └── notifications.service.ts
│       └── jobs/
│           ├── jobs.module.ts
│           ├── sla-monitor.job.ts
│           └── credential-cleaner.job.ts
├── docker-compose.yml
├── .env
├── .env.example
└── package.json
```

---

## T-01 — Docker & Setup

```bash
# docker-compose.yml
# (jalankan: docker-compose up -d)
```

```yaml
version: '3.8'
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres123
      POSTGRES_DB: servisgadget
    ports: ['5432:5432']
    volumes: [postgres_data:/var/lib/postgresql/data]
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U postgres']
      interval: 10s
      retries: 5
  redis:
    image: redis:7-alpine
    ports: ['6379:6379']
    volumes: [redis_data:/data]
volumes:
  postgres_data:
  redis_data:
```

```bash
# Setup project
nest new servisgadget-api --package-manager npm
cd servisgadget-api
rm src/app.controller.ts src/app.controller.spec.ts src/app.service.ts

npm install @nestjs/jwt @nestjs/passport @nestjs/config @nestjs/throttler \
  @nestjs/schedule @nestjs/bullmq bullmq ioredis \
  passport passport-jwt bcrypt class-validator class-transformer \
  axios nanoid @aws-sdk/client-s3

npm install -D prisma @types/bcrypt @types/passport-jwt

npx prisma init --datasource-provider postgresql
# Copy schema dari Master PRD section 3 ke prisma/schema.prisma
npx prisma migrate dev --name init

# Tambah constraint manual setelah migrate:
npx prisma db execute --stdin << 'SQL'
ALTER TABLE spareparts ADD CONSTRAINT spareparts_qty_nonneg CHECK (qty >= 0);
ALTER TABLE spareparts ADD CONSTRAINT spareparts_qty_reserved_nonneg CHECK (qty_reserved >= 0);
ALTER TABLE reviews ADD CONSTRAINT reviews_rating_range CHECK (rating BETWEEN 1 AND 5);
SQL
```

---

## T-02 — src/main.ts

```typescript
import { NestFactory, Reflector } from '@nestjs/core';
import { ValidationPipe, ClassSerializerInterceptor } from '@nestjs/common';
import { AppModule } from './app.module';
import { ResponseInterceptor } from './common/interceptors/response.interceptor';
import { GlobalExceptionFilter } from './common/filters/global-exception.filter';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule);
  app.setGlobalPrefix('v1');
  app.enableCors({ origin: process.env.APP_URL, credentials: true });
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
    transformOptions: { enableImplicitConversion: true },
  }));
  app.useGlobalInterceptors(
    new ClassSerializerInterceptor(app.get(Reflector)),
    new ResponseInterceptor(),
  );
  app.useGlobalFilters(new GlobalExceptionFilter());
  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
```

---

## T-03 — Common Layer

### src/common/types/jwt-payload.type.ts
```typescript
export interface JwtPayload {
  sub: string;
  role: 'customer' | 'store_admin';
  storeId?: string;      // wajib ada untuk store_admin
  isFirstLogin?: boolean;
  iat: number;
  exp: number;
}
```

### src/common/exceptions/index.ts
```typescript
import { HttpException, HttpStatus } from '@nestjs/common';

export class AppException extends HttpException {
  constructor(
    public readonly code: string,
    message: string,
    public readonly userMessage: string,
    status: number,
    details?: object,
  ) {
    super(
      { success: false, error: { code, message, user_message: userMessage, details },
        timestamp: new Date().toISOString() },
      status,
    );
  }
}

// AUTH
export class InvalidCredentialsException extends AppException {
  constructor() { super('INVALID_CREDENTIALS', 'Wrong credentials',
    'Nomor HP atau password salah.', HttpStatus.UNAUTHORIZED); }
}
export class AccountLockedException extends AppException {
  constructor(lockedUntil: Date) { super('ACCOUNT_LOCKED', 'Account locked',
    'Akun terkunci sementara.', 423, { locked_until: lockedUntil }); }
}
export class AccountSuspendedException extends AppException {
  constructor() { super('ACCOUNT_SUSPENDED', 'Account suspended',
    'Akun dinonaktifkan. Hubungi support.', HttpStatus.FORBIDDEN); }
}
export class FirstLoginRequiredException extends AppException {
  constructor() { super('FIRST_LOGIN_REQUIRED', 'Change password first',
    'Harap ganti password sementaramu terlebih dahulu.', HttpStatus.FORBIDDEN); }
}
export class TokenInvalidException extends AppException {
  constructor() { super('TOKEN_INVALID', 'Token invalid or expired',
    'Sesi tidak valid, silakan login kembali.', HttpStatus.UNAUTHORIZED); }
}
export class PasswordSameAsOldException extends AppException {
  constructor() { super('PASSWORD_SAME_AS_OLD', 'Same password',
    'Password baru tidak boleh sama dengan password sebelumnya.', HttpStatus.BAD_REQUEST); }
}

// ORDERS
export class OrderNotFoundException extends AppException {
  constructor() { super('ORDER_NOT_FOUND', 'Order not found',
    'Pesanan tidak ditemukan.', HttpStatus.NOT_FOUND); }
}
export class InvalidStatusTransitionException extends AppException {
  constructor(from: string, to: string) { super('INVALID_STATUS_TRANSITION',
    `Cannot transition from ${from} to ${to}`,
    'Perubahan status tidak valid.', HttpStatus.UNPROCESSABLE_ENTITY); }
}
export class StockUnavailableException extends AppException {
  constructor() { super('STOCK_UNAVAILABLE', 'Insufficient stock',
    'Stok sparepart tidak tersedia.', HttpStatus.CONFLICT); }
}
export class StoreNotActiveException extends AppException {
  constructor() { super('STORE_NOT_ACTIVE', 'Store not active',
    'Toko tidak aktif atau tidak ditemukan.', HttpStatus.UNPROCESSABLE_ENTITY); }
}
export class DeliveryAddressRequiredException extends AppException {
  constructor() { super('DELIVERY_ADDRESS_REQUIRED', 'Delivery address required',
    'Alamat penjemputan wajib diisi untuk metode kurir.', HttpStatus.BAD_REQUEST); }
}
export class ProofRequiredException extends AppException {
  constructor() { super('PROOF_REQUIRED', 'Payment proof required',
    'Bukti pembayaran wajib diunggah untuk transfer bank.', HttpStatus.BAD_REQUEST); }
}

// COUPONS
export class CouponExpiredException extends AppException {
  constructor() { super('COUPON_EXPIRED', 'Coupon expired',
    'Kupon sudah kadaluarsa.', HttpStatus.UNPROCESSABLE_ENTITY); }
}
export class CouponAlreadyUsedException extends AppException {
  constructor() { super('COUPON_ALREADY_USED', 'Coupon already used',
    'Kupon sudah pernah digunakan.', HttpStatus.UNPROCESSABLE_ENTITY); }
}
export class CouponNotOwnedException extends AppException {
  constructor() { super('COUPON_NOT_OWNED', 'Coupon not owned',
    'Kupon ini bukan milikmu.', HttpStatus.FORBIDDEN); }
}

// REVIEWS & DISPUTES
export class DuplicateReviewException extends AppException {
  constructor() { super('DUPLICATE_REVIEW', 'Review already exists',
    'Kamu sudah memberikan ulasan untuk pesanan ini.', HttpStatus.CONFLICT); }
}
export class WarrantyExpiredException extends AppException {
  constructor() { super('WARRANTY_EXPIRED', 'Warranty expired',
    'Masa garansi sudah berakhir.', HttpStatus.UNPROCESSABLE_ENTITY); }
}
export class DisputeAlreadyActiveException extends AppException {
  constructor() { super('DISPUTE_ALREADY_ACTIVE', 'Dispute already exists',
    'Sudah ada klaim aktif untuk pesanan ini.', HttpStatus.CONFLICT); }
}
```

### src/common/guards/first-login.guard.ts
```typescript
import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { FirstLoginRequiredException } from '../exceptions';

@Injectable()
export class FirstLoginGuard implements CanActivate {
  canActivate(ctx: ExecutionContext): boolean {
    const user = ctx.switchToHttp().getRequest().user;
    if (user?.isFirstLogin === true) throw new FirstLoginRequiredException();
    return true;
  }
}
// Pasang di semua controller KECUALI: AuthController.changePassword
// dan StoreAuthController.changePassword
```

### src/common/interceptors/response.interceptor.ts
```typescript
import { Injectable, NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

@Injectable()
export class ResponseInterceptor implements NestInterceptor {
  intercept(_ctx: ExecutionContext, next: CallHandler): Observable<any> {
    return next.handle().pipe(
      map(data => ({
        success: true,
        data: data ?? null,
        timestamp: new Date().toISOString(),
      })),
    );
  }
}
```

### src/common/filters/global-exception.filter.ts
```typescript
import { ExceptionFilter, Catch, ArgumentsHost, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { Response } from 'express';

@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  private logger = new Logger('GlobalExceptionFilter');

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx  = host.switchToHttp();
    const res  = ctx.getResponse<Response>();

    if (exception instanceof HttpException) {
      const body = exception.getResponse();
      // AppException sudah format yang benar
      if (typeof body === 'object' && (body as any).success === false) {
        return res.status(exception.getStatus()).json(body);
      }
      // NestJS default exceptions (ValidationPipe, dll)
      return res.status(exception.getStatus()).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Validation failed',
          user_message: 'Data tidak valid.',
          details: (body as any).message,
        },
        timestamp: new Date().toISOString(),
      });
    }

    this.logger.error('Unhandled exception', exception);
    return res.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
      success: false,
      error: { code: 'INTERNAL_ERROR', message: 'Internal server error',
               user_message: 'Terjadi kesalahan. Coba lagi nanti.' },
      timestamp: new Date().toISOString(),
    });
  }
}
```

---

## T-04 — Auth Utilities

### src/modules/auth/utils/password.util.ts
```typescript
export function generatePassword(fullName: string, phoneNumber: string): string {
  const firstName = fullName.trim().split(/\s+/)[0].toUpperCase();
  const letters   = firstName.replace(/[^A-Z]/g, '');
  const padded    = letters.padEnd(4, '_').substring(0, 4);
  const part1     = padded.split('').map(c =>
    c === '_' ? '00' : String(c.charCodeAt(0) - 64).padStart(2, '0')
  ).join('');
  const digits = phoneNumber.replace(/\D/g, '');
  return part1 + digits.slice(-4);
}

export function normalizePhone(phone: string): string {
  const d = phone.replace(/\D/g, '');
  if (d.startsWith('62')) return `+${d}`;
  if (d.startsWith('0'))  return `+62${d.slice(1)}`;
  return `+62${d}`;
}

// Unit test — wajib semua pass:
// generatePassword('Budi Santoso',  '+6281234567890') === '022104097890' ✓
// generatePassword('Ani',           '+6282198765432') === '011409005432' ✓
// generatePassword('Muhammad',      '+6285611223344') === '132108013344' ✓
// generatePassword('Li',            '+6281299998888') === '120900008888' ✓
```

### src/modules/auth/utils/encryption.util.ts
```typescript
import { createCipheriv, createDecipheriv, randomBytes } from 'crypto';

export function encryptCredential(plaintext: string): string {
  const key = Buffer.from(process.env.CREDENTIAL_ENCRYPTION_KEY!, 'hex');
  if (key.length !== 32) throw new Error('CREDENTIAL_ENCRYPTION_KEY harus 32 bytes (64 hex chars)');
  const iv     = randomBytes(12);
  const cipher = createCipheriv('aes-256-gcm', key, iv);
  const enc    = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
  const tag    = cipher.getAuthTag();
  return `${iv.toString('hex')}:${tag.toString('hex')}:${enc.toString('hex')}`;
}

export function decryptCredential(ciphertext: string): string {
  const key = Buffer.from(process.env.CREDENTIAL_ENCRYPTION_KEY!, 'hex');
  const parts = ciphertext.split(':');
  if (parts.length !== 3) throw new Error('Invalid ciphertext format');
  const [ivHex, tagHex, encHex] = parts;
  const dec = createDecipheriv('aes-256-gcm', key, Buffer.from(ivHex, 'hex'));
  dec.setAuthTag(Buffer.from(tagHex, 'hex'));
  return dec.update(Buffer.from(encHex, 'hex')).toString('utf8') + dec.final('utf8');
}
```

---

## T-05 — Customer Auth Service (Lengkap)

```typescript
// src/modules/auth/auth.service.ts
import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service';
import * as bcrypt from 'bcrypt';
import { createHash } from 'crypto';
import {
  InvalidCredentialsException, AccountLockedException, AccountSuspendedException,
  PasswordSameAsOldException, TokenInvalidException,
} from '../../common/exceptions';
import { generatePassword, normalizePhone } from './utils/password.util';
import { encryptCredential, decryptCredential } from './utils/encryption.util';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
    private config: ConfigService,
  ) {}

  async login(rawPhone: string, password: string, ip: string) {
    const phone = normalizePhone(rawPhone);
    const user  = await this.prisma.user.findUnique({ where: { phoneNumber: phone } });
    if (!user) throw new InvalidCredentialsException();
    if (user.accountStatus === 'suspended') throw new AccountSuspendedException();
    if (user.lockedUntil && user.lockedUntil > new Date())
      throw new AccountLockedException(user.lockedUntil);

    const match = await bcrypt.compare(password, user.passwordHash);
    if (!match) {
      const attempts = user.loginAttemptCount + 1;
      const upd: any = { loginAttemptCount: attempts };
      if (attempts >= 5) {
        upd.lockedUntil       = new Date(Date.now() + 30 * 60 * 1000);
        upd.loginAttemptCount = 0;
      }
      await this.prisma.user.update({ where: { id: user.id }, data: upd });
      throw new InvalidCredentialsException();
    }

    await this.prisma.user.update({
      where: { id: user.id },
      data: { loginAttemptCount: 0, lockedUntil: null, lastLoginAt: new Date() },
    });

    const tokens = this.generateCustomerTokens(user.id, user.isFirstLogin);
    await this.createUserSession(user.id, tokens.refreshToken, ip);
    return {
      ...tokens,
      isFirstLogin: user.isFirstLogin,
      user: { id: user.id, fullName: user.fullName, phoneNumber: user.phoneNumber },
    };
  }

  async changePassword(userId: string, oldPassword: string, newPassword: string) {
    const user = await this.prisma.user.findUniqueOrThrow({ where: { id: userId } });
    if (!await bcrypt.compare(oldPassword, user.passwordHash))
      throw new InvalidCredentialsException();
    if (await bcrypt.compare(newPassword, user.passwordHash))
      throw new PasswordSameAsOldException();

    const hash = await bcrypt.hash(newPassword, 12);
    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: userId },
        data: { passwordHash: hash, isFirstLogin: false,
                passwordChangedAt: new Date(), credentialPlainEnc: null },
      }),
      this.prisma.userSession.updateMany({
        where: { userId, isActive: true },
        data: { isActive: false },
      }),
    ]);
    return { message: 'Password berhasil diubah.' };
  }

  async refresh(refreshToken: string, ip: string) {
    let payload: any;
    try {
      payload = this.jwt.verify(refreshToken,
        { secret: this.config.get('jwt.refreshSecret') });
    } catch {
      throw new TokenInvalidException();
    }
    const tokenHash = createHash('sha256').update(refreshToken).digest('hex');
    const session   = await this.prisma.userSession.findFirst({
      where: { tokenHash, isActive: true, expiresAt: { gt: new Date() } },
    });
    if (!session) throw new TokenInvalidException();

    await this.prisma.userSession.update(
      { where: { id: session.id }, data: { isActive: false } });

    const user   = await this.prisma.user.findUniqueOrThrow({ where: { id: payload.sub } });
    const tokens = this.generateCustomerTokens(user.id, user.isFirstLogin);
    await this.createUserSession(user.id, tokens.refreshToken, ip);
    return tokens;
  }

  async logout(userId: string, rawRefreshToken: string) {
    const tokenHash = createHash('sha256').update(rawRefreshToken).digest('hex');
    await this.prisma.userSession.updateMany({
      where: { userId, tokenHash, isActive: true },
      data:  { isActive: false },
    });
  }

  async logoutAll(userId: string) {
    await this.prisma.userSession.updateMany({
      where: { userId, isActive: true },
      data:  { isActive: false },
    });
  }

  // Dipanggil dari OrdersService — stealth account
  async autoCreateAccount(fullName: string, rawPhone: string)
    : Promise<{ user: any; isNew: boolean; rawPass?: string }> {
    const phone    = normalizePhone(rawPhone);
    const existing = await this.prisma.user.findUnique({ where: { phoneNumber: phone } });
    if (existing) return { user: existing, isNew: false };

    const rawPass          = generatePassword(fullName, phone);
    const passwordHash     = await bcrypt.hash(rawPass, 12);
    const credentialPlainEnc = encryptCredential(rawPass);
    const user = await this.prisma.user.create({
      data: { fullName, phoneNumber: phone, passwordHash,
              credentialPlainEnc, isFirstLogin: true, isCredentialSent: false },
    });
    return { user, isNew: true, rawPass };
  }

  getDecryptedCredential(enc: string | null): string | null {
    if (!enc) return null;
    try { return decryptCredential(enc); } catch { return null; }
  }

  private generateCustomerTokens(userId: string, isFirstLogin: boolean) {
    const payload = { sub: userId, role: 'customer', isFirstLogin };
    return {
      accessToken: this.jwt.sign(payload, {
        secret:    this.config.get('jwt.accessSecret'),
        expiresIn: this.config.get('jwt.accessExpiresIn') ?? '1h',
      }),
      refreshToken: this.jwt.sign(payload, {
        secret:    this.config.get('jwt.refreshSecret'),
        expiresIn: this.config.get('jwt.refreshExpiresIn') ?? '30d',
      }),
    };
  }

  private async createUserSession(userId: string, refreshToken: string, ip: string) {
    const tokenHash = createHash('sha256').update(refreshToken).digest('hex');
    await this.prisma.userSession.create({
      data: {
        userId, tokenHash, ipAddress: ip,
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      },
    });
  }
}
```

---

## T-06 — Store Admin Auth Service

```typescript
// src/modules/store-auth/store-auth.service.ts
@Injectable()
export class StoreAuthService {
  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
    private config: ConfigService,
  ) {}

  async login(rawPhone: string, password: string, ip: string) {
    const phone = normalizePhone(rawPhone);
    const admin = await this.prisma.storeAdmin.findFirst({
      where: { phoneNumber: phone, isActive: true },
      include: { store: { select: { id: true, storeName: true, isActive: true } } },
    });
    if (!admin) throw new InvalidCredentialsException();
    if (!await bcrypt.compare(password, admin.passwordHash))
      throw new InvalidCredentialsException();

    await this.prisma.storeAdmin.update({
      where: { id: admin.id },
      data:  { lastLoginAt: new Date() },
    });

    // JWT payload WAJIB berisi storeId
    const payload = {
      sub: admin.id,
      role: 'store_admin',
      storeId: admin.storeId,
      isFirstLogin: admin.isFirstLogin,
    };
    const tokens = {
      accessToken: this.jwt.sign(payload, {
        secret:    this.config.get('jwt.storeAccessSecret'),
        expiresIn: '1h',
      }),
      refreshToken: this.jwt.sign(payload, {
        secret:    this.config.get('jwt.storeRefreshSecret'),
        expiresIn: '30d',
      }),
    };

    return {
      ...tokens,
      isFirstLogin: admin.isFirstLogin,
      storeAdmin: {
        id:        admin.id,
        storeId:   admin.storeId,
        storeName: admin.store.storeName,
        fullName:  admin.fullName,
      },
    };
  }

  async changePassword(adminId: string, oldPassword: string, newPassword: string) {
    const admin = await this.prisma.storeAdmin.findUniqueOrThrow({ where: { id: adminId } });
    if (!await bcrypt.compare(oldPassword, admin.passwordHash))
      throw new InvalidCredentialsException();
    if (await bcrypt.compare(newPassword, admin.passwordHash))
      throw new PasswordSameAsOldException();
    const hash = await bcrypt.hash(newPassword, 12);
    await this.prisma.storeAdmin.update({
      where: { id: adminId },
      data:  { passwordHash: hash, isFirstLogin: false },
    });
    return { message: 'Password berhasil diubah.' };
  }
}
```

---

## T-07 — Orders Service (createOrder — Full Implementation)

```typescript
// src/modules/orders/orders.service.ts
import { customAlphabet } from 'nanoid';
const nid = customAlphabet('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ', 6);

@Injectable()
export class OrdersService {
  constructor(
    private prisma: PrismaService,
    private authService: AuthService,
    private notif: NotificationsService,
  ) {}

  async createOrder(dto: CreateOrderDto): Promise<any> {
    // 1. Validasi delivery address
    if (dto.deliveryMethod === 'courier_pickup' && !dto.deliveryAddress)
      throw new DeliveryAddressRequiredException();

    // 2. Validasi store aktif
    const store = await this.prisma.store.findUnique({ where: { id: dto.storeId } });
    if (!store || !store.isActive) throw new StoreNotActiveException();
    const config = store.config as any;

    // 3. Validasi stok + kumpulkan itemPrice SEBELUM transaction
    const itemData: Array<{ serviceType: string; complaint: string; sparepartId?: string; itemPrice: number }> = [];
    for (const item of dto.items) {
      let itemPrice = 0;
      if (item.sparepartId) {
        const sp = await this.prisma.sparePart.findUnique({ where: { id: item.sparepartId } });
        if (!sp || sp.storeId !== dto.storeId) throw new StockUnavailableException();
        if (sp.qty - sp.qtyReserved <= 0) throw new StockUnavailableException();
        itemPrice = Number(sp.price); // ← FIX B1: dari sparepart.price
      }
      itemPrice += Number(config.service_fee?.[item.serviceType] ?? 0);
      itemData.push({ serviceType: item.serviceType, complaint: item.complaint,
                      sparepartId: item.sparepartId, itemPrice });
    }

    // 4. Validasi kupon (jika ada) — hanya untuk user yang sudah punya akun
    let discountAmount = 0, couponId: string | undefined;
    if (dto.couponCode) {
      const phone  = normalizePhone(dto.phoneNumber);
      const user   = await this.prisma.user.findUnique({ where: { phoneNumber: phone } });
      const coupon = await this.prisma.coupon.findFirst({ where: { code: dto.couponCode } });
      if (!coupon)                       throw new CouponAlreadyUsedException();
      if (coupon.isUsed)                 throw new CouponAlreadyUsedException();
      if (coupon.expiredAt <= new Date()) throw new CouponExpiredException();
      // FIX B6: cek ownership
      if (!user || coupon.userId !== user.id) throw new CouponNotOwnedException();
      discountAmount = Number(coupon.amount);
      couponId       = coupon.id;
    }

    // 5. Stealth account
    const { user, isNew, rawPass } =
      await this.authService.autoCreateAccount(dto.customerName, dto.phoneNumber);

    // 6. Hitung totalEstimasi
    const totalEstimasi = Math.max(
      0,
      itemData.reduce((sum, i) => sum + i.itemPrice, 0) - discountAmount,
    );

    // 7. Generate order number anti-race condition
    const dateStr     = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const orderNumber = `SG-${dateStr}-${nid()}`;

    // 8. Buat order dalam satu transaction — reserve stok di dalam transaction
    const order = await this.prisma.$transaction(async (tx) => {
      // Re-check + reserve stok dalam transaction
      for (const item of dto.items) {
        if (!item.sparepartId) continue;
        const sp = await tx.sparePart.findUniqueOrThrow({ where: { id: item.sparepartId } });
        if (sp.qty - sp.qtyReserved <= 0) throw new StockUnavailableException();
        // FIX B2: increment qtyReserved, BUKAN decrement qty
        await tx.sparePart.update({
          where: { id: item.sparepartId },
          data:  { qtyReserved: { increment: 1 } },
        });
      }

      const o = await tx.serviceOrder.create({
        data: {
          userId: user.id, storeId: dto.storeId, orderNumber,
          deviceType: dto.deviceType, brand: dto.brand, deviceModel: dto.deviceModel,
          deliveryMethod: dto.deliveryMethod, deliveryAddress: dto.deliveryAddress,
          totalEstimasi, discountAmount, couponId,
          slaDeadline: new Date(Date.now() + 24 * 60 * 60 * 1000),
          items: { create: itemData },  // itemPrice sudah benar dari step 3
        },
        include: { items: true },
      });

      await tx.serviceTracking.create({
        data: { orderId: o.id, status: 'waiting_device',
                createdByType: 'customer', createdById: user.id,
                note: 'Order berhasil dibuat.' },
      });

      if (couponId) {
        await tx.coupon.update({
          where: { id: couponId },
          data:  { isUsed: true, usedAt: new Date(), usedOnOrderId: o.id },
        });
      }

      if (dto.deliveryMethod === 'courier_pickup') {
        await tx.shipment.create({
          data: { orderId: o.id, shipmentType: 'pickup',
                  pickupAddress: dto.deliveryAddress!, destinationAddress: store.address,
                  status: 'scheduled' },
        });
      }
      return o;
    });

    await this.notif.sendNewOrderToStore(store, order, user, isNew, rawPass);

    return {
      id: order.id, orderNumber: order.orderNumber,
      status: order.status, totalEstimasi: order.totalEstimasi,
      isNewCustomer: isNew,
      message: isNew
        ? 'Order berhasil dibuat. Cek WhatsApp untuk info akun ServisGadget.'
        : 'Order berhasil dibuat.',
    };
  }

  async approveOrder(orderId: string, userId: string) {
    const order = await this.prisma.serviceOrder.findFirst({
      where: { id: orderId, userId },
      include: { items: { where: { status: 'confirmed' } }, store: true },
    });
    if (!order) throw new OrderNotFoundException();
    assertValidTransition(order.status, 'repairing');

    await this.prisma.$transaction(async (tx) => {
      for (const item of order.items) {
        if (!item.sparepartId) continue;
        const sp = await tx.sparePart.findUniqueOrThrow({ where: { id: item.sparepartId } });
        if (sp.qty < 1) throw new StockUnavailableException(); // double-check
        // FIX B3: decrement KEDUANYA
        await tx.sparePart.update({
          where: { id: item.sparepartId },
          data:  { qty: { decrement: 1 }, qtyReserved: { decrement: 1 } },
        });
      }
      await tx.serviceOrder.update({
        where: { id: orderId },
        data:  { status: 'repairing', slaDeadline: null, slaWarnedAt: null },
      });
      await tx.serviceTracking.create({
        data: { orderId, status: 'repairing', createdByType: 'customer',
                createdById: userId, note: 'Pelanggan menyetujui diagnosa.' },
      });
    });

    await this.notif.send(order.store.phoneNumber,
      `✅ Pelanggan menyetujui order ${order.orderNumber}. Segera mulai perbaikan!`,
      'order_approved');
    return { status: 'repairing' };
  }

  async rejectOrder(orderId: string, userId: string) {
    const order = await this.prisma.serviceOrder.findFirst({
      where: { id: orderId, userId },
      include: { items: true },
    });
    if (!order) throw new OrderNotFoundException();
    assertValidTransition(order.status, 'cancelled');

    await this.prisma.$transaction(async (tx) => {
      // Rollback qtyReserved, qty TIDAK berubah (belum pernah decrement)
      for (const item of order.items) {
        if (!item.sparepartId) continue;
        await tx.sparePart.update({
          where: { id: item.sparepartId },
          data:  { qtyReserved: { decrement: 1 } },
        });
      }
      await tx.serviceOrder.update({
        where: { id: orderId },
        data:  { status: 'cancelled', cancelledAt: new Date() },
      });
      await tx.serviceTracking.create({
        data: { orderId, status: 'cancelled', createdByType: 'customer',
                createdById: userId, note: 'Pelanggan menolak diagnosa.' },
      });
    });
    return { status: 'cancelled' };
  }

  async updateStatus(orderId: string, adminId: string, storeId: string,
                     dto: UpdateOrderStatusDto) {
    const order = await this.prisma.serviceOrder.findFirst({
      where: { id: orderId, storeId },
    });
    if (!order) throw new OrderNotFoundException();
    assertValidTransition(order.status, dto.status);

    // 'completed' tidak boleh via endpoint ini — hanya via payment confirm
    if (dto.status === 'completed')
      throw new InvalidStatusTransitionException(order.status, 'completed');

    const newSla = ['device_received', 'diagnosing', 'waiting_approval']
      .includes(dto.status)
      ? new Date(Date.now() + 24 * 60 * 60 * 1000)
      : dto.status === 'waiting_payment'
        ? new Date(Date.now() + 48 * 60 * 60 * 1000)
        : null;

    await this.prisma.$transaction(async (tx) => {
      // Jika transisi ke repairing dari waiting_sparepart — decrement stok
      if (dto.status === 'repairing' && order.status === 'waiting_sparepart') {
        const items = await tx.orderItem.findMany({
          where: { orderId, status: 'confirmed' },
        });
        for (const item of items) {
          if (!item.sparepartId) continue;
          await tx.sparePart.update({
            where: { id: item.sparepartId },
            data:  { qty: { decrement: 1 }, qtyReserved: { decrement: 1 } },
          });
        }
      }

      await tx.serviceOrder.update({
        where: { id: orderId },
        data:  { status: dto.status as any,
                 ...(newSla && { slaDeadline: newSla, slaWarnedAt: null }) },
      });
      await tx.serviceTracking.create({
        data: { orderId, status: dto.status as any,
                createdByType: 'store_admin', createdById: adminId,
                note: dto.note ?? null },
      });
    });

    if (dto.status === 'waiting_payment') {
      const fullOrder = await this.prisma.serviceOrder.findUniqueOrThrow({
        where: { id: orderId }, include: { user: true },
      });
      await this.notif.sendWaitingPayment(
        fullOrder.user.phoneNumber, fullOrder.user.fullName,
        fullOrder.orderNumber, Number(fullOrder.finalPrice));
    }

    return { status: dto.status };
  }

  async submitDiagnosis(orderId: string, adminId: string, storeId: string,
                        dto: SubmitDiagnosisDto) {
    const order = await this.prisma.serviceOrder.findFirst({
      where: { id: orderId, storeId, status: 'diagnosing' },
      include: { items: true, user: true },
    });
    if (!order) throw new OrderNotFoundException();

    // Validasi: jika ada item status replaced, wajib ada replacedSparepartId
    for (const diagItem of dto.items) {
      if (diagItem.status === 'replaced' && !diagItem.replacedSparepartId) {
        throw new Error(`Item ${diagItem.orderItemId}: replacedSparepartId wajib diisi jika status=replaced`);
      }
    }

    // Hitung finalPrice
    let finalPrice = Number(dto.serviceFee);
    for (const diagItem of dto.items) {
      if (diagItem.status !== 'cancelled') {
        finalPrice += Number(diagItem.finalItemPrice);
      }
    }

    await this.prisma.$transaction(async (tx) => {
      // Update setiap order item
      for (const diagItem of dto.items) {
        const updateData: any = {
          status:         diagItem.status,
          finalItemPrice: diagItem.finalItemPrice,
          technicianNote: diagItem.technicianNote ?? null,
        };
        // Jika replaced: update sparepartId ke yang baru
        if (diagItem.status === 'replaced' && diagItem.replacedSparepartId) {
          // Rollback reserve sparepart lama
          const oldItem = order.items.find(i => i.id === diagItem.orderItemId);
          if (oldItem?.sparepartId) {
            await tx.sparePart.update({
              where: { id: oldItem.sparepartId },
              data:  { qtyReserved: { decrement: 1 } },
            });
          }
          // Reserve sparepart baru
          const newSp = await tx.sparePart.findUniqueOrThrow(
            { where: { id: diagItem.replacedSparepartId } });
          if (newSp.qty - newSp.qtyReserved <= 0) throw new StockUnavailableException();
          await tx.sparePart.update({
            where: { id: diagItem.replacedSparepartId },
            data:  { qtyReserved: { increment: 1 } },
          });
          updateData.sparepartId = diagItem.replacedSparepartId;
        }
        // Jika cancelled: rollback reserve
        if (diagItem.status === 'cancelled') {
          const oldItem = order.items.find(i => i.id === diagItem.orderItemId);
          if (oldItem?.sparepartId) {
            await tx.sparePart.update({
              where: { id: oldItem.sparepartId },
              data:  { qtyReserved: { decrement: 1 } },
            });
          }
        }
        await tx.orderItem.update({
          where: { id: diagItem.orderItemId },
          data:  updateData,
        });
      }

      await tx.serviceOrder.update({
        where: { id: orderId },
        data:  {
          status:        'waiting_approval',
          finalPrice,
          serviceFee:    dto.serviceFee,
          diagnosisNote: dto.diagnosisNote ?? null,
          slaDeadline:   new Date(Date.now() + 24 * 60 * 60 * 1000),
          slaWarnedAt:   null,
        },
      });
      await tx.serviceTracking.create({
        data: { orderId, status: 'waiting_approval', createdByType: 'store_admin',
                createdById: adminId, note: 'Diagnosa selesai, menunggu persetujuan pelanggan.' },
      });
    });

    await this.notif.sendDiagnosisResult(
      order.user.phoneNumber, order.user.fullName, order.orderNumber, finalPrice);
    return { status: 'waiting_approval', finalPrice };
  }
}
```

---

## T-08 — Payments Service

```typescript
// src/modules/payments/payments.service.ts
@Injectable()
export class PaymentsService {
  async createPayment(orderId: string, userId: string, dto: CreatePaymentDto) {
    // Validasi: transfer bank wajib ada bukti
    if (dto.paymentMethod === 'transfer_bank' && !dto.proofUrl)
      throw new ProofRequiredException();

    const order = await this.prisma.serviceOrder.findFirst({
      where: { id: orderId, userId, status: 'waiting_payment' },
    });
    if (!order) throw new OrderNotFoundException();

    return this.prisma.payment.create({
      data: {
        orderId, userId,
        amount:        dto.amount,
        paymentMethod: dto.paymentMethod as any,
        paymentType:   dto.paymentType as any,
        proofUrl:      dto.proofUrl,
        status:        'pending',
      },
    });
  }

  async confirmPayment(orderId: string, paymentId: string,
                       adminId: string, storeId: string) {
    const payment = await this.prisma.payment.findFirst({
      where: { id: paymentId, orderId },
      include: {
        order: {
          include: { store: true, user: true },
        },
      },
    });
    if (!payment || payment.order.storeId !== storeId)
      throw new OrderNotFoundException();
    if (payment.order.status !== 'waiting_payment')
      throw new InvalidStatusTransitionException(payment.order.status, 'completed');

    // FIX B7: ambil warrantyDays dari store.config
    const config      = payment.order.store.config as any;
    const warrantyDays: number = config.warranty_days ?? 30;
    const completedAt    = new Date();
    const warrantyExpiredAt = new Date(
      completedAt.getTime() + warrantyDays * 24 * 60 * 60 * 1000);

    await this.prisma.$transaction([
      this.prisma.payment.update({
        where: { id: paymentId },
        data:  { status: 'confirmed', confirmedBy: adminId, confirmedAt: new Date() },
      }),
      this.prisma.serviceOrder.update({
        where: { id: orderId },
        data:  {
          status:           'completed',
          paymentStatus:    'paid',
          completedAt,
          warrantyDays,          // ← FIX B7
          warrantyExpiredAt,     // ← FIX B7
        },
      }),
      this.prisma.store.update({
        where: { id: storeId },
        data:  { totalCompleted: { increment: 1 } },
      }),
      this.prisma.serviceTracking.create({
        data: { orderId, status: 'completed', createdByType: 'store_admin',
                createdById: adminId, note: 'Pembayaran dikonfirmasi. Order selesai.' },
      }),
    ]);

    await this.notif.sendOrderCompleted(
      payment.order.user.phoneNumber, payment.order.user.fullName,
      payment.order.orderNumber, payment.order.deliveryMethod);

    return { status: 'completed', warrantyDays, warrantyExpiredAt };
  }
}
```

---

## T-09 — Reviews Service

```typescript
// src/modules/reviews/reviews.service.ts
@Injectable()
export class ReviewsService {
  async createReview(orderId: string, userId: string, dto: CreateReviewDto) {
    const order = await this.prisma.serviceOrder.findFirst({
      where: { id: orderId, userId, status: 'completed' },
    });
    if (!order) throw new OrderNotFoundException();

    const existing = await this.prisma.review.findUnique({ where: { orderId } });
    if (existing) throw new DuplicateReviewException();

    const result = await this.prisma.$transaction(async (tx) => {
      // 1. Buat review
      const review = await tx.review.create({
        data: { orderId, userId, storeId: order.storeId,
                rating: dto.rating, comment: dto.comment },
      });

      // FIX B8: Update ratingAvg toko
      const agg = await tx.review.aggregate({
        where:  { storeId: order.storeId },
        _avg:   { rating: true },
        _count: { rating: true },
      });
      await tx.store.update({
        where: { id: order.storeId },
        data:  { ratingAvg: agg._avg.rating ?? 0 },
      });

      // FIX B9: Buat kupon reward Rp10.000
      const code   = `RWD-${Date.now().toString(36).toUpperCase()}-${nid().slice(0, 4)}`;
      const coupon = await tx.coupon.create({
        data: {
          userId,
          reviewId:  review.id,
          code,
          amount:    10000,
          expiredAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        },
      });

      return { review, coupon };
    });

    return result;
  }
}
```

---

## T-10 — Disputes Service

```typescript
// src/modules/disputes/disputes.service.ts
@Injectable()
export class DisputesService {
  async createDispute(orderId: string, userId: string, dto: CreateDisputeDto) {
    const order = await this.prisma.serviceOrder.findFirst({
      where: { id: orderId, userId, status: 'completed' },
      include: { store: true },
    });
    if (!order) throw new OrderNotFoundException();
    if (!order.warrantyExpiredAt || new Date() >= order.warrantyExpiredAt)
      throw new WarrantyExpiredException();

    // FIX: cek dispute aktif = status NOT IN (resolved, closed)
    const activeDispute = await this.prisma.dispute.findFirst({
      where: { orderId, status: { notIn: ['resolved', 'closed'] } },
    });
    if (activeDispute) throw new DisputeAlreadyActiveException();

    const dispute = await this.prisma.$transaction(async (tx) => {
      const d = await tx.dispute.create({
        data: {
          orderId, userId, storeId: order.storeId,
          disputeType:  dto.disputeType as any,
          description:  dto.description,
          evidenceUrls: dto.evidenceUrls ?? [],
          slaDeadline:  new Date(Date.now() + 24 * 60 * 60 * 1000),
        },
      });
      await tx.serviceOrder.update({
        where: { id: orderId },
        data:  { status: 'disputed',
                 slaDeadline: new Date(Date.now() + 24 * 60 * 60 * 1000) },
      });
      await tx.serviceTracking.create({
        data: { orderId, status: 'disputed', createdByType: 'customer',
                createdById: userId,
                note: `Klaim ${dto.disputeType} diajukan oleh pelanggan.` },
      });
      return d;
    });

    await this.notif.send(order.store.phoneNumber,
      `⚠️ Klaim garansi masuk untuk order ${order.orderNumber}. Respons dalam 24 jam.`,
      'dispute_created');
    return dispute;
  }

  async respondDispute(disputeId: string, adminId: string, storeId: string,
                       dto: RespondDisputeDto) {
    const dispute = await this.prisma.dispute.findFirst({
      where: { id: disputeId, storeId, status: 'open' },
      include: { order: { include: { user: true, store: true, items: true } } },
    });
    if (!dispute) throw new OrderNotFoundException();

    const newStatus = dto.decision === 'store_accepted'
      ? 'store_accepted' : 'store_rejected';

    await this.prisma.$transaction(async (tx) => {
      await tx.dispute.update({
        where: { id: disputeId },
        data:  { status: newStatus as any, storeResponse: dto.storeResponse,
                 resolvedAt: new Date() },
      });

      if (dto.decision === 'store_accepted') {
        // Buat warranty order baru
        const dateStr     = new Date().toISOString().slice(0, 10).replace(/-/g, '');
        const orderNumber = `SG-${dateStr}-${nid()}`;
        const warrantyOrder = await tx.serviceOrder.create({
          data: {
            userId:          dispute.order.userId,
            storeId,
            orderNumber,
            deviceType:      dispute.order.deviceType,
            brand:           dispute.order.brand,
            deviceModel:     dispute.order.deviceModel,
            deliveryMethod:  dispute.order.deliveryMethod,
            deliveryAddress: dispute.order.deliveryAddress,
            totalEstimasi:   0,
            finalPrice:      0,    // garansi gratis
            isWarrantyOrder: true,
            parentOrderId:   dispute.orderId,
            status:          'waiting_device',
            slaDeadline:     new Date(Date.now() + 24 * 60 * 60 * 1000),
            items: {
              create: dispute.order.items
                .filter(i => i.status === 'confirmed' || i.status === 'replaced')
                .map(i => ({
                  serviceType: i.serviceType,
                  complaint:   'Perbaikan ulang dalam garansi',
                  sparepartId: i.sparepartId,
                  itemPrice:   0,
                })),
            },
          },
        });
        await tx.dispute.update({
          where: { id: disputeId },
          data:  { warrantyOrderId: warrantyOrder.id },
        });
        await tx.serviceTracking.create({
          data: { orderId: warrantyOrder.id, status: 'waiting_device',
                  createdByType: 'system', createdById: 'system',
                  note: `Warranty order dari dispute ${disputeId}.` },
        });
        await tx.serviceOrder.update({
          where: { id: dispute.orderId },
          data:  { status: 'completed' },
        });
      }
    });

    await this.notif.send(dispute.order.user.phoneNumber,
      dto.decision === 'store_accepted'
        ? `✅ Klaim garansimu diterima! Order perbaikan ulang sudah dibuat.`
        : `❌ Klaim garansimu ditolak. Alasan: ${dto.storeResponse}`,
      'dispute_responded');

    return { status: newStatus };
  }
}
```

---

## T-11 — Notifications Service

```typescript
// src/modules/notifications/notifications.service.ts
@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(private config: ConfigService, private prisma: PrismaService) {}

  async send(target: string, message: string, messageType: string): Promise<void> {
    const delays = [60_000, 300_000, 900_000];
    for (let attempt = 1; attempt <= 3; attempt++) {
      try {
        await axios.post(
          this.config.get<string>('wa.gatewayUrl')!,
          { target, message, countryCode: '62' },
          { headers: { Authorization: this.config.get('wa.token') }, timeout: 10_000 },
        );
        return;
      } catch (err: any) {
        this.logger.warn(`WA attempt ${attempt}/3 gagal → ${target}: ${err.message}`);
        if (attempt < 3) await new Promise(r => setTimeout(r, delays[attempt - 1]));
        else {
          await this.prisma.failedNotification.create({
            data: { recipientType: 'whatsapp', recipientId: target,
                    messageType, payload: { target, message },
                    attemptCount: 3, lastError: err.message },
          }).catch(e => this.logger.error('Log failed notif error:', e));
        }
      }
    }
  }

  async sendNewOrderToStore(store: any, order: any, user: any,
                            isNew: boolean, rawPass?: string) {
    const lines = [
      `🔔 *Order Baru!*`,
      `No: ${order.orderNumber}`,
      `Pelanggan: ${user.fullName} (${user.phoneNumber})`,
      `Device: ${order.brand} ${order.deviceModel}`,
      `Estimasi: Rp ${Number(order.totalEstimasi).toLocaleString('id-ID')}`,
    ];
    if (isNew && rawPass) {
      lines.push('', `👤 *Pelanggan Baru* — kirim akun ini via WA:`,
        `HP: ${user.phoneNumber}`, `Password: ${rawPass}`,
        `_(berlaku 24 jam)_`);
    }
    await this.send(store.phoneNumber, lines.join('\n'), 'new_order');
  }

  async sendDiagnosisResult(phone: string, name: string,
                             orderNumber: string, finalPrice: number) {
    await this.send(phone, [
      `Halo ${name}! 🔧`,
      `Diagnosa selesai untuk order *${orderNumber}*.`,
      `Biaya Final: *Rp ${finalPrice.toLocaleString('id-ID')}*`,
      `Buka app ServisGadget untuk *Setuju* atau *Tolak* (batas 24 jam).`,
    ].join('\n'), 'diagnosis_result');
  }

  async sendWaitingPayment(phone: string, name: string,
                            orderNumber: string, amount: number) {
    await this.send(phone, [
      `Halo ${name}! ✅`,
      `Perbaikan order *${orderNumber}* selesai!`,
      `Silakan lakukan pembayaran: *Rp ${amount.toLocaleString('id-ID')}*`,
      `Buka app ServisGadget untuk upload bukti pembayaran.`,
    ].join('\n'), 'waiting_payment');
  }

  async sendOrderCompleted(phone: string, name: string,
                            orderNumber: string, method: string) {
    const info = method === 'walk_in'
      ? 'Silakan ambil perangkat ke toko.'
      : 'Perangkat sedang dalam proses pengiriman.';
    await this.send(phone, [
      `Halo ${name}! 🎉`,
      `Order *${orderNumber}* selesai!`, info,
      `Berikan ulasan dan dapatkan *kupon Rp10.000* ⭐`,
    ].join('\n'), 'order_completed');
  }

  async sendSlaWarning(phone: string, orderNumber: string, status: string) {
    await this.send(phone,
      `⚠️ Peringatan SLA! Order *${orderNumber}* (fase: ${status}) kurang dari 6 jam!`,
      'sla_warning');
  }
}
```

---

## T-12 — File Upload Service (Presigned URL)

```typescript
// src/modules/uploads/uploads.service.ts
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

@Injectable()
export class UploadsService {
  private s3: S3Client;

  constructor(private config: ConfigService) {
    this.s3 = new S3Client({
      region: 'auto',
      endpoint: config.get('storage.endpoint'),
      credentials: {
        accessKeyId:     config.get('storage.accessKey')!,
        secretAccessKey: config.get('storage.secretKey')!,
      },
    });
  }

  async generatePresignedUrl(
    folder: 'payments' | 'evidence' | 'avatars',
    fileName: string,
    mimeType: string,
  ): Promise<{ uploadUrl: string; fileUrl: string }> {
    const ext     = fileName.split('.').pop() ?? 'bin';
    const key     = `${folder}/${Date.now()}-${nid()}.${ext}`;
    const command = new PutObjectCommand({
      Bucket:      this.config.get('storage.bucket'),
      Key:         key,
      ContentType: mimeType,
    });
    const uploadUrl = await getSignedUrl(this.s3, command, { expiresIn: 300 });
    const fileUrl   = `${this.config.get('storage.publicUrl')}/${key}`;
    return { uploadUrl, fileUrl };
  }
}

// src/modules/uploads/uploads.controller.ts
@Controller('uploads')
@UseGuards(JwtAuthGuard)
export class UploadsController {
  @Post('presign')
  async presign(
    @Body() body: { fileName: string; mimeType: string; folder: string },
  ) {
    return this.uploadsService.generatePresignedUrl(
      body.folder as any, body.fileName, body.mimeType);
  }
}
```

---

## T-13 — Background Jobs

### SLA Monitor
```typescript
// src/modules/jobs/sla-monitor.job.ts
@Injectable()
export class SlaMonitorJob {
  private readonly logger = new Logger(SlaMonitorJob.name);

  constructor(private prisma: PrismaService, private notif: NotificationsService) {}

  @Cron('*/15 * * * *')
  async run(): Promise<void> {
    const now           = new Date();
    const warnThreshold = new Date(now.getTime() + 6 * 60 * 60 * 1000);

    // 1. Warning T-6 jam
    const nearDeadline = await this.prisma.serviceOrder.findMany({
      where: {
        status:      { notIn: ['completed', 'cancelled', 'disputed'] },
        slaDeadline: { lte: warnThreshold, gte: now },
        slaWarnedAt: null,
      },
      include: { store: true },
    });
    for (const o of nearDeadline) {
      await this.notif.sendSlaWarning(o.store.phoneNumber, o.orderNumber, o.status);
      await this.prisma.serviceOrder.update({
        where: { id: o.id }, data: { slaWarnedAt: now },
      });
    }

    // 2. Auto-cancel overdue
    // Dikecualikan: waiting_approval (customer harus respond)
    //               disputed (toko harus respond)
    const overdue = await this.prisma.serviceOrder.findMany({
      where: {
        status:      { notIn: ['completed', 'cancelled', 'waiting_approval', 'disputed'] },
        slaDeadline: { lt: now },
      },
      include: { store: true, user: true, items: true },
    });

    for (const o of overdue) {
      const postApproval = ['repairing', 'quality_check', 'waiting_payment']
        .includes(o.status);

      await this.prisma.$transaction(async (tx) => {
        for (const item of o.items) {
          if (!item.sparepartId) continue;
          if (postApproval) {
            // Stok sudah di-decrement saat approve → kembalikan
            await tx.sparePart.update({
              where: { id: item.sparepartId },
              data:  { qty: { increment: 1 } },
            });
          } else {
            // Stok belum di-decrement → hanya rollback reserve
            await tx.sparePart.update({
              where: { id: item.sparepartId },
              data:  { qtyReserved: { decrement: 1 } },
            });
          }
        }
        await tx.serviceOrder.update({
          where: { id: o.id },
          data:  { status: 'cancelled', cancelledAt: now,
                   slaBreachCount: { increment: 1 } },
        });
        await tx.serviceTracking.create({
          data: { orderId: o.id, status: 'cancelled', createdByType: 'system',
                  createdById: 'system',
                  note: `Auto-cancelled: SLA breach (${o.status}).` },
        });
        await tx.store.update({
          where: { id: o.storeId },
          data:  { penaltyPoints: { increment: 1 } },
        });
      });
      this.logger.warn(`Auto-cancelled: ${o.orderNumber} (was: ${o.status})`);
    }
  }
}
```

### Credential Cleaner
```typescript
// src/modules/jobs/credential-cleaner.job.ts
@Injectable()
export class CredentialCleanerJob {
  constructor(private prisma: PrismaService, private config: ConfigService) {}

  @Cron(CronExpression.EVERY_HOUR)
  async run(): Promise<void> {
    const ttl    = this.config.get<number>('sla.credentialClear') ?? 1440;
    const cutoff = new Date(Date.now() - ttl * 60 * 1000);

    const result = await this.prisma.user.updateMany({
      where: {
        credentialPlainEnc: { not: null },
        OR: [
          { isCredentialSent: true },
          { createdAt: { lte: cutoff } },
        ],
      },
      data: { credentialPlainEnc: null },
    });
    if (result.count > 0)
      console.log(`[CredentialCleaner] Cleared ${result.count} expired credentials`);
  }
}
```

---

## T-14 — Seed Data

```typescript
// prisma/seed.ts
import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { generatePassword } from '../src/modules/auth/utils/password.util';
import { encryptCredential } from '../src/modules/auth/utils/encryption.util';

const prisma = new PrismaClient();

async function main() {
  const store = await prisma.store.create({
    data: {
      storeName: 'Toko Servis Maju Jaya',
      address:   'Jl. Sudirman No. 42, Jakarta Pusat',
      phoneNumber: '+6281234560001',
      operationalHours: {
        mon:'08:00-20:00', tue:'08:00-20:00', wed:'08:00-20:00',
        thu:'08:00-20:00', fri:'08:00-17:00', sat:'08:00-15:00', sun:'closed',
      },
      config: {
        service_fee:       { screen_replacement:50000, battery_replacement:30000, other:25000 },
        warranty_days:     30,
        diagnosis_fee:     20000,
        low_stock_threshold: 2,
        deposit_required:  false,
      },
      isActive:   true,
      verifiedAt: new Date(),
    },
  });

  const adminRawPass = 'admin123456';
  await prisma.storeAdmin.create({
    data: {
      storeId:      store.id,
      fullName:     'Ahmad Fauzi',
      phoneNumber:  '+6281234560001',
      passwordHash: await bcrypt.hash(adminRawPass, 12),
      isActive:     true,
      isFirstLogin: false,
    },
  });

  await prisma.sparePart.createMany({
    data: [
      { storeId: store.id, brand:'Samsung', deviceModel:'Galaxy S24 Ultra',
        partType:'screen_replacement', partName:'LCD Samsung S24 Ultra Original',
        price: 800000, qty: 5, qtyReserved: 0 },
      { storeId: store.id, brand:'Samsung', deviceModel:'Galaxy S24 Ultra',
        partType:'battery_replacement', partName:'Baterai Samsung S24 Ultra ORI',
        price: 350000, qty: 3, qtyReserved: 0 },
      { storeId: store.id, brand:'Apple', deviceModel:'iPhone 15 Pro',
        partType:'screen_replacement', partName:'LCD iPhone 15 Pro Original',
        price: 1200000, qty: 2, qtyReserved: 0 },
    ],
  });

  // Test customer
  const custPhone = '+628123456789';
  const custRaw   = generatePassword('Budi Santoso', custPhone);
  await prisma.user.create({
    data: {
      fullName:          'Budi Santoso',
      phoneNumber:       custPhone,
      passwordHash:      await bcrypt.hash(custRaw, 12),
      credentialPlainEnc: encryptCredential(custRaw),
      isFirstLogin:      true,
      isCredentialSent:  false,
    },
  });

  console.log('Seed OK');
  console.log(`Customer: ${custPhone} / ${custRaw}`);
  console.log(`Admin:    +6281234560001 / ${adminRawPass}`);
}

main().catch(console.error).finally(() => prisma.$disconnect());
```

---

## Flutter Foundation

### pubspec.yaml (lengkap)
```yaml
name: servisgadget_shared
description: Shared Flutter layer for ServisGadget

environment:
  sdk: '>=3.3.0 <4.0.0'
  flutter: '>=3.29.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  go_router: ^14.2.0
  dio: ^5.4.3+1
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0
  flutter_secure_storage: ^9.2.2
  image_picker: ^1.1.2
  cached_network_image: ^3.3.1
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.9
  freezed: ^2.5.2
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
  custom_lint: ^0.6.4
  riverpod_lint: ^2.3.10
```

### lib/core/network/api_client.dart
```dart
class ApiClient {
  static Dio createAuthenticatedDio(SecureStorageService storage) {
    final dio = Dio(BaseOptions(
      baseUrl:        ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ));
    dio.interceptors.add(TokenInterceptor(dio, storage));
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    return dio;
  }

  // Untuk POST /v1/orders yang PUBLIC (tanpa token)
  static Dio createPublicDio() {
    return Dio(BaseOptions(
      baseUrl:        ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ));
  }
}
```

### lib/core/network/token_interceptor.dart
```dart
class TokenInterceptor extends Interceptor {
  final Dio _dio;
  final SecureStorageService _storage;
  bool _isRefreshing = false;
  final _queue = <({RequestOptions opts, ErrorInterceptorHandler handler})>[];

  TokenInterceptor(this._dio, this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.getAccessToken();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) { handler.next(err); return; }

    if (_isRefreshing) {
      _queue.add((opts: err.requestOptions, handler: handler));
      return;
    }
    _isRefreshing = true;

    try {
      final refresh = await _storage.getRefreshToken();
      if (refresh == null) throw Exception('No refresh token');

      final resp = await Dio().post(
        '${ApiConstants.baseUrl}/auth/refresh',
        data: {'refresh_token': refresh},
      );
      final newAccess  = resp.data['data']['access_token'] as String;
      final newRefresh = resp.data['data']['refresh_token'] as String;
      await _storage.saveTokens(newAccess, newRefresh);

      // Retry request asal
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
      final retry = await _dio.fetch(err.requestOptions);
      handler.resolve(retry);

      // Retry semua yang antri
      for (final q in _queue) {
        q.opts.headers['Authorization'] = 'Bearer $newAccess';
        final r = await _dio.fetch(q.opts);
        q.handler.resolve(r);
      }
    } catch (_) {
      await _storage.clearAll();
      for (final q in _queue) q.handler.reject(err);
      handler.reject(err);
    } finally {
      _isRefreshing = false;
      _queue.clear();
    }
  }
}
```

### lib/shared/models/service_order.dart (contoh model dengan Freezed)
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'service_order.freezed.dart';
part 'service_order.g.dart';

enum OrderStatus {
  @JsonValue('waiting_device')    waitingDevice,
  @JsonValue('device_received')   deviceReceived,
  @JsonValue('diagnosing')        diagnosing,
  @JsonValue('waiting_approval')  waitingApproval,
  @JsonValue('waiting_sparepart') waitingSparepart,
  @JsonValue('repairing')         repairing,
  @JsonValue('quality_check')     qualityCheck,
  @JsonValue('waiting_payment')   waitingPayment,
  @JsonValue('completed')         completed,
  @JsonValue('cancelled')         cancelled,
  @JsonValue('disputed')          disputed;

  String get label => switch (this) {
    waitingDevice    => 'Menunggu Perangkat Diterima',
    deviceReceived   => 'Perangkat Diterima Toko',
    diagnosing       => 'Sedang Diagnosa',
    waitingApproval  => 'Menunggu Persetujuanmu',
    waitingSparepart => 'Menunggu     waitingSparepart => 'Menunggu Sparepart',
    repairing        => 'Sedang Diperbaiki',
    qualityCheck     => 'Quality Check',
    waitingPayment   => 'Menunggu Pembayaran',
    completed        => 'Selesai',
    cancelled        => 'Dibatalkan',
    disputed         => 'Dalam Klaim Garansi',
  };

  bool get isTerminal => this == completed || this == cancelled;
  bool get isActive   => !isTerminal;
}

@freezed
class ServiceOrder with _$ServiceOrder {
  const factory ServiceOrder({
    required String id,
    required String userId,
    required String storeId,
    required String orderNumber,
    @JsonKey(name: 'device_type')     required String deviceType,
    required String brand,
    @JsonKey(name: 'device_model')    required String deviceModel,
    @JsonKey(name: 'delivery_method') required String deliveryMethod,
    @JsonKey(name: 'delivery_address') String? deliveryAddress,
    required OrderStatus status,
    @JsonKey(name: 'payment_status')  required String paymentStatus,
    @JsonKey(name: 'total_estimasi')  required double totalEstimasi,
    @JsonKey(name: 'final_price')     double? finalPrice,
    @JsonKey(name: 'warranty_days')   int? warrantyDays,
    @JsonKey(name: 'warranty_expired_at') DateTime? warrantyExpiredAt,
    @JsonKey(name: 'sla_deadline')    DateTime? slaDeadline,
    @Default([]) List<dynamic> items,
    @Default([]) List<dynamic> tracking,
    @JsonKey(name: 'created_at')      required DateTime createdAt,
  }) = _ServiceOrder;

  factory ServiceOrder.fromJson(Map<String, dynamic> json) =>
      _$ServiceOrderFromJson(json);
}
```

---

## Acceptance Criteria Fase 1

- [ ] AC-01 Customer login benar → 200 + `is_first_login`
- [ ] AC-02 Customer login salah 5x → 423, lockedUntil ada di DB
- [ ] AC-03 Store admin login → 200 + JWT payload berisi `storeId`
- [ ] AC-04 Store token di customer endpoint → 403
- [ ] AC-05 Customer token di store endpoint → 403
- [ ] AC-06 `change-password` → isFirstLogin=false, sesi lama invalid
- [ ] AC-07 `GET /v1/me` saat isFirstLogin=true → 403
- [ ] AC-08 `POST /v1/orders` tanpa JWT → 201, user baru, qtyReserved+1
- [ ] AC-09 `POST /v1/orders` HP yang ada → linked ke akun lama
- [ ] AC-10 `POST /v1/orders` stok habis → 409
- [ ] AC-11 itemPrice = sparepart.price (bukan 0)
- [ ] AC-12 approve → qty-=1 + qtyReserved-=1
- [ ] AC-13 reject → qtyReserved-=1, qty TIDAK berubah
- [ ] AC-14 Race condition approve → salah satu 409, rollback bersih
- [ ] AC-15 submitDiagnosis → finalPrice benar, status=waiting_approval
- [ ] AC-16 replaced tanpa replacedSparepartId → 400
- [ ] AC-17 PATCH status=completed → 422
- [ ] AC-18 confirmPayment → warrantyDays dari store.config, warrantyExpiredAt benar
- [ ] AC-19 totalCompleted toko +1
- [ ] AC-20 createReview → ratingAvg update, kupon dibuat
- [ ] AC-21 Review duplikat → 409
- [ ] AC-22 createDispute dalam garansi → OK
- [ ] AC-23 createDispute setelah expired → 422
- [ ] AC-24 createDispute saat ada aktif → 409
- [ ] AC-25 respondDispute store_accepted → warranty order baru
- [ ] AC-26 credential panel → password ada untuk pelanggan baru
- [ ] AC-27 mark-sent → credentialPlainEnc=null
- [ ] AC-28 SLA Monitor → auto-cancel + rollback stok
- [ ] AC-29 `build_runner build` → 0 error
- [ ] AC-30 `flutter analyze` → 0 error

---

## Output Branch
`feature/fase-1-foundation` — merge ke `develop` setelah semua 30 AC hijau.
