# ServisGadget — 00 Master PRD
## Single Source of Truth · v3.0

> **Cara pakai untuk AI agent:** Baca file ini dulu sebelum file fase manapun.
> Semua keputusan sudah final. Jangan improvise — jika tidak ada di sini, tanya dulu.

---

## 1. Gambaran Sistem

Platform marketplace dua sisi. Pelanggan tidak pernah diminta mendaftar (stealth account). Admin toko menerima order, diagnosa, dan konfirmasi pembayaran via mobile app.

### Tiga Aktor

| Aktor | Tabel | Login Endpoint | JWT `role` |
|---|---|---|---|
| Pelanggan | `users` | `POST /v1/auth/login` | `customer` |
| Admin Toko | `store_admins` | `POST /v1/store/auth/login` | `store_admin` |
| Sistem | — | — | — |

> ⚠️ DUA ENTITAS AUTH TERPISAH. `store_admin` bukan `user`. Login endpoint berbeda, tabel berbeda, JWT strategy berbeda.

---

## 2. Tech Stack — Versi Exact, Tidak Ada Alternatif

### Backend
```
Node.js          20.11.0 LTS
TypeScript       5.x  (strict: true)
NestJS           10.x
Prisma           5.x
PostgreSQL       16
Redis            7.x
BullMQ           5.x
@nestjs/jwt      10.x
bcrypt           cost factor 12
class-validator  0.14.x
axios            1.6.x
nanoid           5.x       ← untuk order number, BUKAN uuid
```

### Install command (copy-paste sekali):
```bash
npm install @nestjs/jwt @nestjs/passport @nestjs/config @nestjs/throttler \
  @nestjs/schedule @nestjs/bullmq bullmq ioredis \
  passport passport-jwt bcrypt class-validator class-transformer \
  axios nanoid @aws-sdk/client-s3

npm install -D prisma @types/bcrypt @types/passport-jwt
```

