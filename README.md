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
  <img src="https://img.shields.io/badge/Redis-7-DC382D?logo=redis" alt="Redis">
  <img src="https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker" alt="Docker">
  <img src="https://img.shields.io/badge/TypeScript-5.x-3178C6?logo=typescript" alt="TypeScript">
  <img src="https://img.shields.io/badge/status-complete-brightgreen" alt="Status">
</p>

---

> **Ceritanya begini...** Kamu punya HP rusak, tapi bingung cari tempat servis terpercaya? Di sisi lain, pemilik toko servis kesulitan mengelola order, stok sparepart, dan komunikasi dengan pelanggan?
>
> **ServisGadget hadir** sebagai jembatan dua sisi: pelanggan bisa booking perbaikan **tanpa perlu daftar akun** (cukup nomor HP), dan admin toko bisa mengelola seluruh operasional dari **satu mobile app** — mulai dari terima order, diagnosa, tracking, hingga pembayaran.

---

## Dalam Satu Lihat

| | Phase 1 | Phase 2 | Phase 3 |
|---|:---:|:---:|:---:|
| **Apa?** | Backend API | Mobile App Customer | Mobile App Admin |
| **Stack** | NestJS + Prisma | Flutter + Riverpod | Flutter + Riverpod |
| **Isi** | 12+ modul, 50+ endpoint, 21 model | 17 screen, real-time tracking | 14 screen, analytics dashboard |
| **Status** | ✅ | ✅ | ✅ |

---

## Sorotan Teknis

- **Dua sistem auth terpisah** — Customer JWT vs Store Admin JWT, tidak campur
- **Stealth account** — Pelanggan booking tanpa daftar, akun dibuat otomatis di belakang layar
- **State machine order** — 9 status transisi dengan validasi ketat, SLA timer per status
- **Real-time tracking** — Polling 30 detik, pelanggan bisa lihat progress perbaikan kapan saja
- **Background jobs** — SLA monitor otomatis (warning + breach), credential cleaner tiap 30 menit
- **Notifikasi WhatsApp** — Dengan exponential retry 3x, failed notification logging
- **Kupon reward otomatis** — Pelanggan dapat Rp10.000 setiap beri ulasan

---

## Arsitektur

```
                    Pelanggan              Admin Toko
                  (Flutter App)          (Flutter App)
                       │                      │
                       └──────────┬───────────┘
                                  │
                     REST API (NestJS Monolith)
                     /v1/auth/*     /v1/store/auth/*
                     /v1/me/*       /v1/store/*
                     /v1/orders/*   /v1/store/orders/*
                                  │
                    ┌─────────────┼─────────────┐
                    ▼             ▼             ▼
              ┌──────────┐ ┌──────────┐ ┌──────────┐
              │PostgreSQL│ │  Redis   │ │  AWS S3  │
              └──────────┘ └────┬─────┘ └──────────┘
                                │
                         ┌──────┴──────┐
                         │  BullMQ     │
                         │  SLA        │
                         │  Cleaner    │
                         └─────────────┘
```

---

## Mulai Cepat

### Prasyarat
- Docker & Docker Compose v2+
- Node.js 20.11 LTS · Flutter SDK 3.4+

### Backend — Satu Perintah

```bash
cp .env.example .env
docker compose up --build
```

Buka http://localhost:3000/docs untuk Swagger interaktif.

### Frontend

