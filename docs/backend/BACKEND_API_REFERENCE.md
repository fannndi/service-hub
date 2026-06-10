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

### `GET /me/coupons`
- **Response:** Array of `{ id, code, amount, isUsed, expiredAt, ... }`

### `GET /me/orders`
- **Response:** Array of semua order milik user (dengan items, tracking, payments, store info)

### `GET /me/orders/:id/progress`
- **Params:** `id` = orderId
- **Response:** Detail order + tracking timeline
- **Error:** `ORDER_NOT_FOUND` jika bukan milik user ini

### `GET /me/notifications`
- **Response:** 50 notifikasi terbaru dari `service_tracking` (30 hari terakhir)

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
  "phoneNumber": "08111222333",
  "ratingAvg": 4.5,
  "totalCompleted": 150,
  "spareparts": [{ "id": "uuid", "partName": "LCD iPhone 14", "partType": "LCD", "price": 850000, "availableQty": 3, "status": "available" }],
  "estimatedCost": 900000
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
- **Auth:** Tidak perlu (stealth account — akun dibuat otomatis jika belum ada)
- **Body:**
```json
{
  "storeId": "uuid",
  "deviceType": "android",
  "brand": "Samsung",
  "deviceModel": "Galaxy S23",
  "deliveryMethod": "walk_in",
  "customerName": "Budi Santoso",
  "phoneNumber": "08123456789",
  "couponCode": "COUPON123",
  "items": [
    {
      "serviceType": "ganti_lcd",
      "complaint": "LCD retak",
      "sparepartId": "uuid"
    }
  ]
}
```

- **Notes:**
  - `deliveryMethod: courier_pickup` wajib isi `deliveryAddress`
  - `customerName` dan `phoneNumber` wajib untuk auto-create account
  - `couponCode` optional, harus valid & belum dipakai
  - Sparepart stock di-reserve (qtyReserved += 1)
  - Order awalnya `waiting_device` dengan SLA 24 jam

- **Response:**
```json
{
  "id": "uuid",
  "orderNumber": "SG-20260610-XXXX",
  "status": "waiting_device",
  "totalEstimasi": 0,
  "isNewCustomer": true,
  "message": "Order berhasil dibuat."
}
```

### `GET /orders/me`
- **Response:** Semua order user

### `GET /orders/:id`
- **Response:** Detail order lengkap

### `POST /orders/:id/approve`
- **Auth:** `Bearer Token` (customer JWT)
- **Description:** Customer menyetujui diagnosis dari teknisi
- **Status Transition:** `waiting_approval` → `repairing`

### `POST /orders/:id/reject`
- **Auth:** `Bearer Token` (customer JWT)
- **Body (optional):** `{ "reason": "..." }`
- **Status Transition:** `waiting_approval` → `cancelled`

### `POST /orders/:id/payments`
- **Auth:** Tidak perlu
- **Description:** Buat payment untuk order (alternate route)

### `POST /orders/:id/reviews`
- **Auth:** Tidak perlu
- **Description:** Buat review untuk order (alternate route)

### `POST /orders/:id/disputes`
- **Auth:** Tidak perlu
- **Description:** Buat dispute untuk order (alternate route)

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

### `GET /disputes`
- **Auth:** `Bearer Token`
- **Description:** List semua dispute milik customer

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

> Semua endpoint di bawah memerlukan `Bearer Token` (store admin JWT) + `FirstLoginGuard`.

### `GET /store/dashboard/summary`
- **Response:**
```json
{
  "activeOrders": 12,
  "byStatus": {
    "waiting_device": 3,
    "diagnosing": 2,
    "repairing": 4,
    "waiting_payment": 3
  },
  "pendingPayments": 3,
  "openDisputes": 1,
  "ratingAvg": 4.5,
  "totalCompletedThisMonth": 15
}
```

### `GET /store/customers`
- **Response:** Daftar customer yang pernah order di store ini

### `GET /store/payments`
- **Response:** Semua payment records untuk order di store ini

### `GET /store/reviews`
- **Response:** Semua reviews untuk store ini

### `POST /store/reviews/:reviewId/response`
- **Body:** `{ "response": "Terima kasih atas ulasannya!" }`

### `GET /store/notifications`
- **Response:** Notifikasi untuk store ini

### `GET /store/profile`
- **Response:** Detail store profile

### `PATCH /store/profile`
- **Body:** `{ "storeName": "...", "operationalHours": {...}, "config": {...} }`

### `PATCH /store/settings`
- **Body:** `{ "config": {...} }`
- **Description:** Update store configuration

### `GET /store/analytics`
- **Response:** Data analytics untuk dashboard charts (30 hari terakhir)

---