### Flutter (pubspec.yaml — bagian dependencies)
```yaml
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

---

## 3. Prisma Schema Lengkap — Copy-paste ke `prisma/schema.prisma`

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// ─── ENUMS ────────────────────────────────────────────────────────────────────

enum AccountStatus       { active suspended deleted }
enum DeviceType          { android ios }
enum DeliveryMethod      { walk_in courier_pickup }
enum OrderStatus {
  waiting_device
  device_received
  diagnosing
  waiting_approval
  waiting_sparepart
  repairing
  quality_check
  waiting_payment
  completed
  cancelled
  disputed
}
enum PaymentStatus       { unpaid partially_paid paid refunded }
enum PaymentMethod       { transfer_bank qris cash ewallet }
enum PaymentType         { deposit final_payment refund }
enum PaymentRecordStatus { pending confirmed failed refunded }
enum SparePartStatus     { available preorder discontinued }
enum OrderItemStatus     { pending confirmed replaced cancelled }
enum ShipmentType        { pickup return warranty_pickup }
enum ShipmentStatus      { scheduled picked_up in_transit delivered failed }
enum DisputeType         { warranty_claim service_quality wrong_diagnosis other }
enum DisputeStatus       { open store_accepted store_rejected escalated resolved closed }
enum CreatedByType       { customer store_admin system }
enum ApplicationStatus   { pending approved rejected }
enum FeeBearerType       { customer store platform }

// ─── USERS (Pelanggan) ────────────────────────────────────────────────────────

model User {
  id                 String        @id @default(uuid())
  fullName           String        @map("full_name") @db.VarChar(150)
  phoneNumber        String        @unique @map("phone_number") @db.VarChar(20)
  passwordHash       String        @map("password_hash") @db.VarChar(255)
  avatarUrl          String?       @map("avatar_url") @db.VarChar(255)
  address            String?       @db.Text
  accountStatus      AccountStatus @default(active) @map("account_status")
  isFirstLogin       Boolean       @default(true) @map("is_first_login")
  isCredentialSent   Boolean       @default(false) @map("is_credential_sent")
  credentialPlainEnc String?       @map("credential_plain_enc") @db.Text
  loginAttemptCount  Int           @default(0) @map("login_attempt_count") @db.SmallInt
  lockedUntil        DateTime?     @map("locked_until") @db.Timestamptz
  lastLoginAt        DateTime?     @map("last_login_at") @db.Timestamptz
  passwordChangedAt  DateTime?     @map("password_changed_at") @db.Timestamptz
  createdAt          DateTime      @default(now()) @map("created_at") @db.Timestamptz
  updatedAt          DateTime      @updatedAt @map("updated_at") @db.Timestamptz
  orders             ServiceOrder[]
  payments           Payment[]
  reviews            Review[]
  coupons            Coupon[]
  disputes           Dispute[]
  sessions           UserSession[]
  @@map("users")
}

// ─── STORE ADMINS ─────────────────────────────────────────────────────────────

model StoreAdmin {
  id           String    @id @default(uuid())
  storeId      String    @map("store_id")
  fullName     String    @map("full_name") @db.VarChar(150)
  phoneNumber  String    @map("phone_number") @db.VarChar(20)
  passwordHash String    @map("password_hash") @db.VarChar(255)
  isActive     Boolean   @default(true) @map("is_active")
  isFirstLogin Boolean   @default(false) @map("is_first_login")
  lastLoginAt  DateTime? @map("last_login_at") @db.Timestamptz
  createdAt    DateTime  @default(now()) @map("created_at") @db.Timestamptz
  store        Store     @relation(fields: [storeId], references: [id])
  @@unique([storeId, phoneNumber])
  @@map("store_admins")
}

// ─── STORES ───────────────────────────────────────────────────────────────────

model Store {
  id               String       @id @default(uuid())
  storeName        String       @map("store_name") @db.VarChar(150)
  address          String       @db.Text
  phoneNumber      String       @map("phone_number") @db.VarChar(20)
  operationalHours Json         @default("{}") @map("operational_hours")
  // Shape: { "mon":"08:00-20:00", "tue":"08:00-20:00", ..., "sun":"closed" }
  config           Json         @default("{}")
  // Shape: { "service_fee":{"screen_replacement":50000}, "warranty_days":30,
  //          "diagnosis_fee":20000, "low_stock_threshold":2, "deposit_required":false }
  isActive         Boolean      @default(false) @map("is_active")
  ratingAvg        Decimal      @default(0) @map("rating_avg") @db.Decimal(3, 2)
  totalCompleted   Int          @default(0) @map("total_completed")
  penaltyPoints    Int          @default(0) @map("penalty_points")
  verifiedAt       DateTime?    @map("verified_at") @db.Timestamptz
  createdAt        DateTime     @default(now()) @map("created_at") @db.Timestamptz
  updatedAt        DateTime     @updatedAt @map("updated_at") @db.Timestamptz
  admins           StoreAdmin[]
  spareparts       SparePart[]
  orders           ServiceOrder[]
  reviews          Review[]
  disputes         Dispute[]
  @@map("stores")
}

// ─── STORE APPLICATIONS ───────────────────────────────────────────────────────

model StoreApplication {
  id                 String            @id @default(uuid())
  storeName          String            @map("store_name") @db.VarChar(150)
  applicantName      String            @map("applicant_name") @db.VarChar(150)
  phoneNumber        String            @map("phone_number") @db.VarChar(20)
  address            String            @db.Text
  businessLicenseUrl String?           @map("business_license_url") @db.VarChar(255)
  idCardUrl          String            @map("id_card_url") @db.VarChar(255)
  status             ApplicationStatus @default(pending)
  reviewedBy         String?           @map("reviewed_by")
  reviewNote         String?           @map("review_note") @db.Text
  appliedAt          DateTime          @default(now()) @map("applied_at") @db.Timestamptz
  reviewedAt         DateTime?         @map("reviewed_at") @db.Timestamptz
  @@map("store_applications")
}

// ─── SPAREPARTS ───────────────────────────────────────────────────────────────

model SparePart {
  id          String          @id @default(uuid())
  storeId     String          @map("store_id")
  brand       String          @db.VarChar(80)
  deviceModel String          @map("device_model") @db.VarChar(100)
  partType    String          @map("part_type") @db.VarChar(60)
  // Nilai valid: screen_replacement | battery_replacement | charging_port | camera | other
  partName    String          @map("part_name") @db.VarChar(150)
  price       Decimal         @db.Decimal(12, 2)
  qty         Int             @default(0)
  qtyReserved Int             @default(0) @map("qty_reserved")
  // qty_available (computed) = qty - qtyReserved — JANGAN simpan di DB
  status      SparePartStatus @default(available)
  createdAt   DateTime        @default(now()) @map("created_at") @db.Timestamptz
  updatedAt   DateTime        @updatedAt @map("updated_at") @db.Timestamptz
  store       Store           @relation(fields: [storeId], references: [id])
  orderItems  OrderItem[]
  @@index([storeId])
  @@index([brand, deviceModel, partType])
  @@map("spareparts")
}

// ─── SERVICE ORDERS ───────────────────────────────────────────────────────────

model ServiceOrder {
  id               String        @id @default(uuid())
  userId           String        @map("user_id")
  storeId          String        @map("store_id")
  orderNumber      String        @unique @map("order_number") @db.VarChar(30)
  // Format: SG-YYYYMMDD-XXXX (generated dengan nanoid, bukan count)
  deviceType       DeviceType    @map("device_type")
  brand            String        @db.VarChar(80)
  deviceModel      String        @map("device_model") @db.VarChar(100)
  deliveryMethod   DeliveryMethod @map("delivery_method")
  deliveryAddress  String?       @map("delivery_address") @db.Text
  status           OrderStatus   @default(waiting_device)
  paymentStatus    PaymentStatus @default(unpaid) @map("payment_status")
  totalEstimasi    Decimal       @default(0) @map("total_estimasi") @db.Decimal(12, 2)
  discountAmount   Decimal       @default(0) @map("discount_amount") @db.Decimal(12, 2)
  finalPrice       Decimal?      @map("final_price") @db.Decimal(12, 2)
  // Diisi saat admin submit diagnosis: SUM(finalItemPrice confirmed) + serviceFee
  serviceFee       Decimal?      @map("service_fee") @db.Decimal(12, 2)
  diagnosisNote    String?       @map("diagnosis_note") @db.Text
  warrantyDays     Int?          @map("warranty_days")
  // Diisi dari store.config.warranty_days saat payment dikonfirmasi
  warrantyExpiredAt DateTime?    @map("warranty_expired_at") @db.Timestamptz
  slaDeadline      DateTime?     @map("sla_deadline") @db.Timestamptz
  slaWarnedAt      DateTime?     @map("sla_warned_at") @db.Timestamptz
  slaBreachCount   Int           @default(0) @map("sla_breach_count") @db.SmallInt
  couponId         String?       @map("coupon_id")
  isWarrantyOrder  Boolean       @default(false) @map("is_warranty_order")
  parentOrderId    String?       @map("parent_order_id")
  completedAt      DateTime?     @map("completed_at") @db.Timestamptz
  cancelledAt      DateTime?     @map("cancelled_at") @db.Timestamptz
  createdAt        DateTime      @default(now()) @map("created_at") @db.Timestamptz
  updatedAt        DateTime      @updatedAt @map("updated_at") @db.Timestamptz
  user             User          @relation(fields: [userId], references: [id])
  store            Store         @relation(fields: [storeId], references: [id])
  coupon           Coupon?       @relation("OrderCoupon", fields: [couponId], references: [id])
  items            OrderItem[]
  tracking         ServiceTracking[]
  payments         Payment[]
  shipments        Shipment[]
  review           Review?
  dispute          Dispute?
  @@index([userId])
  @@index([storeId])
  @@index([status])
  @@map("service_orders")
}

// ─── ORDER ITEMS ──────────────────────────────────────────────────────────────

model OrderItem {
  id             String          @id @default(uuid())
  orderId        String          @map("order_id")
  sparepartId    String?         @map("sparepart_id")
  serviceType    String          @map("service_type") @db.VarChar(100)
  complaint      String          @db.Text
  itemPrice      Decimal         @map("item_price") @db.Decimal(12, 2)
  // Estimasi dari sparepart.price saat booking. 0 jika tidak ada sparepartId.
  finalItemPrice Decimal?        @map("final_item_price") @db.Decimal(12, 2)
  // Diisi admin saat submit diagnosis
  status         OrderItemStatus @default(pending)
  technicianNote String?         @map("technician_note") @db.Text
  order          ServiceOrder    @relation(fields: [orderId], references: [id], onDelete: Cascade)
  sparepart      SparePart?      @relation(fields: [sparepartId], references: [id])
  @@map("order_items")
}

// ─── SERVICE TRACKING (IMMUTABLE) ────────────────────────────────────────────

model ServiceTracking {
  id            String        @id @default(uuid())
  orderId       String        @map("order_id")
  status        OrderStatus
  note          String?       @db.Text
  createdByType CreatedByType @map("created_by_type")
  createdById   String        @map("created_by_id")
  createdAt     DateTime      @default(now()) @map("created_at") @db.Timestamptz
  // ⚠️ IMMUTABLE — JANGAN UPDATE atau DELETE baris di tabel ini
  order         ServiceOrder  @relation(fields: [orderId], references: [id])
  @@map("service_tracking")
}

// ─── PAYMENTS ────────────────────────────────────────────────────────────────

model Payment {
  id            String              @id @default(uuid())
  orderId       String              @map("order_id")
  userId        String              @map("user_id")
  amount        Decimal             @db.Decimal(12, 2)
  paymentMethod PaymentMethod       @map("payment_method")
  paymentType   PaymentType         @map("payment_type")
  status        PaymentRecordStatus @default(pending)
  proofUrl      String?             @map("proof_url") @db.VarChar(255)
  confirmedBy   String?             @map("confirmed_by")
  confirmedAt   DateTime?           @map("confirmed_at") @db.Timestamptz
  createdAt     DateTime            @default(now()) @map("created_at") @db.Timestamptz
  order         ServiceOrder        @relation(fields: [orderId], references: [id])
  user          User                @relation(fields: [userId], references: [id])
  @@map("payments")
}

// ─── SHIPMENTS ───────────────────────────────────────────────────────────────

model Shipment {
  id                 String         @id @default(uuid())
  orderId            String         @map("order_id")
  shipmentType       ShipmentType   @map("shipment_type")
  courierName        String?        @map("courier_name") @db.VarChar(80)
  trackingNumber     String?        @unique @map("tracking_number") @db.VarChar(100)
  pickupAddress      String         @map("pickup_address") @db.Text
  destinationAddress String         @map("destination_address") @db.Text
  status             ShipmentStatus @default(scheduled)
  scheduledAt        DateTime?      @map("scheduled_at") @db.Timestamptz
  deliveredAt        DateTime?      @map("delivered_at") @db.Timestamptz
  shippingFee        Decimal        @default(0) @map("shipping_fee") @db.Decimal(12, 2)
  feeBearer          FeeBearerType  @default(customer) @map("fee_bearer")
  notes              String?        @db.Text
  createdAt          DateTime       @default(now()) @map("created_at") @db.Timestamptz
  order              ServiceOrder   @relation(fields: [orderId], references: [id])
  @@map("shipments")
}

// ─── REVIEWS ──────────────────────────────────────────────────────────────────

model Review {
  id        String       @id @default(uuid())
  orderId   String       @unique @map("order_id")
  userId    String       @map("user_id")
  storeId   String       @map("store_id")
  rating    Int          @db.SmallInt   // 1-5, validated in service layer
  comment   String?      @db.Text
  isPublic  Boolean      @default(true) @map("is_public")
  createdAt DateTime     @default(now()) @map("created_at") @db.Timestamptz
  order     ServiceOrder @relation(fields: [orderId], references: [id])
  user      User         @relation(fields: [userId], references: [id])
  store     Store        @relation(fields: [storeId], references: [id])
  coupon    Coupon?
  @@map("reviews")
}

// ─── COUPONS ──────────────────────────────────────────────────────────────────

model Coupon {
  id            String        @id @default(uuid())
  userId        String        @map("user_id")
  reviewId      String        @unique @map("review_id")
  code          String        @unique @db.VarChar(20)
  amount        Decimal       @default(10000) @db.Decimal(12, 2)
  isUsed        Boolean       @default(false) @map("is_used")
  usedAt        DateTime?     @map("used_at") @db.Timestamptz
  usedOnOrderId String?       @map("used_on_order_id")
  expiredAt     DateTime      @map("expired_at") @db.Timestamptz
  createdAt     DateTime      @default(now()) @map("created_at") @db.Timestamptz
  user          User          @relation(fields: [userId], references: [id])
  review        Review        @relation(fields: [reviewId], references: [id])
  usedOnOrder   ServiceOrder? @relation("OrderCoupon", fields: [usedOnOrderId], references: [id])
  @@map("coupons")
}

// ─── DISPUTES ────────────────────────────────────────────────────────────────

model Dispute {
  id               String        @id @default(uuid())
  orderId          String        @unique @map("order_id")
  // UNIQUE: satu order hanya bisa punya satu dispute aktif pada satu waktu
  userId           String        @map("user_id")
  storeId          String        @map("store_id")
  disputeType      DisputeType   @map("dispute_type")
  description      String        @db.Text
  evidenceUrls     Json          @default("[]") @map("evidence_urls")
  status           DisputeStatus @default(open)
  storeResponse    String?       @map("store_response") @db.Text
  platformDecision String?       @map("platform_decision") @db.Text
  resolution       String?       @db.Text
  warrantyOrderId  String?       @map("warranty_order_id")
  resolvedAt       DateTime?     @map("resolved_at") @db.Timestamptz
  slaDeadline      DateTime?     @map("sla_deadline") @db.Timestamptz
  createdAt        DateTime      @default(now()) @map("created_at") @db.Timestamptz
  order            ServiceOrder  @relation(fields: [orderId], references: [id])
  user             User          @relation(fields: [userId], references: [id])
  store            Store         @relation(fields: [storeId], references: [id])
  @@map("disputes")
}

// ─── USER SESSIONS ────────────────────────────────────────────────────────────

model UserSession {
  id           String   @id @default(uuid())
  userId       String   @map("user_id")
  tokenHash    String   @unique @map("token_hash") @db.VarChar(64)
  // tokenHash = SHA-256(refreshToken) dalam hex
  deviceInfo   Json?    @map("device_info")
  ipAddress    String?  @map("ip_address") @db.VarChar(45)
  isActive     Boolean  @default(true) @map("is_active")
  expiresAt    DateTime @map("expires_at") @db.Timestamptz
  lastActiveAt DateTime @default(now()) @map("last_active_at") @db.Timestamptz
  createdAt    DateTime @default(now()) @map("created_at") @db.Timestamptz
  user         User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  @@index([userId, isActive])
  @@map("user_sessions")
}

// ─── FAILED NOTIFICATIONS ────────────────────────────────────────────────────

model FailedNotification {
  id            String   @id @default(uuid())
  recipientType String   @map("recipient_type") @db.VarChar(20)
  recipientId   String   @map("recipient_id")
  channel       String   @default("whatsapp") @db.VarChar(20)
  messageType   String   @map("message_type") @db.VarChar(50)
  payload       Json
  attemptCount  Int      @default(0) @map("attempt_count") @db.SmallInt
  lastError     String?  @map("last_error") @db.Text
  createdAt     DateTime @default(now()) @map("created_at") @db.Timestamptz
  @@map("failed_notifications")
}
```

