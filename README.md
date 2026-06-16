<p align="center">
  <h1 align="center">ServisGadget</h1>
  <p align="center">
    <b>Platform Marketplace Servis Gadget Dua Sisi</b><br>
    <sub>Pelanggan booking tanpa daftar · Admin toko kelola dari mobile</sub>
  </p>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/NestJS-10.x-E0234E?logo=nestjs" alt="NestJS">
  <img src="https://img.shields.io/badge/Flutter-3.4+-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/PostgreSQL-16-336791?logo=postgresql" alt="PostgreSQL">
  <img src="https://img.shields.io/badge/Supabase-Database-3ECF8E?logo=supabase" alt="Supabase">
  <img src="https://img.shields.io/badge/TypeScript-5.x-3178C6?logo=typescript" alt="TypeScript">
  <img src="https://img.shields.io/badge/status-complete-brightgreen" alt="Status">
</p>

---

> **Ceritanya begini...** Kamu punya HP rusak, tapi bingung cari tempat servis terpercaya? Di sisi lain, pemilik toko servis kesulitan mengelola order, stok sparepart, dan komunikasi dengan pelanggan?
>
> **ServisGadget hadir** sebagai jembatan dua sisi: pelanggan bisa booking perbaikan **tanpa perlu daftar akun** (cukup nomor HP), dan admin toko bisa mengelola seluruh operasional dari **satu mobile app** — mulai dari terima order, diagnosa, tracking, hingga pembayaran.

---

## Dalam Satu Lihat

| Aktor | Login | Dashboard |
|---|---|---|
| **Pelanggan** | `/login` — HP + password | Home: ringkasan order, kupon, garansi |
| **Admin Toko** | `/store-login` — HP + password | Dashboard: order, inventori, pembayaran, analitik |
| **Admin Platform** | `/admin/login` — username + password | Buat toko, set device types (Android/iOS), kelola akun toko |

---

## Sorotan Teknis

- **Tiga sistem auth terpisah** — Customer JWT, Store Admin JWT, Platform Admin JWT
- **Stealth account** — Pelanggan booking tanpa daftar, akun dibuat otomatis
- **Matching engine** — Auto-filter toko by brand, model, sparepart, stock tersedia
- **Multi-step booking** — 5 langkah: device → kerusakan → match toko → data diri → booking
- **State machine order** — 11 status transisi dengan validasi ketat, SLA timer per status
- **Real-time tracking** — Polling 30 detik, pelanggan lihat progress perbaikan
- **Background jobs** — SLA monitor auto-cancel, credential cleaner (via `@nestjs/schedule`)
- **Kupon reward otomatis** — Pelanggan dapat Rp10.000 setiap beri ulasan

---

## Mulai Cepat (No Docker)

### Prasyarat
- Node.js 20+ · Flutter SDK 3.4+ · Database Supabase

### Backend

```bash
cd backend
cp .env .env.example          # edit DATABASE_URL dengan connection string Supabase
npm install
npx prisma generate
npx prisma db push
npm run start:dev             # jalan di http://localhost:3000
```

Swagger: http://localhost:3000/docs

### Flutter

```bash
cd frontend
flutter pub get
flutter run                    # emulator otomatis konek ke localhost
```

