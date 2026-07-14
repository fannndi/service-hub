# ServisGadget — 00 Master PRD
## Single Source of Truth · v3.1

> **Cara pakai untuk AI agent:** Baca file ini dulu sebelum file fase manapun.
> Semua keputusan sudah final. Jangan improvise — jika tidak ada di sini, tanya dulu.
>
> **Perubahan v3.1 (2026-06-17):**
> - Tambahan Platform Admin sebagai aktor ketiga
> - Update tech stack (npm packages yang ter-install)
> - Update 30 acceptance criteria dengan test evidence
> - Security fixes documented (IDOR, stock guard, rate limiting, store isActive)

---

## 1. Gambaran Sistem

Platform marketplace dua sisi. Pelanggan tidak pernah diminta mendaftar (stealth account). Admin toko menerima order, diagnosa, dan konfirmasi pembayaran via mobile app.

### Tiga Aktor

| Aktor | Tabel | Auth Method | JWT `role` |
|------|-------|------------|------------|
| Pelanggan | `users` | Supabase Auth (magic link/OTP) | `customer` |
| Admin Toko | `store_admins` | Supabase Auth + RLS | `store_admin` |
| Admin Platform | `platform_admins` | Supabase Auth + RLS | `platform_admin` |

> ⚠️ TIGA ENTITAS AUTH TERPISAH. `store_admin` bukan `user`. `platform_admin` punya tabel sendiri. Auth via Supabase Auth dengan role-based RLS.

---

## 2. Tech Stack — Versi Exact, Tidak Ada Alternatif

### Backend (100% Serverless via Supabase)
```
Supabase          Managed PostgreSQL + Auth + Storage + Edge Functions
Edge Functions    Deno (TypeScript) — 11 functions
PostgreSQL        15.x
Supabase Auth     Built-in (email/OTP, magic link)
Supabase Storage  File uploads (payment proofs, avatars, id cards)
```

### Flutter (pubspec.yaml — dependencies aktual)
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  go_router: ^14.8.1
  supabase_flutter: ^2.8.1
  image_picker: ^1.1.2
  cached_network_image: ^3.3.1
  intl: ^0.20.0
  shared_preferences: ^2.3.0
  google_fonts: ^6.2.1
  url_launcher: ^6.3.1
  m3_expressive: ^1.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  flutter_launcher_icons: ^0.14.3