**Setelah `npx prisma migrate dev --name init`, tambahkan constraint manual:**
```sql
ALTER TABLE spareparts ADD CONSTRAINT spareparts_qty_nonneg CHECK (qty >= 0);
ALTER TABLE spareparts ADD CONSTRAINT spareparts_qty_reserved_nonneg CHECK (qty_reserved >= 0);
ALTER TABLE reviews ADD CONSTRAINT reviews_rating_range CHECK (rating BETWEEN 1 AND 5);
```

---

## 4. Semua DTOs — Copy-paste langsung

### Auth DTOs
```typescript
// src/modules/auth/dto/auth.dto.ts
import { IsString, IsNotEmpty, MinLength } from 'class-validator';
import { Transform } from 'class-transformer';

export function normalizePhone(phone: string): string {
  const d = phone.replace(/\D/g, '');
  if (d.startsWith('62')) return `+${d}`;
  if (d.startsWith('0'))  return `+62${d.slice(1)}`;
  return `+62${d}`;
}

export class LoginDto {
  @IsString() @IsNotEmpty()
  @Transform(({ value }) => normalizePhone(value))
  phoneNumber: string;

  @IsString() @IsNotEmpty()
  password: string;
}

export class ChangePasswordDto {
  @IsString() @IsNotEmpty() oldPassword: string;
  @IsString() @MinLength(8) newPassword: string;
}

export class RefreshTokenDto {
  @IsString() @IsNotEmpty() refreshToken: string;
}
```