### Build APK Release

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api-domainmu.com/v1
```

### Akun Default

| Role | Login | Password |
|------|-------|----------|
| Admin Platform | `admin` | `admin` |
| Pelanggan | `081212345678` | `customer123` |

---

## Jelajah Fitur

### Sisi Pelanggan
- **Welcome** — 4 tombol: Service Now, Pelanggan, Toko, Admin
- **Service Now** — Multi-step booking: device type → kerusakan → match toko → data diri → booking
- **Cari Toko** — Browsing daftar toko servis + sparepart tersedia
- **Lacak Order** — Timeline real-time, update tiap 30 detik
- **Bayar** — Upload bukti transfer langsung dari app
- **Ulas** — Rating bintang + komentar, otomatis dapat kupon Rp10.000
- **Garansi** — Klaim garansi langsung dari order detail

### Sisi Admin Toko
- **Dashboard** — Analitik 30 hari: total order, pendapatan, rating rata-rata
- **Order** — Terima, diagnosa, ganti sparepart, update status per langkah
- **Tracking** — Timeline progress, tambah entry manual
- **Pembayaran** — Konfirmasi pembayaran + lihat bukti transfer
- **Inventori** — Kelola stok sparepart, tambah/edit/hapus
- **Pelanggan** — Lihat daftar pelanggan + panel kredensial akun baru
- **Dispute** — Tangani klaim garansi, setujui/tolak

### Sisi Admin Platform
- **Buat Toko** — Input nama, alamat, admin toko, password, pilih Android/iOS
- **Daftar Toko** — Lihat semua toko dengan chip Android/iOS

---

## Endpoint API

### Prefix `/v1` — Public & Customer

```
POST   /auth/login                      PUBLIC
POST   /auth/change-password            Customer
POST   /auth/logout                     Customer
GET    /me                              Customer
PATCH  /me                              Customer
GET    /me/summary                      Customer
GET    /me/orders                       Customer
GET    /me/orders/:id/progress          Customer
GET    /me/coupons                      Customer
GET    /me/notifications                Customer
GET    /stores                          PUBLIC
GET    /stores/:id                      PUBLIC
GET    /stores/match                    PUBLIC    ← Matching Engine
GET    /stores/:id/spareparts           PUBLIC
POST   /orders                          PUBLIC    ← No auth (stealth account)
GET    /orders/:id                      Customer
POST   /orders/:id/approve              Customer
POST   /orders/:id/reject               Customer
POST   /orders/:id/payments             Customer
POST   /orders/:id/reviews              Customer
POST   /orders/:id/disputes             Customer
POST   /uploads/presign                 Customer
```

### Prefix `/v1/store` — Admin Toko

```
POST   /auth/login                      PUBLIC
POST   /auth/change-password            Store
POST   /auth/logout                     Store
GET    /profile                         Store
PATCH  /profile                         Store
GET    /analytics                       Store
GET    /orders                          Store
GET    /orders/:id                      Store
PATCH  /orders/:id/status               Store
POST   /orders/:id/diagnosis            Store
PATCH  /orders/:id/diagnosis            Store
POST   /orders/:id/actions/:action      Store
GET    /orders/:id/tracking             Store
POST   /orders/:id/tracking             Store
POST   /orders/:id/payments/:pid/confirm Store
POST   /orders/:id/mark-credential-sent Store
GET    /customers                       Store
GET    /payments                        Store
GET    /reviews                         Store
POST   /reviews/:id/response            Store
GET    /notifications                   Store
GET    /spareparts                      Store
POST   /spareparts                      Store
PATCH  /spareparts/:id                  Store
DELETE /spareparts/:id                  Store
GET    /dashboard/summary               Store
PATCH  /settings                        Store
GET    /disputes                        Store
POST   /disputes/:id/respond            Store
```

### Prefix `/v1/platform` — Admin Platform

```
POST   /login                           PUBLIC
POST   /stores                          Admin
GET    /stores                          Admin
```

### Prefix `/v1/store` — Registrasi

```
POST   /register                        PUBLIC    ← Self-registration toko
```

---

## Struktur Project

```
service-hub/
├── backend/                     NestJS API
│   ├── src/modules/
│   │   ├── auth/                Customer auth + stealth account
│   │   ├── store-auth/          Store admin auth
│   │   ├── platform-admin/      Platform admin auth + store creation
│   │   ├── users/               /me endpoints
│   │   ├── stores/              Store listing + matching engine
│   │   ├── store-register/      Store self-registration
│   │   ├── orders/              Order CRUD + state machine + diagnosis
│   │   ├── spareparts/          Sparepart inventory
│   │   ├── payments/            Payment + confirmation
│   │   ├── reviews/             Reviews + coupon rewards
│   │   ├── disputes/            Dispute + warranty claims
│   │   ├── notifications/       WhatsApp notifications
│   │   ├── uploads/             S3 presigned uploads
│   │   └── jobs/                SLA monitor + credential cleaner
│   ├── prisma/                  Schema + seed
│   └── Dockerfile               Multi-stage production build
│
├── frontend/                    Flutter
│   └── lib/
│       ├── core/                Shared: config, json_helpers, domain types
│       │   ├── json_helpers.dart    Unified deserialization helpers
│       │   └── domain/             OrderStatus, PaymentRecordStatus, PageResult
│       ├── network/             Dio client, auth factory, error mapping
│       ├── shared_widgets/      StatusBadge, ErrorState, EmptyState, Formatters
│       ├── storage/             Secure token storage abstraction
│       └── features/
│           ├── customer/            Pelanggan (26 screens, 7 domain model files)
│           ├── store_admin/         Admin Toko (14 screens, 9 domain model files)
│           └── platform_admin/      Admin Platform (2 screens)
│
├── docs/                        Dokumentasi lengkap
│   ├── backend/                 Backend reference (5 files)
│   │   ├── BACKEND_API_REFERENCE.md
│   │   ├── BACKEND_DATABASE_SCHEMA.md
│   │   ├── BACKEND_AUTH_SYSTEM.md
│   │   ├── BACKEND_BUSINESS_LOGIC.md
│   │   └── BACKEND_SETUP.md
│   ├── frontend/                Frontend reference (5 files)
│   │   ├── FRONTEND_ARCHITECTURE.md
│   │   ├── FRONTEND_CUSTOMER.md
│   │   ├── FRONTEND_STORE_ADMIN.md
│   │   ├── FRONTEND_PLATFORM_ADMIN.md
│   │   └── FRONTEND_NETWORK_LAYER.md
│   ├── PRD/                     Product Requirements Documents
│   └── *.md                     Arsitektur, run-guide, task-list
│
├── render.yaml                  One-click Render deployment
└── CHANGELOG.md                 Riwayat perubahan lengkap

