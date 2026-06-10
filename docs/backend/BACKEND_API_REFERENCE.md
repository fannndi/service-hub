# Backend API Reference

> **Base URL:** `http://localhost:3000/v1`
> **Swagger:** `http://localhost:3000/docs`
> **Framework:** NestJS 10.x | **Language:** TypeScript

Semua response dibungkus dalam format:
```json
{
  "success": true,
  "data": { ... },
  "timestamp": "2026-06-10T11:00:00.000Z"
}
```

Error response:
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "English message",
    "user_message": "Pesan dalam Bahasa Indonesia",
    "details": {}
  },
  "timestamp": "2026-06-10T11:00:00.000Z"
}
```

---

## Table of Contents

1. [Health](#1-health)
2. [Customer Auth](#2-customer-auth)
3. [Customer Profile (/me)](#3-customer-profile-me)
4. [Stores (Public)](#4-stores-public)
5. [Orders (Customer)](#5-orders-customer)
6. [Payments (Customer)](#6-payments-customer)
7. [Reviews (Customer)](#7-reviews-customer)
8. [Disputes (Customer)](#8-disputes-customer)
9. [Store Auth](#9-store-auth)
10. [Store Dashboard](#10-store-dashboard)
11. [Store Orders](#11-store-orders)
12. [Store Spareparts](#12-store-spareparts)
13. [Platform Admin](#13-platform-admin)
14. [Uploads](#14-uploads)
15. [Notifications](#15-notifications)
16. [Background Jobs](#16-background-jobs)

---

## 1. Health

### `GET /health`
- **Auth:** Tidak perlu
- **Response:**
```json
{ "status": "ok", "service": "servisgadget-foundation" }
```

---

## 2. Customer Auth

### `POST /auth/login`
- **Auth:** Tidak perlu
- **Body:**
  | Field | Type | Required | Notes |
  |-------|------|----------|-------|
  | `phoneNumber` | string | Ya | Normalized otomatis (0xxx) |
  | `password` | string | Ya | |

- **Response:**
```json
{
  "accessToken": "...",
  "refreshToken": "...",
  "isFirstLogin": true,
  "user": { "id": "uuid", "fullName": "Budi", "phoneNumber": "08123456789" }
}
```

- **Error Cases:**
  - `INVALID_CREDENTIALS` — password salah, setelah 5x gagal akun terkunci 30 menit
  - `ACCOUNT_SUSPENDED` — akun dinonaktifkan
  - `ACCOUNT_LOCKED` — terkunci sementara (response includes `locked_until`)

### `POST /auth/refresh`
- **Auth:** Tidak perlu (menggunakan refresh token)
- **Body:** `{ "refreshToken": "jwt.refresh.token" }`
- **Response:** `{ "accessToken": "...", "refreshToken": "..." }`
- **Note:** Refresh token lama di-invalidate (rotation)

### `POST /auth/change-password`
- **Auth:** `Bearer Token` (customer JWT)
- **Body:**
  | Field | Type | Required | Notes |
  |-------|------|----------|-------|
  | `oldPassword` | string | Ya | |
  | `newPassword` | string | Ya | Min 8 karakter |

- **Response:** `{ "message": "Password berhasil diubah." }`
- **Side Effect:** Semua session lain di-logout

### `POST /auth/logout`
- **Auth:** `Bearer Token`
- **Body:** `{ "refreshToken": "..." }`
- **Response:** `{ "message": "Logout berhasil." }`

### `POST /auth/logout-all`
- **Auth:** `Bearer Token`
- **Response:** `{ "message": "Semua sesi telah diakhiri." }`

---

## 3. Customer Profile (/me)

> Semua endpoint di bawah memerlukan `Bearer Token` dan `FirstLoginGuard` (harus ganti password dulu jika first login).

### `GET /me`
- **Response:**
```json
{
  "id": "uuid",
  "fullName": "Budi Santoso",
  "phoneNumber": "08123456789",
  "avatarUrl": null,
  "address": "Jl. Sudirman 10",
  "accountStatus": "active",
  "isFirstLogin": false,
  "createdAt": "2026-01-01T00:00:00Z",
  "updatedAt": "2026-01-01T00:00:00Z"
}
```

### `PATCH /me`
- **Body:** `{ "fullName": "New Name", "address": "New Address", "avatarUrl": "https://..." }`
- Semua field optional

### `GET /me/summary`
- **Response:**
```json
{ "activeOrders": 3, "activeCoupons": 2, "activeWarranty": 1 }
```
- `activeOrders` = jumlah order dengan status selain `completed`/`cancelled`
- `activeCoupons` = kupon belum dipakai & belum expired
- `activeWarranty` = order completed dengan warranty masih berlaku

### `GET /me/coupons`
- **Response:** Array of `{ id, code, amount, isUsed, expiredAt, ... }`

### `GET /me/orders`
- **Response:** Array of semua order milik user (dengan items, tracking, payments, store info)
- **Query Params:** Tidak ada (mengembalikan semua)

### `GET /me/orders/:id/progress`
- **Params:** `id` = orderId
- **Response:** Detail order + tracking timeline
- **Error:** `ORDER_NOT_FOUND` jika bukan milik user ini

### `GET /me/notifications`
- **Response:** 50 notifikasi terbaru dari `service_tracking` (30 hari terakhir)
- Include `order.orderNumber`

---

## 4. Stores (Public)

### `GET /stores`
- **Auth:** Tidak perlu
- **Query Params:**
  | Param | Type | Notes |
  |-------|------|-------|
  | `brand` | string | Filter brand device |
  | `partType` | string | Filter tipe sparepart |

- **Response:** Array of stores dengan spareparts yang match + info rating

### `GET /stores/match`
- **Query Params:**
  | Param | Type | Notes |
  |-------|------|-------|
  | `brand` | string | Required |
  | `deviceModel` | string | Required |
  | `partType` | string | Required |

- **Response:**
```json
[{
  "storeId": "uuid",
  "storeName": "Service Center ABC",
  "address": "...",
  "ratingAvg": 4.5,
  "matchingParts": [{ "partName": "LCD iPhone 14", "price": 850000, "qty": 3 }],
  "estimatedServiceFee": 50000,
  "totalEstimate": 900000
}]
```

### `GET /stores/:id`
- **Response:** Detail store + reviews

### `GET /stores/:id/spareparts`
- **Query Params:** `brand`, `deviceModel`, `partType` (optional)
- **Response:** Array spareparts yang tersedia di store

---

## 5. Orders (Customer)

### `POST /orders`
- **Auth:** `Bearer Token`
- **Body:**
```json
{
  "storeId": "uuid",
  "deviceType": "android",
  "brand": "Samsung",
  "deviceModel": "Galaxy S23",
  "deliveryMethod": "walk_in",
  "deliveryAddress": null,
  "items": [
    {
      "serviceType": "Ganti LCD",
      "complaint": "LCD retak",
      "sparepartId": "uuid",
      "itemPrice": 850000
    }
  ],
  "couponCode": "COUPON123"
}
```

- **Notes:**
  - `deliveryMethod: courier_pickup` wajib isi `deliveryAddress`
  - `couponCode` optional, harus valid & belum dipakai
  - Sparepart stock di-reserve (qtyReserved += 1)
  - Order awalnya `waiting_device` dengan SLA 24 jam

- **Response:**
```json
{ "orderId": "uuid", "orderNumber": "SG-20260610-XXXX" }
```

### `GET /orders/me`
- **Response:** Semua order user (sama dengan `GET /me/orders`)

### `GET /orders/:id`
- **Response:** Detail order lengkap

### `GET /orders/:id/progress`
- **Response:** Order + tracking timeline

### `POST /orders/:id/approve`
- **Auth:** `Bearer Token`
- **Description:** Customer menyetujui diagnosis dari teknisi
- **Response:** `{ "message": "Order disetujui." }`
- **Status Transition:** `waiting_approval` → `waiting_sparepart`

### `POST /orders/:id/reject`
- **Auth:** `Bearer Token`
- **Body (optional):** `{ "reason": "..." }`
- **Status Transition:** `waiting_approval` → `cancelled`

---

## 6. Payments (Customer)

### `POST /payments/:orderId`
- **Auth:** `Bearer Token`
- **Body:**
```json
{
  "amount": 900000,
  "paymentMethod": "transfer_bank",
  "paymentType": "final_payment",
  "proofUrl": "https://storage.example.com/proof.jpg"
}
```

- **Notes:**
  - `transfer_bank` wajib upload `proofUrl`
  - `paymentType`: `deposit` | `final_payment` | `refund`
  - `paymentMethod`: `transfer_bank` | `qris` | `cash` | `ewallet`

- **Response:**
```json
{ "paymentId": "uuid", "status": "pending" }
```

---

## 7. Reviews (Customer)

### `POST /reviews/:orderId`
- **Auth:** `Bearer Token`
- **Body:**
```json
{ "rating": 5, "comment": "Servis bagus, cepat!" }
```

- **Notes:**
  - Rating 1-5
  - Order harus berstatus `completed`
  - 1 review per order (duplicate check)
  - **Side Effect:** Otomatis buat coupon reward (Rp 10.000, expired 30 hari)
  - Update `ratingAvg` dan `totalCompleted` pada store

- **Response:**
```json
{ "reviewId": "uuid", "couponCode": "RWD-XXXX" }
```

---

## 8. Disputes (Customer)

### `POST /disputes/:orderId`
- **Auth:** `Bearer Token`
- **Body:**
```json
{
  "disputeType": "warranty_claim",
  "description": "Service rusak lagi setelah 2 minggu",
  "evidenceUrls": ["https://storage.example.com/photo1.jpg"]
}
```

- **Notes:**
  - `disputeType`: `warranty_claim` | `service_quality` | `wrong_diagnosis` | `other`
  - Order harus `completed` dan masih dalam warranty
  - Tidak boleh ada dispute aktif lain untuk order yang sama
  - SLA respond: 24 jam untuk store

- **Response:**
```json
{ "disputeId": "uuid" }
```

---

## 9. Store Auth

### `POST /store/auth/login`
- **Body:**
```json
{ "phoneNumber": "08123456789", "password": "xxx" }
```

- **Response:**
```json
{
  "accessToken": "...",
  "refreshToken": "...",
  "admin": { "id": "uuid", "fullName": "Admin Toko", "storeId": "uuid" }
}
```

### `POST /store/auth/change-password`
- **Auth:** `Bearer Token` (store admin JWT)
- **Body:** `{ "oldPassword": "...", "newPassword": "..." }`

### `POST /store/auth/logout`
- **Auth:** `Bearer Token`

---

## 10. Store Dashboard

> Semua endpoint di bawah memerlukan `Bearer Token` (store admin JWT).

### `GET /store/dashboard`
- **Response:**
```json
{
  "totalOrdersToday": 5,
  "activeOrders": 12,
  "pendingPayments": 3,
  "openDisputes": 1,
  "monthlyRevenue": 5000000,
  "ratingAvg": 4.5,
  "statusBreakdown": {
    "waiting_device": 3,
    "diagnosing": 2,
    "repairing": 4,
    "waiting_payment": 3
  },
  "recentOrders": [...]
}
```

### `GET /store/customers`
- **Response:** Daftar customer yang pernah order di store ini

### `GET /store/payments`
- **Response:** Semua payment records untuk order di store ini

### `POST /store/payments/:orderId/:paymentId/confirm`
- **Body:** `{ "confirmedBy": "admin-name" }`
- **Side Effect:**
  - Status payment → `confirmed`
  - Status order → `completed`
  - Set warranty (30 hari dari sekarang)
  - Increment `totalCompleted` store

### `GET /store/reviews`
- **Response:** Semua reviews untuk store ini

### `POST /store/reviews/:reviewId/respond`
- **Body:** `{ "response": "Terima kasih atas ulasannya!" }`

### `GET /store/notifications`
- **Response:** Notifikasi untuk store ini

### `GET /store/profile`
- **Response:** Detail store profile

### `PATCH /store/profile`
- **Body:** `{ "storeName": "...", "operationalHours": {...}, "config": {...} }`

### `GET /store/analytics`
- **Response:** Data analytics untuk dashboard charts

---

## 11. Store Orders

### `GET /store/orders`
- **Query Params:**
  | Param | Type | Notes |
  |-------|------|-------|
  | `status` | string | Filter by status |
  | `search` | string | Cari order number/nama customer |
  | `page` | number | Pagination (default: 1) |
  | `limit` | number | Items per page (default: 20) |

- **Response:**
```json
{
  "orders": [...],
  "total": 50,
  "page": 1,
  "limit": 20
}
```

### `GET /store/orders/:id`
- **Response:** Detail order lengkap + `allowedActions` + `credentialPanel`

### `PATCH /store/orders/:id/status`
- **Body:**
```json
{ "status": "diagnosing" }
```

- **Status Transitions yang diizinkan:**
  ```
  waiting_device → device_received
  device_received → diagnosing
  waiting_sparepart → repairing
  repairing → quality_check
  quality_check → waiting_payment
  waiting_payment → completed
  ```

### `POST /store/orders/:id/diagnosis`
- **Body:**
```json
{
  "note": "LCD perlu diganti, baterai masih bagus",
  "estimatedDays": 2,
  "items": [
    {
      "serviceType": "Ganti LCD",
      "itemPrice": 850000,
      "status": "confirmed",
      "technicianNote": "LCD crack parah"
    },
    {
      "serviceType": "Cek Baterai",
      "itemPrice": 0,
      "status": "confirmed",
      "technicianNote": "Baterai normal"
    }
  ]
}
```

- **Response:** Menunggu approval customer (status → `waiting_approval`)

### `GET /store/orders/:id/tracking`
- **Response:** Tracking timeline

### `POST /store/orders/:id/tracking`
- **Body:** `{ "status": "repairing", "note": "Sedang proses penggantian LCD" }`

### `POST /store/orders/:id/credential-sent`
- **Description:** Menandai credential sudah dikirim ke customer baru
- **Side Effect:** `isCredentialSent = true` pada user

---

## 12. Store Spareparts

### `GET /store/spareparts`
- **Query Params:** `search`, `brand`, `status`, `page`, `limit`

### `POST /store/spareparts`
- **Body:**
```json
{
  "brand": "Apple",
  "deviceModel": "iPhone 14",
  "partType": "LCD",
  "partName": "LCD iPhone 14 Original",
  "price": 850000,
  "qty": 10,
  "status": "available"
}
```

### `PATCH /store/spareparts/:id`
- **Body:** Field mana yang mau diupdate

### `DELETE /store/spareparts/:id`

---

## 13. Platform Admin

### `POST /platform/login`
- **Body:** `{ "username": "admin", "password": "xxx" }`
- **Response:** `{ "accessToken": "...", "admin": { "id", "username", "fullName" } }`

### `POST /platform/stores`
- **Auth:** `Bearer Token` (platform admin JWT)
- **Body:**
```json
{
  "storeName": "Service Center Baru",
  "address": "Jl. Gatot Subroto 20",
  "phoneNumber": "08111222333",
  "adminFullName": "Admin Toko",
  "adminPhoneNumber": "08111222444",
  "adminPassword": "optional-custom-pass",
  "deviceTypes": ["android", "ios"]
}
```

- **Side Effect:**
  - Buat store + 1 store admin
  - Generate password otomatis jika tidak diisi
  - Hash password dengan bcrypt

### `GET /platform/stores`
- **Response:** Daftar semua stores

---

## 14. Uploads

### `POST /uploads/presign`
- **Auth:** `Bearer Token`
- **Body:** `{ "filename": "photo.jpg", "contentType": "image/jpeg" }`
- **Response:** `{ "uploadUrl": "...", "fileUrl": "..." }`
- **Note:** Menggunakan S3-compatible storage (Cloudflare R2 / AWS S3)

---

## 15. Notifications

Notifikasi dikirim via WhatsApp menggunakan Fonnte Gateway.

### Flow Notifikasi
- Setiap perubahan status order mengirim WhatsApp ke customer
- Dispute creation & response mengirim notifikasi
- Gagal mengirim → disimpan ke `failed_notifications` table
- Background job retry setiap 5 menit

### WhatsApp Message Types
| Event | Template |
|-------|----------|
| Order created | `✅ Order {orderNumber} berhasil dibuat. Status: Menunggu perangkat.` |
| Status change | `🔄 Order {orderNumber} status berubah menjadi: {status}` |
| Diagnosis ready | `🔍 Diagnosis untuk order {orderNumber} sudah selesai.` |
| Dispute created | `⚠️ Klaim garansi masuk untuk order {orderNumber}. Respons dalam 24 jam.` |
| Dispute accepted | `✅ Klaim garansimu diterima! Order perbaikan ulang sudah dibuat.` |
| Dispute rejected | `❌ Klaim garansimu ditolak. Alasan: {reason}` |

---

## 16. Background Jobs

### SLA Monitor (`sla-monitor.job.ts`)
- **Schedule:** Setiap 5 menit (`@Cron('*/5 * * * *')`)
- **Fungsi:**
  1. Cari order dengan status aktif yang melewati `slaDeadline`
  2. Kirim WhatsApp warning jika belum warned
  3. Increment `slaBreachCount`
  4. Update `slaWarnedAt`

### Credential Cleaner (`credential-cleaner.job.ts`)
- **Schedule:** Setiap 1 jam
- **Fungsi:**
  1. Cari user dengan `isCredentialSent = true` dan `credentialPlainEnc` belum null
  2. Setelah 24 jam → hapus `credentialPlainEnc` (force delete)
  3. Bersihkan data credential plain text

---

## Rate Limiting

- **Default:** 100 requests per 60 detik per IP
- **Configurable:** `THROTTLE_TTL_SECONDS` dan `THROTTLE_LIMIT` di `.env`

## CORS

- **Origin:** `APP_URL` (default: `http://localhost:3000`)
- **Credentials:** `true`

## Pagination

Beberapa endpoint mendukung pagination:
- `page` (default: 1)
- `limit` (default: 20)

Response pagination:
```json
{
  "data": [...],
  "total": 100,
  "page": 1,
  "limit": 20
}
```