### Order DTOs
```typescript
// src/modules/orders/dto/order.dto.ts
import { Type, Transform } from 'class-transformer';
import {
  IsString, IsEnum, IsArray, ValidateNested, IsNotEmpty,
  IsOptional, IsUUID, MinLength, ArrayMinSize, IsNumber, Min,
} from 'class-validator';
import { normalizePhone } from '../../auth/dto/auth.dto';

export class CreateOrderItemDto {
  @IsEnum(['screen_replacement','battery_replacement','charging_port','camera','other'])
  serviceType: string;

  @IsString() @MinLength(10) complaint: string;

  @IsOptional() @IsUUID() sparepartId?: string;
}

export class CreateOrderDto {
  @IsEnum(['android','ios']) deviceType: string;
  @IsString() @IsNotEmpty() brand: string;
  @IsString() @IsNotEmpty() deviceModel: string;
  @IsUUID() storeId: string;
  @IsEnum(['walk_in','courier_pickup']) deliveryMethod: string;
  @IsOptional() @IsString() deliveryAddress?: string;
  @IsString() @IsNotEmpty() customerName: string;

  @IsString()
  @Transform(({ value }) => normalizePhone(value))
  phoneNumber: string;

  @IsOptional() @IsString() couponCode?: string;

  @IsArray() @ArrayMinSize(1)
  @ValidateNested({ each: true }) @Type(() => CreateOrderItemDto)
  items: CreateOrderItemDto[];
}

export class DiagnosisItemDto {
  @IsUUID() orderItemId: string;
  @IsEnum(['confirmed','replaced','cancelled']) status: string;
  // replacedSparepartId WAJIB jika status === 'replaced'
  @IsOptional() @IsUUID() replacedSparepartId?: string;
  @IsNumber() @Min(0) finalItemPrice: number;
  @IsOptional() @IsString() technicianNote?: string;
}

export class SubmitDiagnosisDto {
  @IsOptional() @IsString() diagnosisNote?: string;
  @IsNumber() @Min(0) serviceFee: number;
  @IsArray() @ValidateNested({ each: true }) @Type(() => DiagnosisItemDto)
  items: DiagnosisItemDto[];
}

export class UpdateOrderStatusDto {
  // Endpoint ini HANYA untuk store_admin, TIDAK termasuk 'completed'
  // 'completed' hanya lewat payment confirm
  @IsEnum([
    'device_received','diagnosing','waiting_sparepart',
    'repairing','quality_check','waiting_payment','cancelled',
  ])
  status: string;

  @IsOptional() @IsString() note?: string;
}
```

### Payment DTOs
```typescript
export class CreatePaymentDto {
  @IsNumber() @Min(1000) amount: number;
  @IsEnum(['transfer_bank','qris','cash','ewallet']) paymentMethod: string;
  @IsEnum(['deposit','final_payment']) paymentType: string;
  @IsOptional() @IsString() proofUrl?: string;
  // proofUrl WAJIB jika paymentMethod === 'transfer_bank', validasi di service layer
}

export class ConfirmPaymentDto {
  @IsOptional() @IsString() note?: string;
}
```

