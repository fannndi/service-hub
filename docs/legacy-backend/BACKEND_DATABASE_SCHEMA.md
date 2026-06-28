# Backend Database Schema

> **ORM:** Prisma 5.x | **Database:** PostgreSQL 16 | **Schema:** `backend/prisma/schema.prisma`

---

## Table of Contents

1. [Enums](#1-enums)
2. [Models](#2-models)
3. [Relationships](#3-relationships)
4. [Indexes](#4-indexes)

---

## 1. Enums

### AccountStatus
```prisma
enum AccountStatus {
  active
  suspended
  deleted
}
```
Digunakan di `User.accountStatus`. Default: `active`.

### DeviceType
```prisma
enum DeviceType {
  android
  ios
}
```
Digunakan di `ServiceOrder.deviceType`.

### DeliveryMethod
```prisma
enum DeliveryMethod {
  walk_in
  courier_pickup
}
```
- `walk_in`: Customer datang ke toko
- `courier_pickup`: Kurir jemput barang (wajib isi `deliveryAddress`)

### OrderStatus
```prisma
enum OrderStatus {
  waiting_device      # Awal, menunggu customer serahkan device
  device_received     # Device sudah diterima toko
  diagnosing          # Sedang diagnosis
  waiting_approval    # Menunggu customer setujui diagnosis
  waiting_sparepart   # Menunggu sparepart
  repairing           # Sedang diperbaiki
  quality_check       # QC sebelum final
  waiting_payment     # Menunggu pembayaran
  completed           # Selesai
  cancelled           # Dibatalkan
  disputed            # Ada klaim garansi
}
```

### PaymentStatus
```prisma
enum PaymentStatus {
  unpaid            # Belum bayar
  partially_paid    # Bayar sebagian
  paid              # Lunas
  refunded          # Uang dikembalikan
}
```
Digunakan di `ServiceOrder.paymentStatus`.

### PaymentMethod
```prisma
enum PaymentMethod {
  transfer_bank
  qris
  cash
  ewallet
}
```

### PaymentType
```prisma
enum PaymentType {
  deposit          # Uang muka
  final_payment    # Pelunasan
  refund           # Pengembalian dana
}
```

### PaymentRecordStatus
```prisma
enum PaymentRecordStatus {
  pending     # Menunggu konfirmasi
  confirmed   # Dikonfirmasi
  failed      # Gagal
  refunded    # Dikembalikan
}
```
Digunakan di `Payment.status`.

### SparePartStatus
```prisma
enum SparePartStatus {
  available       # Tersedia
  preorder        # Pre-order
  discontinued    # Tidak diproduksi lagi
}
```

### OrderItemStatus
```prisma
enum OrderItemStatus {
  pending     # Belum diproses
  confirmed   # Dikonfirmasi teknisi
  replaced    # Sudah diganti
  cancelled   # Dibatalkan
}
```

### ShipmentType
```prisma
enum ShipmentType {
  pickup              # Penjemputan
  return              # Pengembalian
  warranty_pickup     # Penjemputan garansi
}
```

### ShipmentStatus
```prisma
enum ShipmentStatus {
  scheduled
  picked_up
  in_transit
  delivered
  failed
}
```

### DisputeType
```prisma
enum DisputeType {
  warranty_claim      # Klaim garansi
  service_quality     # Kualitas service
  wrong_diagnosis     # Diagnosis salah
  other               # Lainnya
}
```

### DisputeStatus
```prisma
enum DisputeStatus {
  open              # Baru dibuat
  store_accepted    # Toko terima → buat warranty order
  store_rejected    # Toko tolak
  escalated         # Escalated ke platform
  resolved          # Selesai
  closed            # Ditutup
}
```

### CreatedByType
```prisma
enum CreatedByType {
  customer
  store_admin
  system
}
```
Digunakan di `ServiceTracking.createdByType`.

### ApplicationStatus
```prisma
enum ApplicationStatus {
  pending
  approved
  rejected
}
```
Digunakan di `StoreApplication.status`.

### FeeBearerType
```prisma
enum FeeBearerType {
  customer
  store
  platform
}
```
Digunakan di `Shipment.feeBearer`.

---

## 2. Models

### User (Customer)
```prisma
model User {
  id                 String         @id @default(uuid())
  fullName           String         @db.VarChar(150)
  phoneNumber        String         @unique @db.VarChar(20)
  passwordHash       String         @db.VarChar(255)
  avatarUrl          String?        @db.VarChar(255)
  address            String?        @db.Text
  accountStatus      AccountStatus  @default(active)
  isFirstLogin       Boolean        @default(true)
  isCredentialSent   Boolean        @default(false)
  credentialPlainEnc String?        @db.Text
  loginAttemptCount  Int            @default(0) @db.SmallInt
  lockedUntil        DateTime?      @db.Timestamptz
  lastLoginAt        DateTime?      @db.Timestamptz
  passwordChangedAt  DateTime?      @db.Timestamptz
  createdAt          DateTime       @default(now()) @db.Timestamptz
  updatedAt          DateTime       @updatedAt @db.Timestamptz
}
```

**Key Fields:**
- `phoneNumber`: Normalized format `0xxx`, unique
- `isFirstLogin`: `true` → wajib ganti password setelah login pertama
- `isCredentialSent`: `true` → credential sudah dikirim via WhatsApp
- `credentialPlainEnc`: Password plain text terenkripsi (AES-256-GCM), dihapus setelah 24 jam
- `loginAttemptCount`: Counter untuk brute-force protection, reset setelah 5x → lock 30 menit
- `lockedUntil`: Timestamp kunci akun

### StoreAdmin
```prisma
model StoreAdmin {
  id           String    @id @default(uuid())
  storeId      String
  fullName     String    @db.VarChar(150)
  phoneNumber  String    @db.VarChar(20)
  passwordHash String    @db.VarChar(255)
  isActive     Boolean   @default(true)
  isFirstLogin Boolean   @default(false)
  lastLoginAt  DateTime? @db.Timestamptz
  createdAt    DateTime  @default(now()) @db.Timestamptz
}
```

**Unique:** `@@unique([storeId, phoneNumber])` — phone harus unik per store.

### Store
```prisma
model Store {
  id               String          @id @default(uuid())
  storeName        String          @db.VarChar(150)
  address          String          @db.Text
  phoneNumber      String          @db.VarChar(20)
  operationalHours Json            @default("{}")
  config           Json            @default("{}")
  isActive         Boolean         @default(false)
  ratingAvg        Decimal         @default(0) @db.Decimal(3, 2)
  totalCompleted   Int             @default(0)
  penaltyPoints    Int             @default(0)
  verifiedAt       DateTime?       @db.Timestamptz
  createdAt        DateTime        @default(now()) @db.Timestamptz
  updatedAt        DateTime        @updatedAt @db.Timestamptz
}
```

**Key Fields:**
- `operationalHours`: JSON object `{ "mon": { "open": "09:00", "close": "17:00" }, ... }`
- `config`: JSON configuration (flexible, bisa ditambah field apapun)
- `isActive`: `false` sampai diverifikasi platform admin
- `ratingAvg`: Rata-rata rating (3 digit, 2 decimal) — di-update otomatis saat review
- `totalCompleted`: Counter order selesai — di-update otomatis saat payment confirmed
- `penaltyPoints`: Poin pelanggaran (untuk ranking/penalty)

### StoreApplication
```prisma
model StoreApplication {
  id                 String            @id @default(uuid())
  storeName          String            @db.VarChar(150)
  applicantName      String            @db.VarChar(150)
  phoneNumber        String            @db.VarChar(20)
  address            String            @db.Text
  businessLicenseUrl String?           @db.VarChar(255)
  idCardUrl          String            @db.VarChar(255)
  status             ApplicationStatus @default(pending)
  reviewedBy         String?
  reviewNote         String?           @db.Text
  appliedAt          DateTime          @default(now()) @db.Timestamptz
  reviewedAt         DateTime?         @db.Timestamptz
}
```

### SparePart
```prisma
model SparePart {
  id          String          @id @default(uuid())
  storeId     String
  brand       String          @db.VarChar(80)
  deviceModel String          @db.VarChar(100)
  partType    String          @db.VarChar(60)
  partName    String          @db.VarChar(150)
  price       Decimal         @db.Decimal(12, 2)
  qty         Int             @default(0)
  qtyReserved Int             @default(0)
  status      SparePartStatus @default(available)
  createdAt   DateTime        @default(now()) @db.Timestamptz
  updatedAt   DateTime        @updatedAt @db.Timestamptz
}
```

**Key Fields:**
- `qty`: Total stok
- `qtyReserved`: Stok yang di-reserve untuk order pending
- `available` = `qty - qtyReserved` (computed field)
- `status`: `available`, `preorder`, `discontinued`

**Indexes:** `@@index([storeId])`, `@@index([brand, deviceModel, partType])`

### ServiceOrder
```prisma
model ServiceOrder {
  id                String        @id @default(uuid())
  userId            String
  storeId           String
  orderNumber       String        @unique @db.VarChar(30)
  deviceType        DeviceType
  brand             String        @db.VarChar(80)
  deviceModel       String        @db.VarChar(100)
  deliveryMethod    DeliveryMethod
  deliveryAddress   String?       @db.Text
  status            OrderStatus   @default(waiting_device)
  paymentStatus     PaymentStatus @default(unpaid)
  totalEstimasi     Decimal       @default(0) @db.Decimal(12, 2)
  discountAmount    Decimal       @default(0) @db.Decimal(12, 2)
  finalPrice        Decimal?      @db.Decimal(12, 2)
  serviceFee        Decimal?      @db.Decimal(12, 2)
  diagnosisNote     String?       @db.Text
  warrantyDays      Int?
  warrantyExpiredAt DateTime?     @db.Timestamptz
  slaDeadline       DateTime?     @db.Timestamptz
  slaWarnedAt       DateTime?     @db.Timestamptz
  slaBreachCount    Int           @default(0) @db.SmallInt
  couponId          String?       @unique
  isWarrantyOrder   Boolean       @default(false)
  parentOrderId     String?
  completedAt       DateTime?     @db.Timestamptz
  cancelledAt       DateTime?     @db.Timestamptz
  createdAt         DateTime      @default(now()) @db.Timestamptz
  updatedAt         DateTime      @updatedAt @db.Timestamptz
}
```

**Key Fields:**
- `orderNumber`: Format `SG-{YYYYMMDD}-{random 6 digit}` — unique
- `totalEstimasi`: Total estimasi harga dari teknisi
- `discountAmount`: Diskon dari coupon
- `finalPrice`: Harga final (totalEstimasi - discount + serviceFee)
- `slaDeadline`: Deadline SLA untuk status saat ini
- `isWarrantyOrder`: `true` jika order ini dari warranty claim
- `parentOrderId`: ID order asli (jika warranty order)

**Indexes:** `@@index([userId])`, `@@index([storeId])`, `@@index([status])`

### OrderItem
```prisma
model OrderItem {
  id             String          @id @default(uuid())
  orderId        String
  sparepartId    String?
  serviceType    String          @db.VarChar(100)
  complaint      String          @db.Text
  itemPrice      Decimal         @db.Decimal(12, 2)
  finalItemPrice Decimal?        @db.Decimal(12, 2)
  status         OrderItemStatus @default(pending)
  technicianNote String?         @db.Text
}
```

**Key Fields:**
- `sparepartId`: Nullable — jika tidak perlu sparepart
- `itemPrice`: Harga estimasi
- `finalItemPrice`: Harga final dari diagnosis
- `technicianNote`: Catatan teknisi

### ServiceTracking
```prisma
model ServiceTracking {
  id            String        @id @default(uuid())
  orderId       String
  status        OrderStatus
  note          String?       @db.Text
  createdByType CreatedByType
  createdById   String
  createdAt     DateTime      @default(now()) @db.Timestamptz
}
```

**Key Fields:**
- Setiap perubahan status order membuat 1 record di sini
- `createdByType`: Siapa yang ubah (customer/system/store_admin)
- `createdById`: ID entity yang ubah (user_id/system/store_admin_id)

### Payment
```prisma
model Payment {
  id            String              @id @default(uuid())
  orderId       String
  userId        String
  amount        Decimal             @db.Decimal(12, 2)
  paymentMethod PaymentMethod
  paymentType   PaymentType
  status        PaymentRecordStatus @default(pending)
  proofUrl      String?             @db.VarChar(255)
  confirmedBy   String?
  confirmedAt   DateTime?           @db.Timestamptz
  createdAt     DateTime            @default(now()) @db.Timestamptz
}
```

### Shipment
```prisma
model Shipment {
  id                 String         @id @default(uuid())
  orderId            String
  shipmentType       ShipmentType
  courierName        String?        @db.VarChar(80)
  trackingNumber     String?        @unique @db.VarChar(100)
  pickupAddress      String         @db.Text
  destinationAddress String         @db.Text
  status             ShipmentStatus @default(scheduled)
  scheduledAt        DateTime?      @db.Timestamptz
  deliveredAt        DateTime?      @db.Timestamptz
  shippingFee        Decimal        @default(0) @db.Decimal(12, 2)
  feeBearer          FeeBearerType  @default(customer)
  notes              String?        @db.Text
  createdAt          DateTime       @default(now()) @db.Timestamptz
}
```

### Review
```prisma
model Review {
  id        String       @id @default(uuid())
  orderId   String       @unique
  userId    String
  storeId   String
  rating    Int          @db.SmallInt
  comment   String?      @db.Text
  isPublic  Boolean      @default(true)
  createdAt DateTime     @default(now()) @db.Timestamptz
}
```

**Unique:** 1 review per order (`@@unique` di `orderId`).

### Coupon
```prisma
model Coupon {
  id            String        @id @default(uuid())
  userId        String
  reviewId      String        @unique
  code          String        @unique @db.VarChar(20)
  amount        Decimal       @default(10000) @db.Decimal(12, 2)
  isUsed        Boolean       @default(false)
  usedAt        DateTime?     @db.Timestamptz
  usedOnOrderId String?       @unique
  expiredAt     DateTime
  createdAt     DateTime      @default(now()) @db.Timestamptz
}
```

**Key Fields:**
- `code`: Format `RWD-XXXX` (random 4 karakter)
- `amount`: Default Rp 10.000 (reward dari review)
- `isUsed`: `true` setelah dipakai di order
- `expiredAt`: 30 hari dari pembuatan
- `reviewId`: 1 coupon per review

### Dispute
```prisma
model Dispute {
  id               String        @id @default(uuid())
  orderId          String        @unique
  userId           String
  storeId          String
  disputeType      DisputeType
  description      String        @db.Text
  evidenceUrls     Json          @default("[]")
  status           DisputeStatus @default(open)
  storeResponse    String?       @db.Text
  platformDecision String?       @db.Text
  resolution       String?       @db.Text
  warrantyOrderId  String?
  resolvedAt       DateTime?     @db.Timestamptz
  slaDeadline      DateTime?     @db.Timestamptz
  createdAt        DateTime      @default(now()) @db.Timestamptz
}
```

**Key Fields:**
- `evidenceUrls`: JSON array of image URLs
- `warrantyOrderId`: ID order warranty jika dispute diterima
- `slaDeadline`: 24 jam dari pembuatan

### UserSession
```prisma
model UserSession {
  id           String   @id @default(uuid())
  userId       String
  tokenHash    String   @unique @db.VarChar(64)
  deviceInfo   Json?
  ipAddress    String?  @db.VarChar(45)
  isActive     Boolean  @default(true)
  expiresAt    DateTime @db.Timestamptz
  lastActiveAt DateTime @default(now()) @db.Timestamptz
  createdAt    DateTime @default(now()) @db.Timestamptz
}
```

**Key Fields:**
- `tokenHash`: SHA-256 hash dari refresh token (bukan raw token)
- `expiresAt`: 30 hari dari pembuatan
- `isActive`: `false` = session sudah di-logout

**Index:** `@@index([userId, isActive])`

### FailedNotification
```prisma
model FailedNotification {
  id            String   @id @default(uuid())
  recipientType String   @db.VarChar(20)
  recipientId   String
  channel       String   @default("whatsapp") @db.VarChar(20)
  messageType   String   @db.VarChar(50)
  payload       Json
  attemptCount  Int      @default(0) @db.SmallInt
  lastError     String?  @db.Text
  createdAt     DateTime @default(now()) @db.Timestamptz
}
```

### PlatformAdmin
```prisma
model PlatformAdmin {
  id           String    @id @default(uuid())
  username     String    @unique @db.VarChar(50)
  passwordHash String    @db.VarChar(255)
  fullName     String    @db.VarChar(150)
  isActive     Boolean   @default(true)
  lastLoginAt  DateTime? @db.Timestamptz
  createdAt    DateTime  @default(now()) @db.Timestamptz
}
```

---

## 3. Relationships

```
User ──< ServiceOrder        (1 user → many orders)
User ──< Payment             (1 user → many payments)
User ──< Review              (1 user → many reviews)
User ──< Coupon              (1 user → many coupons)
User ──< Dispute             (1 user → many disputes)
User ──< UserSession         (1 user → many sessions, onDelete: Cascade)

Store ──< StoreAdmin         (1 store → many admins)
Store ──< SparePart          (1 store → many spareparts)
Store ──< ServiceOrder       (1 store → many orders)
Store ──< Review             (1 store → many reviews)
Store ──< Dispute            (1 store → many disputes)

ServiceOrder ──< OrderItem   (1 order → many items, onDelete: Cascade)
ServiceOrder ──< ServiceTracking (1 order → many tracking)
ServiceOrder ──< Payment     (1 order → many payments)
ServiceOrder ──< Shipment    (1 order → many shipments)
ServiceOrder ── Review       (1 order → 1 review, optional)
ServiceOrder ── Dispute      (1 order → 1 dispute, optional)
ServiceOrder ── Coupon       (order uses coupon, optional)

OrderItem ──> SparePart      (item uses sparepart, optional)
```

---

## 4. Indexes

| Table | Index | Purpose |
|-------|-------|---------|
| `spareparts` | `[storeId]` | Query sparepart by store |
| `spareparts` | `[brand, deviceModel, partType]` | Search spareparts |
| `service_orders` | `[userId]` | Query order by customer |
| `service_orders` | `[storeId]` | Query order by store |
| `service_orders` | `[status]` | Filter by status |
| `user_sessions` | `[userId, isActive]` | Find active sessions |
| `coupons` | `code` (unique) | Lookup coupon by code |
| `coupons` | `orderId` (unique) | 1 coupon per order |