---

## Deployment

### Production (Play Store)
1. Deploy backend ke Render (via `render.yaml`) atau VPS
2. Build Flutter dengan production URL:
   ```bash
   flutter build appbundle --release --dart-define=API_BASE_URL=https://api.yourdomain.com/v1
   ```
3. Upload AAB ke Google Play Console

Lihat **[docs/run-guide.md](docs/run-guide.md)** untuk panduan lengkap.

---

## Dokumentasi

### Backend Docs

| Dokumen | Isi |
|---------|-----|
| [BACKEND_API_REFERENCE.md](docs/backend/BACKEND_API_REFERENCE.md) | Referensi lengkap semua endpoint API, request/response, error codes |
| [BACKEND_DATABASE_SCHEMA.md](docs/backend/BACKEND_DATABASE_SCHEMA.md) | Schema database: 21 models, 20+ enums, relasi, indexes |
| [BACKEND_AUTH_SYSTEM.md](docs/backend/BACKEND_AUTH_SYSTEM.md) | 3 sistem JWT auth, stealth account, enkripsi credential, security |
| [BACKEND_BUSINESS_LOGIC.md](docs/backend/BACKEND_BUSINESS_LOGIC.md) | Order lifecycle, state machine, SLA, payments, reviews, disputes |
| [BACKEND_SETUP.md](docs/backend/BACKEND_SETUP.md) | Environment variables, Docker setup, deployment, project structure |

### Frontend Docs

| Dokumen | Isi |
|---------|-----|
| [FRONTEND_ARCHITECTURE.md](docs/frontend/FRONTEND_ARCHITECTURE.md) | Clean architecture, Riverpod, GoRouter, shared widgets |
| [FRONTEND_CUSTOMER.md](docs/frontend/FRONTEND_CUSTOMER.md) | Customer feature: 24 screens, models, repos, providers |
| [FRONTEND_STORE_ADMIN.md](docs/frontend/FRONTEND_STORE_ADMIN.md) | Store admin feature: 18 screens, responsive layout |
| [FRONTEND_PLATFORM_ADMIN.md](docs/frontend/FRONTEND_PLATFORM_ADMIN.md) | Platform admin feature: 2 screens, admin flow |
| [FRONTEND_NETWORK_LAYER.md](docs/frontend/FRONTEND_NETWORK_LAYER.md) | Dio client, error handling, token management, provider system |

### Other Docs

| Dokumen | Isi |
|---------|-----|
| [PRD/00_MASTER_PRD.md](docs/PRD/00_MASTER_PRD.md) | Single source of truth — business rules, API contracts |
| [docs/run-guide.md](docs/run-guide.md) | Panduan menjalankan backend + Flutter |
| [CHANGELOG.md](CHANGELOG.md) | Riwayat perubahan semua phase |
| [docs/architecture.md](docs/architecture.md) | Detail arsitektur sistem |

---

<p align="center">
  <b>ServisGadget</b> — Siap deploy Play Store.
</p>