### Sparepart, Review, Dispute DTOs
```typescript
export class CreateSparepartDto {
  @IsString() @IsNotEmpty() brand: string;
  @IsString() @IsNotEmpty() deviceModel: string;
  @IsEnum(['screen_replacement','battery_replacement','charging_port','camera','other'])
  partType: string;
  @IsString() @IsNotEmpty() partName: string;
  @IsNumber() @Min(0) price: number;
  @IsNumber() @Min(0) qty: number;
  @IsOptional() @IsEnum(['available','preorder','discontinued']) status?: string;
}

export class UpdateSparepartDto {
  @IsOptional() @IsNumber() @Min(0) price?: number;
  @IsOptional() @IsNumber() @Min(0) qty?: number;
  @IsOptional() @IsEnum(['available','preorder','discontinued']) status?: string;
  @IsOptional() @IsString() partName?: string;
}

export class CreateReviewDto {
  @IsInt() @Min(1) @Max(5) rating: number;
  @IsOptional() @IsString() @MaxLength(500) comment?: string;
}

export class CreateDisputeDto {
  @IsEnum(['warranty_claim','service_quality','wrong_diagnosis','other']) disputeType: string;
  @IsString() @MinLength(20) description: string;
  @IsOptional() @IsArray() @IsString({ each: true }) evidenceUrls?: string[];
}

export class RespondDisputeDto {
  @IsEnum(['store_accepted','store_rejected']) decision: string;
  @IsString() @MinLength(10) storeResponse: string;
}

export class UpdateProfileDto {
  @IsOptional() @IsString() @MaxLength(150) fullName?: string;
  @IsOptional() @IsString() address?: string;
  @IsOptional() @IsString() avatarUrl?: string;
}
```

---

## 5. JWT Strategy — Dua Strategy Terpisah

```typescript
// src/modules/auth/strategies/jwt-access.strategy.ts
// Untuk customer login
@Injectable()
export class JwtAccessStrategy extends PassportStrategy(Strategy, 'jwt-access') {
  constructor(config: ConfigService, private prisma: PrismaService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: config.get<string>('jwt.accessSecret'),
    });
  }
  async validate(payload: JwtPayload) {
    // Validasi session masih aktif
    // (tidak perlu untuk access token — cukup verify signature)
    return { id: payload.sub, role: payload.role, isFirstLogin: payload.isFirstLogin };
  }
}

// src/modules/store-auth/strategies/store-jwt-access.strategy.ts
// Untuk store_admin login — STRATEGY TERPISAH
@Injectable()
export class StoreJwtAccessStrategy extends PassportStrategy(Strategy, 'store-jwt-access') {
  constructor(config: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: config.get<string>('jwt.storeAccessSecret'),
      // Secret BERBEDA dari customer JWT
    });
  }
  async validate(payload: JwtPayload) {
    if (!payload.storeId) throw new UnauthorizedException();
    return {
      id: payload.sub,
      role: payload.role,           // = 'store_admin'
      storeId: payload.storeId,     // ← WAJIB ada
      isFirstLogin: payload.isFirstLogin,
    };
  }
}
```

```typescript
// Guard untuk store_admin
@Injectable()
export class StoreJwtAuthGuard extends AuthGuard('store-jwt-access') {
  handleRequest(err: any, user: any): any {
    if (err || !user) throw new TokenInvalidException();
    return user;
  }
}
```

**generateTokens untuk store_admin — wajib include storeId:**
```typescript
private generateStoreTokens(adminId: string, storeId: string, isFirstLogin: boolean) {
  const payload: JwtPayload = {
    sub: adminId,
    role: 'store_admin',
    storeId,           // ← WAJIB
    isFirstLogin,
  };
  return {
    accessToken: this.jwt.sign(payload, {
      secret: this.config.get('jwt.storeAccessSecret'),
      expiresIn: '1h',
    }),
    refreshToken: this.jwt.sign(payload, {
      secret: this.config.get('jwt.storeRefreshSecret'),
      expiresIn: '30d',
    }),
  };
}
```

---

## 6. State Machine — Lengkap & Final

### Diagram
```
(new) ──► waiting_device
              │
              ▼ store: confirm diterima
         device_received
              │
              ▼ store: mulai diagnosa
           diagnosing
              │
              ▼ store: submit diagnosis
       waiting_approval ──────────────────────────────────► cancelled
              │                                         (customer reject / SLA)
              ├──► waiting_sparepart ──► repairing
              │    (store: stok habis)   (store: stok tiba)
              │
              └──► repairing  (customer approve)
                      │
                      ▼ store: selesai perbaikan
                  quality_check
                      │
                      ▼ store: QC ok
                  waiting_payment
                      │
                      ▼ store: confirm payment
                    completed
                      │
                      ▼ customer: klaim garansi
                    disputed
                      │
                      ▼ store: terima klaim
                    completed (warranty order baru dibuat)

(any active state) ──► cancelled  (SLA Monitor, kecuali waiting_approval & disputed)
```

### Validator
```typescript
// src/modules/orders/utils/state-machine.util.ts
const VALID_TRANSITIONS: Record<string, string[]> = {
  waiting_device:    ['device_received', 'cancelled'],
  device_received:   ['diagnosing', 'cancelled'],
  diagnosing:        ['waiting_approval', 'cancelled'],
  waiting_approval:  ['repairing', 'waiting_sparepart', 'cancelled'],
  waiting_sparepart: ['repairing', 'cancelled'],
  repairing:         ['quality_check', 'cancelled'],
  quality_check:     ['waiting_payment', 'cancelled'],
  waiting_payment:   ['completed', 'cancelled'],
  completed:         ['disputed'],
  cancelled:         [],
  disputed:          ['completed'],
};

export function assertValidTransition(from: string, to: string): void {
  if (!(VALID_TRANSITIONS[from] ?? []).includes(to)) {
    throw new InvalidStatusTransitionException(from, to);
  }
}
```

### Side effects per transisi — wajib dikerjakan