```

> **Catatan:** freezed, json_serializable, riverpod_generator tidak digunakan.
> Code generation di-replace dengan manual JSON helpers (`json_helpers.dart`).

---

## 3. Database Schema — Migrasi SQL

Schema diimplementasikan via 21+ migrasi SQL di `supabase/migrations/`. Tidak pakai Prisma — langsung SQL mentah.

### Tabel Utama (12 tables)

| Table | Purpose |
|-------|---------|
| `users` | Pelanggan (stealth account) |
| `store_admins` | Admin toko |
| `platform_admins` | Admin platform |
| `stores` | Data toko + konfigurasi |
| `store_applications` | Pendaftaran toko baru |
| `spareparts` | Inventaris sparepart per toko |
| `service_orders` | Order service |
| `order_items` | Item dalam order |
| `service_tracking` | Riwayat status (IMMUTABLE) |
| `payments` | Riwayat pembayaran |
| `shipments` | Data pengiriman |
| `reviews` | Review + rating |
| `coupons` | Kupon reward review |
| `disputes` | Klaim garansi/sengketa |
| `user_sessions` | Session tracking |
| `failed_notifications` | Log notifikasi gagal |

### CHECK constraints (wajib ada)
```sql
ALTER TABLE spareparts ADD CONSTRAINT spareparts_qty_nonneg CHECK (qty >= 0);
ALTER TABLE spareparts ADD CONSTRAINT spareparts_qty_reserved_nonneg CHECK (qty_reserved >= 0);
ALTER TABLE reviews ADD CONSTRAINT reviews_rating_range CHECK (rating BETWEEN 1 AND 5);
```

> Lengkap: lihat `supabase/migrations/`.

---

## 4. API Contracts — Edge Function Actions

Validation ada di masing-masing Edge Function (`supabase/functions/*/index.ts`). Format request/response mengikuti pola:

```typescript
// Request: JSON body dengan field 'action' + payload
// Response: { success: true, data: {...} } | { success: false, error: { code, message } }
```

| Function | Auth | Actions |
|----------|------|---------|
| `guest` | None | `create-order`, `track`, `credentials` |
| `orders` | User JWT | `orders`, `approve`, `reject`, `diagnosis`, `status` |
| `payments` | User JWT | `create`, `confirm` |
| `midtrans` | None | `snap-token`, `notification` |
| `notifications` | User JWT | CRUD notifikasi in-app |
| `disputes` | User JWT | `create`, `respond` |
| `reviews` | User JWT | `create`, `store-list` |
| `admin` | User JWT | CRUD store, manage users |
| `store-applications` | None | Pendaftaran toko |
| `cron-sla` | None | Auto-cancel SLA |

### Normalize Phone (Edge Functions shared helper)
```typescript
export function normalizePhone(phone: string): string {
  const d = phone.replace(/\D/g, '');
  if (d.startsWith('62')) return `+${d}`;
  if (d.startsWith('0'))  return `+62${d.slice(1)}`;
  return `+62${d}`;
}
```

---

## 5. Auth — Supabase Auth + RLS

Auth di-handle oleh Supabase Auth. Tidak ada JWT strategy manual.

- **Customer**: login via Supabase Auth (email link atau OTP). Password formula stealth account di BR-28.
- **Store Admin**: login via Supabase Auth dengan `store_admin` metadata.
- **Platform Admin**: login via Supabase Auth dengan `platform_admin` metadata.

RLS (Row Level Security) di setiap tabel:
- Customer hanya bisa akses data miliknya (user_id = auth.uid())
- Store admin hanya bisa akses data storeId dari JWT-nya
- Platform admin akses semua

Detail: lihat `supabase/migrations/002_rls.sql`.

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

Upload file via **Supabase Storage** (bucket `uploads`). Tidak perlu presigned URL — langsung upload via Supabase SDK.

```
Flutter → supabase.storage.from('uploads').upload(path, file)
        → supabase.storage.from('uploads').getPublicUrl(path)
```

**Flutter implementation:**
```dart
// Upload langsung ke Supabase Storage
final path = '${folder}/${userId}/${filename}';
await sb.client.storage.from('uploads').upload(path, File(file.path));

// Dapatkan public URL
final url = sb.client.storage.from('uploads').getPublicUrl(path);
// Gunakan sebagai proofUrl / avatarUrl / evidenceUrl
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

## 14. Environment Variables — Supabase Edge Functions

Setiap variable di-set via `supabase secrets set` (bukan `.env`).

```bash
# Midtrans
MIDTRANS_SNAP_URL=https://app.sandbox.midtrans.com/snap/v1/transactions
MIDTRANS_SERVER_KEY=<midtrans-server-key>

# Email (via Resend.com)
RESEND_API_KEY=re_xxxxxxxxxx
EMAIL_FROM=Service Me <noreply@serviceme.app>

# Encryption credential
CREDENTIAL_ENCRYPTION_KEY=<32-byte-hex>

# Supabase (otomatis dari dashboard)
SUPABASE_URL=https://eboplbemgtvmviwhdlfa.supabase.co
SUPABASE_ANON_KEY=<anon-key>
SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
```

### Flutter .env (build-time)
```env
SUPABASE_URL=https://eboplbemgtvmviwhdlfa.supabase.co
SUPABASE_ANON_KEY=<anon-key>
```

### SLA (menit) — dikonfigurasi dalam Edge Function
| Parameter | Default | Description |
|-----------|---------|-------------|
| SLA_RECEIVE_DEVICE | 1440 | 24 jam |
| SLA_DIAGNOSIS | 1440 | 24 jam |
| SLA_APPROVAL | 1440 | 24 jam |
| SLA_PAYMENT | 2880 | 48 jam |
| SLA_CREDENTIAL_CLEAR | 1440 | 24 jam |
| SLA_DISPUTE_RESPOND | 1440 | 24 jam |

---

## 15. Acceptance Criteria — 30 Test Wajib ✅

> **Status: 30/30 ACs VERIFIED — 175 tests, 17 suites**
> **Evidence:** `docs/testing/phase2-integration-ac30.tdd.md`

### Auth
- [x] AC-01 Customer login benar → 200 + `is_first_login`
- [x] AC-02 Customer login salah 5x → 423 + lockedUntil ada di DB
- [x] AC-03 Store admin login → 200 + JWT berisi `storeId`
- [x] AC-04 Store admin token di endpoint customer → 403
- [x] AC-05 Customer token di endpoint store_admin → 403
- [x] AC-06 `change-password` sukses → isFirstLogin=false, semua sesi invalid
- [x] AC-07 `GET /v1/me` saat isFirstLogin=true → 403 FIRST_LOGIN_REQUIRED

### Booking & Stock
- [x] AC-08 `POST /v1/orders` tanpa JWT (pelanggan baru) → 201, user baru di DB, credentialPlainEnc terenkripsi, qtyReserved+1
- [x] AC-09 `POST /v1/orders` nomor HP yang sudah ada → order linked ke akun lama, TIDAK buat user baru
- [x] AC-10 `POST /v1/orders` stok qty-qtyReserved=0 → 409 STOCK_UNAVAILABLE
- [x] AC-11 `itemPrice` di order_items = sparepart.price, bukan 0
- [x] AC-12 `POST /v1/orders/:id/approve` → qty-=1 + qtyReserved-=1 per item, status=repairing
- [x] AC-13 `POST /v1/orders/:id/reject` → qtyReserved-=1, qty TIDAK berubah, status=cancelled
- [x] AC-14 Race condition: 2 approve bersamaan saat qty=1 → 1 sukses, 1 rollback 409

### Diagnosis
- [x] AC-15 `PATCH /v1/store/orders/:id/diagnosis` → finalPrice = SUM(confirmed/replaced items) + serviceFee, status=waiting_approval
- [x] AC-16 DiagnosisItemDto status=replaced tanpa replacedSparepartId → 400
- [x] AC-17 `PATCH /v1/store/orders/:id/status` status=completed → 400 INVALID_STATUS_TRANSITION (tidak bisa langsung completed)

### Payment & Completion
- [x] AC-18 Confirm payment → status=completed, warrantyDays dari store.config, warrantyExpiredAt = completedAt + warrantyDays
- [x] AC-19 totalCompleted toko +1 setelah payment confirm

### Reviews & Coupons
- [x] AC-20 Review berhasil → ratingAvg toko ter-update, kupon Rp10.000 dibuat (expired +30 hari)
- [x] AC-21 Review kedua untuk order sama → 409 DUPLICATE_REVIEW

### Disputes
- [x] AC-22 Dispute dalam garansi → dispute dibuat, order=disputed, slaDeadline+24j, notif WA toko
- [x] AC-23 Dispute setelah warrantyExpiredAt → 422 WARRANTY_EXPIRED
- [x] AC-24 Dispute saat ada dispute aktif → 409 DISPUTE_ALREADY_ACTIVE
- [x] AC-25 Respond store_accepted → warranty order baru (finalPrice=0, isWarrantyOrder=true)

### Credential System
- [x] AC-26 `GET /v1/store/orders/:id` pelanggan baru (<24j) → credentialPanel.credential.password ada
- [x] AC-27 `mark-sent` → isCredentialSent=true, credentialPlainEnc=null di DB
- [x] AC-28 Credential cleaner cron → credentialPlainEnc=null otomatis setelah TTL

### SLA & Jobs
- [x] AC-29 SLA Monitor: auto-cancel order overdue → penaltyPoints+1, qty rollback benar
- [x] AC-30 SLA Monitor: warning T-6j → slaWarnedAt ter-set, tidak kirim warning dua kali

---

*ServisGadget Master PRD v3.1 — Security Audited & Fully Tested*