```bash
cd frontend
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

### Akun Demo

| Role | No. HP | Password |
|------|--------|----------|
| Pelanggan | `081234567890` | `customer123` |
| Admin Toko | `081298765432` | `admin123` |

---

## Jelajah Fitur

### Sisi Pelanggan
- **Beranda** — Ringkasan order aktif, kupon, garansi
- **Cari Toko** — Browsing daftar toko servis + sparepart tersedia
- **Booking** — Pilih sparepart, isi nomor HP, langsung masuk — tanpa daftar
- **Lacak Order** — Timeline real-time, update tiap 30 detik
- **Bayar** — Upload bukti transfer langsung dari app
- **Ulas** — Rating bintang + komentar, otomatis dapat kupon Rp10.000
- **Garansi** — Klaim garansi langsung dari order detail

### Sisi Admin Toko
- **Dashboard** — Analitik 30 hari: total order, pendapatan, rating rata-rata
- **Order** — Terima, diagnosa, ganti sparepart, update status per langkah
- **Tracking** — Timeline progress yang dilihat pelanggan, tambah entry manual
- **Pembayaran** — Konfirmasi pembayaran + lihat bukti transfer
- **Inventori** — Kelola stok sparepart, tambah/edit/hapus
- **Pelanggan** — Lihat daftar pelanggan + panel kredensial akun baru
- **Dispute** — Tangani klaim garansi, setujui/tolak

---

## Endpoint API

### Prefix `/v1` — Customer

```
POST   /auth/login                    PUBLIC
POST   /auth/change-password          Customer
POST   /auth/logout                   Customer
GET    /me/summary                    Customer
GET    /me/orders                     Customer
GET    /me/orders/:id/progress        Customer
GET    /me/notifications              Customer
GET    /stores                        PUBLIC
GET    /stores/:id                    PUBLIC
GET    /spareparts?storeId=           PUBLIC
POST   /orders                        PUBLIC
POST   /orders/:id/payments           Customer
POST   /orders/:id/reviews            Customer
POST   /orders/:id/disputes           Customer
POST   /uploads/presign               Customer
```

### Prefix `/v1/store` — Admin Toko

```
POST   /auth/login                    PUBLIC
POST   /auth/logout                   Store
POST   /auth/change-password          Store
GET    /profile                       Store
PATCH  /profile                       Store
GET    /analytics                     Store
GET    /orders                        Store
GET    /orders/:id                    Store
PATCH  /orders/:id/status             Store
PATCH  /orders/:id/diagnosis          Store
POST   /orders/:id/actions/:action    Store
GET    /orders/:id/tracking           Store
POST   /orders/:id/tracking           Store
POST   /orders/:id/payments/:pid/confirm  Store
GET    /customers                     Store
GET    /payments                      Store
GET    /reviews                       Store
POST   /reviews/:id/response          Store
GET    /notifications                 Store
GET    /spareparts                    Store
POST   /spareparts                    Store
PUT    /spareparts/:id                Store
DELETE /spareparts/:id                Store
GET    /disputes                      Store
GET    /disputes/:id                  Store
POST   /disputes/:id/respond          Store
```

> Dokumentasi lengkap & interaktif di **Swagger** → http://localhost:3000/docs

---

## Struktur Project

```
service-hub/
├── backend/                  NestJS API (68 file .ts)
│   ├── src/
│   │   ├── modules/          auth, store-auth, users, stores, orders,
│   │   │   payments, reviews, disputes, notifications, uploads, jobs
│   │   ├── common/           guards, decorators, filters, pipes
│   │   └── config/           typed environment
│   └── prisma/               schema (21 model) + seed
│
├── frontend/                 Flutter (57 file .dart)
│   └── lib/
│       ├── features/
│       │   ├── customer/     17 screen, Riverpod, GoRouter
│       │   └── store_admin/  14 screen, Riverpod, GoRouter
│       ├── network/          Dio interceptors, token refresh
│       └── shared_widgets/   StatusBadge, SearchFilterBar, dll
│
├── docs/                     PRD, arsitektur, integrasi, task-list
├── docker-compose.yml        PostgreSQL 16 + Redis 7 + Backend
└── CHANGELOG.md
```

---

## Tim

1. **Fandi** — Phase 1 · Backend Foundation (NestJS API)
2. **Andriyan** — Phase 2 · Customer Mobile App (Flutter)
3. **Nissa** — Phase 3 · Store Admin App + Backend Extension

Pembagian tugas detail: → **[docs/task-list.md](docs/task-list.md)**

---

## Dokumentasi

| Dokumen | Isi |
|---------|-----|
| [PRD/00_MASTER_PRD.md](docs/PRD/00_MASTER_PRD.md) | Single source of truth — business rules, API contracts |
| [PRD/01_PHASE_FOUNDATION.md](docs/PRD/01_PHASE_FOUNDATION.md) | Spesifikasi lengkap Phase 1 |
| [PRD/02_PHASE_CUSTOMER.md](docs/PRD/02_PHASE_CUSTOMER.md) | Spesifikasi lengkap Phase 2 |
| [PRD/03_PHASE_STORE_ADMIN.md](docs/PRD/03_PHASE_STORE_ADMIN.md) | Spesifikasi lengkap Phase 3 |
| [CHANGELOG.md](CHANGELOG.md) | Riwayat perubahan semua phase |

---

<p align="center">
  <b>ServisGadget</b> &mdash; Phase 1, 2, 3 selesai. Siap digunakan.
</p>