| Transisi | Side Effects |
|---|---|
| new → `waiting_device` | Create order+items+tracking; `qtyReserved += 1` per item; slaDeadline+24j; notif WA toko |
| `waiting_device` → `device_received` | Log tracking; reset slaDeadline+24j |
| `device_received` → `diagnosing` | Log tracking; set slaDeadline+24j |
| `diagnosing` → `waiting_approval` | Hitung finalPrice; log tracking; slaDeadline+24j; notif WA pelanggan |
| `waiting_approval` → `repairing` | `qty-=1` + `qtyReserved-=1` per confirmed item (dalam tx); log tracking; notif toko |
| `waiting_approval` → `waiting_sparepart` | Log tracking; update slaDeadline |
| `waiting_approval` → `cancelled` | `qtyReserved-=1` per item (rollback reserve); log tracking; notif |
| `waiting_sparepart` → `repairing` | `qty-=1` + `qtyReserved-=1` per item; log tracking |
| `repairing` → `quality_check` | Log tracking; notif progress pelanggan |
| `quality_check` → `waiting_payment` | Log tracking; slaDeadline+48j; notif WA pelanggan |
| `waiting_payment` → `completed` | Via payment confirm SAJA; set warrantyDays+warrantyExpiredAt dari store.config; paymentStatus=paid; totalCompleted+1; log tracking; notif pelanggan |
| `completed` → `disputed` | Buat dispute record; log tracking; slaDeadline+24j; notif toko |
| `disputed` → `completed` | Jika store_accepted: buat warranty order baru; log tracking; notif pelanggan |
| (any) → `cancelled` via SLA | Rollback qty/qtyReserved sesuai fase; penaltyPoints+1; notif |

---

## 7. Stock Management — Mekanisme qtyReserved

```
BOOKING:
  → qtyReserved += 1   (per item yang punya sparepartId)
  → qty TIDAK berubah

APPROVE (waiting_approval → repairing):
  → qty -= 1           (stok fisik berkurang)
  → qtyReserved -= 1   (reserve dilepas)

CANCEL/REJECT sebelum approve:
  → qtyReserved -= 1   (rollback reserve)
  → qty TIDAK berubah

CANCEL setelah approve (post-repairing):
  → qty += 1           (kembalikan stok fisik)
  → qtyReserved sudah 0 saat approve, tidak perlu ubah

MATCHING ENGINE filter:
  → WHERE qty - qty_reserved > 0
```

---

## 8. Order Number Generation — Anti Race Condition

**JANGAN** pakai `count()` lalu `+1` — race condition di concurrent requests.

```typescript
import { customAlphabet } from 'nanoid';
const nid = customAlphabet('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ', 6);

function generateOrderNumber(): string {
  const date = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  return `SG-${date}-${nid()}`;
}
// Contoh output: SG-20250812-A3F7K2
// @unique constraint di DB sebagai safety net
```

---

## 9. API Response Shapes — Presisi per Endpoint

### GET /v1/store/orders/:id — Response dengan Credential Panel
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "orderNumber": "SG-20250812-A3F7K2",
    "status": "waiting_device",
    "deviceType": "android",
    "brand": "Samsung",
    "deviceModel": "Galaxy S24 Ultra",
    "deliveryMethod": "walk_in",
    "deliveryAddress": null,
    "totalEstimasi": "850000.00",
    "finalPrice": null,
    "serviceFee": null,
    "diagnosisNote": null,
    "slaDeadline": "2025-08-13T10:30:00.000Z",
    "createdAt": "2025-08-12T10:30:00.000Z",
    "user": {
      "id": "uuid",
      "fullName": "Budi Santoso",
      "phoneNumber": "+628123456789"
    },
    "items": [
      {
        "id": "uuid",
        "serviceType": "screen_replacement",
        "complaint": "Layar retak dari pojok kiri bawah",
        "sparepartId": "uuid",
        "itemPrice": "800000.00",
        "finalItemPrice": null,
        "status": "pending",
        "technicianNote": null
      }
    ],
    "tracking": [
      {
        "id": "uuid",
        "status": "waiting_device",
        "note": "Order berhasil dibuat.",
        "createdByType": "customer",
        "createdAt": "2025-08-12T10:30:00.000Z"
      }
    ],
    "payments": [],
    "shipments": [],
    "credentialPanel": {
      "isNewCustomer": true,
      "isCredentialSent": false,
      "credential": {
        "phone": "+628123456789",
        "password": "022104097890",
        "expiresAt": "2025-08-13T10:30:00.000Z"
      }
    }
  }
}
```

`credentialPanel.credential` = `null` jika sudah expired atau `isCredentialSent=true`.

### POST /v1/orders — Response
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "orderNumber": "SG-20250812-A3F7K2",
    "status": "waiting_device",
    "totalEstimasi": "850000.00",
    "isNewCustomer": true,
    "message": "Order berhasil dibuat. Cek WhatsApp untuk info akun ServisGadget."
  }
}
```

### POST /v1/orders/:id/reviews — Response
```json
{
  "success": true,
  "data": {
    "review": { "id": "uuid", "rating": 5, "comment": "Mantap!" },
    "coupon": {
      "code": "RWD-1723456789-A3F7",
      "amount": "10000.00",
      "expiredAt": "2025-09-12T10:30:00.000Z"
    }
  }
}
```

### GET /v1/store/dashboard/summary — Response
```json
{
  "success": true,
  "data": {
    "activeOrders": 12,
    "byStatus": {
      "waiting_device": 2,
      "device_received": 1,
      "diagnosing": 3,
      "waiting_approval": 2,
      "waiting_sparepart": 1,
      "repairing": 2,
      "quality_check": 0,
      "waiting_payment": 1
    },
    "pendingPayments": 1,
    "openDisputes": 0,
    "ratingAvg": "4.70",
    "totalCompletedThisMonth": 34
  }
}
```

---

## 10. File Upload Flow

Upload file ke Cloudflare R2 menggunakan **presigned URL** (aman, tidak expose credentials ke client):

```
Client                    Backend               R2
  │                          │                   │
  ├── POST /v1/uploads/presign ──────────────────►│
  │   { fileName, mimeType } │                   │
  │                          │◄── presignedUrl ───┤
  │◄── { uploadUrl, fileUrl }│                   │
  │                          │                   │
  ├── PUT {uploadUrl} ────────────────────────────►
  │   (body: file binary)    │                   │
  │                          │                   │
  ├── [gunakan fileUrl sebagai proofUrl/avatarUrl/evidenceUrl]
```

**Endpoint presign:**
```typescript
// POST /v1/uploads/presign  [JWT]
// Body: { fileName: string, mimeType: string, folder: 'payments'|'evidence'|'avatars' }
// Response: { uploadUrl: string, fileUrl: string, expiresIn: 300 }
```