## 11. Store Orders

### `GET /store/orders`
- **Auth:** `Bearer Token` (store admin)
- **Query Params:**
  | Param | Type | Notes |
  |-------|------|-------|
  | `status` | string | Filter by status |
  | `actionGroup` | string | Filter by action group |

### `GET /store/orders/:id`
- **Response:** Detail order lengkap + `allowedActions` + `credentialPanel`

### `POST /store/orders/:id/actions/:action`
- **Description:** Execute action berdasarkan action name
- **Valid Actions:**
  | Action | Status Transition |
  |--------|-------------------|
  | `receive_device` | → `device_received` |
  | `start_diagnosis` | → `diagnosing` |
  | `sparepart_arrived` | → `repairing` |
  | `start_qc` | → `quality_check` |
  | `mark_complete` | → `completed` |

### `PATCH /store/orders/:id/status`
- **Body:**
```json
{ "status": "repairing", "note": "Sedang proses penggantian LCD" }
```

### `POST /store/orders/:id/diagnosis`
- **Body:**
```json
{
  "diagnosisNote": "LCD perlu diganti, baterai masih bagus",
  "serviceFee": 50000,
  "items": [
    {
      "orderItemId": "uuid",
      "status": "confirmed",
      "finalItemPrice": 850000,
      "technicianNote": "LCD crack parah"
    },
    {
      "orderItemId": "uuid",
      "status": "replaced",
      "replacedSparepartId": "uuid",
      "finalItemPrice": 0,
      "technicianNote": "Baterai normal, tidak perlu ganti"
    }
  ]
}
```

- **Status Transition:** `diagnosing` → `waiting_approval`

### `PATCH /store/orders/:id/diagnosis`
- **Description:** Update diagnosis yang sudah ada

### `GET /store/orders/:id/tracking`
- **Response:** Tracking timeline

### `POST /store/orders/:id/tracking`
- **Body:** `{ "status": "repairing", "note": "Sedang proses penggantian LCD" }`

### `POST /store/orders/:id/payments/:paymentId/confirm`
- **Body:** `{ "confirmedBy": "admin-name" }`
- **Side Effect:**
  - Status payment → `confirmed`
  - Status order → `completed`
  - Set warranty (30 hari dari sekarang)
  - Increment `totalCompleted` store

### `POST /store/orders/:id/mark-credential-sent`
- **Description:** Menandai credential sudah dikirim ke customer baru
- **Side Effect:** `isCredentialSent = true` pada user

---

## 12. Store Spareparts

### `GET /store/spareparts`
- **Auth:** Tidak perlu (public query by storeId)
- **Query Params:**
  | Param | Type | Notes |
  |-------|------|-------|
  | `storeId` | string | Required |
  | `search` | string | Cari nama/brand |
  | `brand` | string | Filter brand |
  | `status` | string | Filter status |

### `POST /store/spareparts`
- **Auth:** `Bearer Token` (store admin)
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
- **Auth:** `Bearer Token` (store admin)
- **Body:** Field mana yang mau diupdate

### `DELETE /store/spareparts/:id`
- **Auth:** `Bearer Token` (store admin)

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
  "storePhone": "08111222333",
  "adminName": "Admin Toko",
  "adminPhone": "08111222444",
  "password": "optional-custom-pass",
  "handlesAndroid": true,
  "handlesIos": false,
  "operationalHours": {}
}
```

- **Field Notes:**
  - `storePhone`: Nomor HP toko
  - `adminName`: Nama lengkap admin toko
  - `adminPhone`: Nomor HP admin toko
  - `password`: Password admin (wajib)
  - `handlesAndroid`: Toko handle perangkat Android
  - `handlesIos`: Toko handle perangkat iOS
  - `operationalHours`: JSON jam operasional (optional)

- **Side Effect:**
  - Buat store (`isActive = true`, langsung aktif)
  - Buat 1 store admin
  - Hash password dengan bcrypt

### `GET /platform/stores`
- **Auth:** `Bearer Token` (platform admin JWT)
- **Response:** Daftar semua stores

---

## 14. Uploads

### `POST /uploads/presign`
- **Auth:** `Bearer Token`
- **Body:**
  | Field | Type | Required | Notes |
  |-------|------|----------|-------|
  | `fileName` | string | Ya | Nama file (camelCase, bukan snake_case) |
  | `mimeType` | string | Tidak | MIME type file |
  | `contentType` | string | Tidak | Alternative ke mimeType |
  | `folder` | string | Tidak | Folder tujuan upload |

- **Response:** `{ "uploadUrl": "...", "fileUrl": "..." }`
- **Note:** Menggunakan S3-compatible storage (Cloudflare R2 / AWS S3)