**Flutter implementation:**
```dart
// 1. Dapatkan presigned URL
final presign = await dio.post('/uploads/presign', data: {
  'fileName': file.name,
  'mimeType': lookupMimeType(file.path) ?? 'application/octet-stream',
  'folder': 'payments',
});
final uploadUrl = presign.data['data']['uploadUrl'] as String;
final fileUrl   = presign.data['data']['fileUrl'] as String;

// 2. Upload langsung ke R2 (tanpa Authorization header)
final uploadDio = Dio();
await uploadDio.put(
  uploadUrl,
  data: file.openRead(),
  options: Options(
    headers: {
      'Content-Type': lookupMimeType(file.path),
      'Content-Length': await file.length(),
    },
  ),
);

// 3. Gunakan fileUrl sebagai proofUrl di POST /v1/orders/:id/payments
```

---

## 11. Error Code Registry Lengkap

| Code | HTTP | Trigger |
|---|---|---|
| `INVALID_CREDENTIALS` | 401 | HP/password salah |
| `ACCOUNT_LOCKED` | 423 | 5x gagal login, lock 30 menit |
| `ACCOUNT_SUSPENDED` | 403 | accountStatus=suspended |
| `FIRST_LOGIN_REQUIRED` | 403 | isFirstLogin=true di semua endpoint kecuali change-password |
| `TOKEN_INVALID` | 401 | JWT gagal verifikasi atau session sudah tidak aktif |
| `ORDER_NOT_FOUND` | 404 | Order tidak ada atau bukan milik user/toko ini |
| `INVALID_STATUS_TRANSITION` | 422 | Transisi tidak ada di VALID_TRANSITIONS |
| `STOCK_UNAVAILABLE` | 409 | qty - qtyReserved < 1 saat reserve atau decrement |
| `COUPON_EXPIRED` | 422 | coupon.expiredAt <= now |
| `COUPON_ALREADY_USED` | 422 | coupon.isUsed = true |
| `COUPON_NOT_OWNED` | 403 | coupon.userId != user.id |
| `DISPUTE_ALREADY_ACTIVE` | 409 | Ada dispute dengan status NOT IN (resolved, closed) |
| `WARRANTY_EXPIRED` | 422 | now >= warrantyExpiredAt |
| `DUPLICATE_REVIEW` | 409 | Sudah ada review untuk order ini |
| `STORE_NOT_ACTIVE` | 422 | store.isActive = false |
| `DELIVERY_ADDRESS_REQUIRED` | 400 | deliveryMethod=courier_pickup tanpa deliveryAddress |
| `PROOF_REQUIRED` | 400 | paymentMethod=transfer_bank tanpa proofUrl |
| `PASSWORD_SAME_AS_OLD` | 400 | newPassword sama dengan passwordHash saat ini |
| `VALIDATION_ERROR` | 400 | class-validator gagal |
| `INTERNAL_ERROR` | 500 | Unexpected exception |

---

## 12. Business Rules Master (38 Rules)

| # | Rule |
|---|---|
| BR-01 | Satu order = satu toko. |
| BR-02 | Order minimal 1 item. |
| BR-03 | Status hanya maju kecuali ke `cancelled`. |
| BR-04 | `completed` dan `cancelled` = TERMINAL. |
| BR-05 | Satu review per order, hanya jika `completed`. |
| BR-06 | Matching engine: `qty - qtyReserved > 0`. |
| BR-07 | qty decrement saat approve, BUKAN saat booking. |
| BR-08 | qtyReserved increment saat booking. |
| BR-09 | Cancel pre-approve: rollback qtyReserved saja. |
| BR-10 | Cancel post-approve: rollback qty fisik. |
| BR-11 | Race condition: cek ulang dalam transaction, rollback jika gagal. |
| BR-12 | `completed` hanya via payment confirm, bukan PATCH status. |
| BR-13 | warrantyDays diambil dari store.config saat payment confirm. |
| BR-14 | warrantyExpiredAt = completedAt + warrantyDays hari. |
| BR-15 | Cancel pre-repairing: refund deposit 100%. |
| BR-16 | Cancel post-repairing: refund - diagnosis_fee. |
| BR-17 | Cancel karena SLA: refund 100% + penaltyPoints+1. |
| BR-18 | SLA = jam kalender (bukan jam kerja). |
| BR-19 | SLA warning T-6 jam. |
| BR-20 | Auto-cancel T+24j post-deadline (kecuali waiting_approval & disputed). |
| BR-21 | Klaim garansi hanya jika `completed` AND `now < warrantyExpiredAt`. |
| BR-22 | Dispute aktif = status NOT IN (resolved, closed). |
| BR-23 | Warranty order: isWarrantyOrder=true, parentOrderId, finalPrice=0. |
| BR-24 | customer hanya akses data miliknya. |
| BR-25 | store_admin hanya akses data storeId dari JWT-nya. |
| BR-26 | service_tracking IMMUTABLE. |
| BR-27 | Satu HP = satu akun (UNIQUE). |
| BR-28 | Password formula: 4 huruf depan nama (A=01..Z=26, pad 00) + 4 digit akhir HP. |
| BR-29 | credentialPlainEnc TTL 24 jam atau setelah isCredentialSent=true. |
| BR-30 | isFirstLogin=true → 403 di semua endpoint kecuali change-password. |
| BR-31 | Password baru: min 8 karakter, tidak boleh sama dengan sebelumnya. |
| BR-32 | Reset password admin → formula default + isFirstLogin=true. |
| BR-33 | Kupon hanya bisa dipakai oleh pemilik (coupon.userId == user.id). |
| BR-34 | Kupon reward Rp10.000 dibuat otomatis saat review, expired +30 hari. |
| BR-35 | ratingAvg diperbarui dengan AVG(rating) setiap review baru. |
| BR-36 | HP tidak bisa diubah via app. |
| BR-37 | WA retry 3x: 1 menit, 5 menit, 15 menit. Gagal → log ke failed_notifications. |
| BR-38 | POST /v1/orders bersifat PUBLIC (tidak butuh JWT). |

---

## 13. Stealth Account — Formula & Test Cases Wajib

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

// TEST CASES — WAJIB SEMUA PASS sebelum deploy:
// generatePassword('Budi Santoso',  '+6281234567890') === '022104097890'
// generatePassword('Ani',           '+6282198765432') === '011409005432'
// generatePassword('Muhammad',      '+6285611223344') === '132108013344'
// generatePassword('Li',            '+6281299998888') === '120900008888'
// generatePassword('ZARA',          '+6289012345678') === '260118015678'
```

---

## 14. Environment Variables Lengkap

```env
# Database
DATABASE_URL=postgresql://postgres:postgres123@localhost:5432/servisgadget

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT Customer
# Generate: node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
JWT_ACCESS_SECRET=<64-byte-hex>
JWT_REFRESH_SECRET=<64-byte-hex-berbeda>
JWT_ACCESS_EXPIRES_IN=1h
JWT_REFRESH_EXPIRES_IN=30d

# JWT Store Admin — SECRET HARUS BERBEDA dari customer
JWT_STORE_ACCESS_SECRET=<64-byte-hex-ketiga>
JWT_STORE_REFRESH_SECRET=<64-byte-hex-keempat>

# Encryption credential
# Generate: node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
CREDENTIAL_ENCRYPTION_KEY=<32-byte-hex>

# WhatsApp Fonnte
WA_GATEWAY_URL=https://api.fonnte.com/send
WA_GATEWAY_TOKEN=<token-dari-fonnte-dashboard>
WA_SENDER_NUMBER=628XXXXXXXXXX

# Cloudflare R2
STORAGE_ENDPOINT=https://<account-id>.r2.cloudflarestorage.com
STORAGE_ACCESS_KEY=<r2-access-key>
STORAGE_SECRET_KEY=<r2-secret-key>
STORAGE_BUCKET=servisgadget-prod
STORAGE_PUBLIC_URL=https://files.servisgadget.id

# App
APP_URL=https://app.servisgadget.id
NODE_ENV=development
PORT=3000

# SLA (menit)
SLA_RECEIVE_DEVICE_MINUTES=1440
SLA_DIAGNOSIS_MINUTES=1440
SLA_APPROVAL_MINUTES=1440
SLA_PAYMENT_MINUTES=2880
SLA_CREDENTIAL_CLEAR_MINUTES=1440
SLA_DISPUTE_RESPOND_MINUTES=1440

# Rate limit
THROTTLE_TTL_SECONDS=60
THROTTLE_LIMIT=100
```

---

## 15. Acceptance Criteria — 30 Test Wajib

Jangan merge ke `main` jika ada satu pun yang fail.

### Auth
- [ ] AC-01 Customer login benar → 200 + `is_first_login`
- [ ] AC-02 Customer login salah 5x → 423 + lockedUntil ada di DB
- [ ] AC-03 Store admin login → 200 + JWT berisi `storeId`
- [ ] AC-04 Store admin token di endpoint customer → 403
- [ ] AC-05 Customer token di endpoint store_admin → 403
- [ ] AC-06 `change-password` sukses → isFirstLogin=false, semua sesi invalid
- [ ] AC-07 `GET /v1/me` saat isFirstLogin=true → 403 FIRST_LOGIN_REQUIRED

### Booking & Stock
- [ ] AC-08 `POST /v1/orders` tanpa JWT (pelanggan baru) → 201, user baru di DB, credentialPlainEnc terenkripsi, qtyReserved+1
- [ ] AC-09 `POST /v1/orders` nomor HP yang sudah ada → order linked ke akun lama, TIDAK buat user baru
- [ ] AC-10 `POST /v1/orders` stok qty-qtyReserved=0 → 409 STOCK_UNAVAILABLE
- [ ] AC-11 `itemPrice` di order_items = sparepart.price, bukan 0
- [ ] AC-12 `POST /v1/orders/:id/approve` → qty-=1 + qtyReserved-=1 per item, status=repairing
- [ ] AC-13 `POST /v1/orders/:id/reject` → qtyReserved-=1, qty TIDAK berubah, status=cancelled
- [ ] AC-14 Race condition: 2 approve bersamaan saat qty=1 → 1 sukses, 1 rollback 409

### Diagnosis
- [ ] AC-15 `PATCH /v1/store/orders/:id/diagnosis` → finalPrice = SUM(confirmed/replaced items) + serviceFee, status=waiting_approval
- [ ] AC-16 DiagnosisItemDto status=replaced tanpa replacedSparepartId → 400
- [ ] AC-17 `PATCH /v1/store/orders/:id/status` status=completed → 400 INVALID_STATUS_TRANSITION (tidak bisa langsung completed)

### Payment & Completion
- [ ] AC-18 Confirm payment → status=completed, warrantyDays dari store.config, warrantyExpiredAt = completedAt + warrantyDays
- [ ] AC-19 totalCompleted toko +1 setelah payment confirm

### Reviews & Coupons
- [ ] AC-20 Review berhasil → ratingAvg toko ter-update, kupon Rp10.000 dibuat (expired +30 hari)
- [ ] AC-21 Review kedua untuk order sama → 409 DUPLICATE_REVIEW

### Disputes
- [ ] AC-22 Dispute dalam garansi → dispute dibuat, order=disputed, slaDeadline+24j, notif WA toko
- [ ] AC-23 Dispute setelah warrantyExpiredAt → 422 WARRANTY_EXPIRED
- [ ] AC-24 Dispute saat ada dispute aktif → 409 DISPUTE_ALREADY_ACTIVE
- [ ] AC-25 Respond store_accepted → warranty order baru (finalPrice=0, isWarrantyOrder=true)

### Credential System
- [ ] AC-26 `GET /v1/store/orders/:id` pelanggan baru (<24j) → credentialPanel.credential.password ada
- [ ] AC-27 `mark-sent` → isCredentialSent=true, credentialPlainEnc=null di DB
- [ ] AC-28 Credential cleaner cron → credentialPlainEnc=null otomatis setelah TTL

### SLA & Jobs
- [ ] AC-29 SLA Monitor: auto-cancel order overdue → penaltyPoints+1, qty rollback benar
- [ ] AC-30 SLA Monitor: warning T-6j → slaWarnedAt ter-set, tidak kirim warning dua kali

---

*ServisGadget Master PRD v3.0 — Revised & Completed*
