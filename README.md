<p align="center">
  <h1 align="center">ServisGadget</h1>
  <p align="center">
    <b>Platform Marketplace Servis Gadget Dua Sisi</b><br>
    <sub>Pelanggan booking tanpa daftar · Admin toko kelola dari mobile · Deploy via Docker + Cloudflare Tunnel</sub>
  </p>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/NestJS-10.x-E0234E?logo=nestjs" alt="NestJS">
  <img src="https://img.shields.io/badge/Flutter-3.4+-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/PostgreSQL-16-336791?logo=postgresql" alt="PostgreSQL">
  <img src="https://img.shields.io/badge/Redis-7-DC382D?logo=redis" alt="Redis">
  <img src="https://img.shields.io/badge/TypeScript-5.x-3178C6?logo=typescript" alt="TypeScript">
  <img src="https://img.shields.io/badge/status-production--ready-brightgreen" alt="Status">
  <img src="https://img.shields.io/badge/tests-175%20passing-2ea44f" alt="Tests">
  <img src="https://img.shields.io/badge/security-audited-blue" alt="Security">
</p>

---

> **Ceritanya begini...** Kamu punya HP rusak, tapi bingung cari tempat servis terpercaya? Di sisi lain, pemilik toko servis kesulitan mengelola order, stok sparepart, dan komunikasi dengan pelanggan?
>
> **ServisGadget hadir** sebagai jembatan dua sisi: pelanggan bisa booking perbaikan **tanpa perlu daftar akun** (cukup nomor HP), dan admin toko bisa mengelola seluruh operasional dari **satu mobile app** — mulai dari terima order, diagnosa, tracking, hingga pembayaran.

---

## Quick Start (Docker + Cloudflare Tunnel)

Rekomendasi utama: **Docker di WSL + Cloudflare Tunnel** untuk deploy instan tanpa VPS.

### Prasyarat

- **WSL 2** + Ubuntu/Debian distro
- **Docker Engine** di WSL (bukan Docker Desktop)
- **Node.js 20+** di WSL
- **Flutter SDK 3.4+**
- **Git** credentials ter-cache di WSL

### Setup

```bash
# 1. Clone & install
git clone https://github.com/fannndi/service-hub.git
cd service-hub

# 2. Setup .env (otomatis dari secrets/.env.local)
./switch-env.sh local

# 3. Fix hostnames untuk Docker networking
sed -i 's|@localhost:5432/|@postgres:5432/|' .env
sed -i 's|REDIS_HOST=localhost|REDIS_HOST=redis|' .env

# 4. Build & start semua services
docker compose up -d --build

# 5. Migrasi database + seed data
docker compose exec backend npx prisma db push
docker compose exec backend npx prisma db seed

# 6. Verify health
curl http://localhost:3000/v1/health
```

### Start Cloudflare Tunnel (untuk HP connect dari mana saja)

```bash
# Install cloudflared
sudo curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
  -o /usr/local/bin/cloudflared
sudo chmod +x /usr/local/bin/cloudflared

# Start tunnel
cloudflared tunnel --url http://localhost:3000
# URL akan muncul: https://xxxx.trycloudflare.com

# Update tunel.txt + push ke GitHub
echo "https://xxxx.trycloudflare.com/v1" > tunel.txt
git add tunel.txt && git commit -m "tunnel: xxxx" && git push
```

**Flutter app otomatis fetch URL baru dari `tunel.txt` saat startup** — tidak perlu rebuild APK.

### Build APK

```bash
cd frontend
flutter build apk
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`

Distribute ke HP via WhatsApp/Bluetooth/USB.

### Default Accounts

| Role | Login | Password |
|------|-------|----------|
| Platform Admin | `/admin/login` | `admin` / `admin` |
| Store Admin | `/store-login` | Dibuat dari Platform Admin |
| Customer | `/login` | Booking langsung (stealth account) |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Backend** | NestJS 10.x, TypeScript 5.x, Node.js 20+ |
| **Frontend** | Flutter 3.4+, Dart 3.x, Riverpod 2.5, GoRouter 14 |
| **Database** | PostgreSQL 16 (Docker / Supabase) |
| **Cache** | Redis 7 (Docker) |
| **ORM** | Prisma 5.x |
| **Auth** | 3 JWT systems (Customer, Store Admin, Platform Admin) |
| **Queue** | BullMQ via @nestjs/bullmq |
| **Notifications** | WhatsApp (Fonnte) + SMTP email fallback |
| **Storage** | Cloudflare R2 / S3 (presigned URLs) |
| **CI/CD** | GitHub Actions |
| **Tunnel** | Cloudflare Quick Tunnel (auto-fetch by Flutter app) |

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      HP (3 device)                       │
│  Customer │ Store Admin │ Platform Admin                 │
└─────┬─────┴──────┬──────┴────────┬──────────────────────┘
      │            │               │
      ▼            ▼               ▼
┌─────────────────────────────────────────────────────────┐
│              Cloudflare Tunnel (public URL)              │
│         https://xxxx.trycloudflare.com/v1               │
└─────────────────────────┬───────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                    Backend (NestJS)                       │
│               Docker Container (port 3000)               │
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌────────────────────────┐ │
│  │  Auth     │  │  Orders  │  │  15 Domain Modules     │ │
│  │  (3 JWT)  │  │  + State │  │  + Background Jobs     │ │
│  └──────────┘  │  Machine │  └────────────────────────┘ │
│                └──────────┘                               │
└───────────────┬──────────────────────┬──────────────────┘
                │                      │
                ▼                      ▼
┌──────────────────────┐  ┌──────────────────────┐
│  PostgreSQL 16       │  │  Redis 7             │
│  (Docker Volume)     │  │  (Docker)            │
│  Data persist        │  │  Cache-aside         │
└──────────────────────┘  └──────────────────────┘
```

### Auto-Fetch Tunnel URL

Flutter app fetch URL dari GitHub saat startup:

```
1. GET https://raw.githubusercontent.com/fannndi/service-hub/main/tunel.txt
2. Berhasil? → pakai URL itu
3. Gagal 3x? → cek cache
4. Cache ada? → pakai cache
5. Tidak ada? → maintenance mode
```

---

## Dalam Satu Lihat

| Aktor | Login | Dashboard |
|---|---|---|
| **Pelanggan** | `/login` — HP + password | Home: ringkasan order, kupon, garansi |
| **Admin Toko** | `/store-login` — HP + password | Dashboard: order, inventori, pembayaran, analitik |
| **Admin Platform** | `/admin/login` — username + password | Buat toko, kelola akun toko |

---

## Sorotan Teknis

- **Tiga sistem auth terpisah** — Customer JWT, Store Admin JWT, Platform Admin JWT
- **Stealth account** — Pelanggan booking tanpa daftar, akun dibuat otomatis
- **Matching engine** — Auto-filter toko by brand, model, sparepart, stock tersedia
- **Multi-step booking** — 5 langkah: device → kerusakan → match toko → data diri → booking
- **State machine order** — 11 status transisi dengan validasi ketat, SLA timer per status
- **Atomic stock operations** — Sparepart qty ops pakai `$queryRawUnsafe` — race condition safe
- **Session invalidation** — Store admin sessions di-track & invalidate on change-password/logout
- **Real-time tracking** — Polling 30 detik, pelanggan lihat progress perbaikan
- **Background jobs** — SLA monitor auto-cancel, credential cleaner (via `@nestjs/schedule`)
- **Kupon reward otomatis** — Pelanggan dapat Rp10.000 setiap beri ulasan
- **Security audited** — IDOR protection, stock over-commitment guard, rate limiting
- **175+ tests** — 152 backend (12 suites) + 23 frontend, 30/30 PRD acceptance criteria
- **Cloudflare Tunnel** — Deploy instan tanpa VPS, auto-fetch URL dari GitHub

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
- **Sesi** — Lihat & revoke active sessions

### Sisi Admin Toko
- **Dashboard** — Analitik 30 hari: total order, pendapatan, rating rata-rata
- **Order** — Terima, diagnosa, ganti sparepart, update status per langkah
- **Tracking** — Timeline progress, tambah entry manual
- **Pembayaran** — Konfirmasi pembayaran + lihat bukti transfer
- **Inventori** — Kelola stok sparepart, tambah/edit/hapus
- **Pelanggan** — Lihat daftar pelanggan + panel kredensial akun baru
- **Dispute** — Tangani klaim garansi, setujui/tolak

### Sisi Admin Platform
- **Buat Toko** — Input nama, alamat, admin toko, password
- **Daftar Toko** — Lihat semua toko

---

## Project Structure

```
service-hub/
├── backend/                     NestJS API
│   ├── src/modules/
│   │   ├── auth/                Customer auth + stealth account
│   │   ├── store-auth/          Store admin auth + session management
│   │   ├── platform-admin/      Platform admin auth + store creation
│   │   ├── users/               /me endpoints
│   │   ├── stores/              Store listing + matching engine
│   │   ├── orders/              Order CRUD + atomic state machine
│   │   ├── spareparts/          Sparepart inventory
│   │   ├── payments/            Payment + confirmation
│   │   ├── reviews/             Reviews + coupon rewards
│   │   ├── disputes/            Dispute + warranty claims + stock reservation
│   │   ├── notifications/       WhatsApp + email notifications
│   │   ├── uploads/             S3 presigned uploads
│   │   └── jobs/                SLA monitor + credential cleaner
│   ├── prisma/                  22 models + 20+ enums + seed
│   └── Dockerfile               Multi-stage production build
│
├── frontend/                    Flutter mobile app (3 roles)
│   └── lib/
│       ├── core/                Config, auto-fetch URL, address system
│       ├── network/             Dio client + token refresh mutex
│       ├── shared_widgets/      StatusBadge, ErrorState, EmptyState, Formatters
│       ├── storage/             Secure token storage
│       └── features/
│           ├── customer/        26 screens, 11 repositories
│           ├── store_admin/     14 screens, responsive layout
│           └── platform_admin/  2 screens
│
├── docs/                        Documentation
├── secrets/                     .env files (gitignored, shared manually)
├── tunel.txt                    Cloudflare tunnel URL (auto-fetched by Flutter)
├── docker-compose.yml           Local dev: Postgres + Redis + Backend
├── render.yaml                  One-click Render deployment
└── switch-env.sh                Switch local/production env
```

---

## Docker & Environment

### Local Development (Docker)

```bash
# Start all services
docker compose up -d --build

# View logs
docker compose logs -f backend

# Stop (data persists via volume)
docker compose down

# Fresh start (deletes data)
docker compose down -v
```

### Environment Switching

```bash
# Switch to local (Docker PostgreSQL)
./switch-env.sh local

# Switch to production (Supabase)
./switch-env.sh production

# Check current environment
./switch-env.sh status
```

### Docker Hostname Fix

Setelah `switch-env.sh`, fix hostnames untuk Docker networking:

```bash
# DATABASE_URL: postgres:5432 (bukan localhost:5432)
sed -i 's|@localhost:5432/|@postgres:5432/|' .env

# REDIS_HOST: redis (bukan localhost)
sed -i 's|REDIS_HOST=localhost|REDIS_HOST=redis|' .env
```

### Data Persistence

Data PostgreSQL tersimpan di Docker **named volume** (`service-hub_postgres_data`). Data persist meskipun:
- Container di-stop (`docker compose down`)
- Container di-restart
- WSL di-restart

Data hanya hilang jika:
- `docker compose down -v` (hapus volume secara eksplisit)

---

## Cloudflare Tunnel

Cloudflare Tunnel memungkinkan HP connect ke backend dari **mana saja** tanpa VPS.

### Cara Kerja

```
1. cloudflared tunnel → URL publik (contoh: https://abc.trycloudflare.com)
2. URL ditulis ke tunel.txt → commit + push ke GitHub
3. Flutter app fetch tunel.txt saat startup (3x retry)
4. HP otomatis pakai URL baru — tanpa rebuild APK
```

### Workflow

```bash
# Laptop:
cloudflared tunnel --url http://localhost:3000
# Catat URL yang muncul

# Update tunel.txt:
echo "https://abc.trycloudflare.com/v1" > tunel.txt
git add tunel.txt && git commit -m "tunnel: abc" && git push

# Flutter app (di HP) otomatis detect URL baru
```

### Auto-Fetch Logic (Flutter)

```dart
// app_config.dart
// 1. Fetch https://raw.githubusercontent.com/.../tunel.txt
// 2. 3x retry dengan 2 detik delay
// 3. Simpan ke SharedPreferences sebagai cache
// 4. Kalau gagal 3x + tidak ada cache → maintenance mode
```

---

## API Endpoints

### `/v1` — Customer & Public

| Method | Endpoint | Auth |
|--------|----------|------|
| POST | `/auth/login` | Public |
| POST | `/auth/change-password` | Customer |
| GET | `/me`, `/me/summary`, `/me/orders` | Customer |
| GET | `/stores`, `/stores/match` | Public |
| POST | `/orders` | Public (stealth) |
| POST | `/orders/:id/approve`, `/:id/reject` | Customer |
| POST | `/orders/:id/payments`, `/:id/reviews` | Customer |

### `/v1/store` — Admin Toko

| Method | Endpoint | Auth |
|--------|----------|------|
| POST | `/auth/login`, `/auth/refresh` | Public/Session |
| POST | `/auth/change-password`, `/auth/logout` | Store |
| GET | `/orders`, `/orders/:id` | Store |
| POST | `/orders/:id/diagnosis`, `/orders/:id/tracking` | Store |
| GET/POST/PATCH/DELETE | `/spareparts` | Store |
| GET | `/dashboard/summary`, `/analytics` | Store |
| POST | `/disputes/:id/respond` | Store |

### `/v1/platform` — Admin Platform

| Method | Endpoint | Auth |
|--------|----------|------|
| POST | `/login` | Public |
| POST | `/stores`, GET `/stores` | Admin |

---

## Deployment

### Option 1: Cloudflare Tunnel (Instant)

Tidak perlu VPS. Backend jalan di Docker, expose via tunnel. Lihat [Cloudflare Tunnel](#cloudflare-tunnel).

### Option 2: Render (Free Tier)

```bash
# Fork repo, set env vars di Render Dashboard, deploy
# render.yaml sudah tersedia di root project
```

### Option 3: VPS

```bash
# Clone repo
git clone https://github.com/fannndi/service-hub.git
cd service-hub

# Setup
./switch-env.sh production
# Edit .env: isi Supabase connection string, JWT secrets, dll.
sed -i 's|@localhost:5432/|@postgres:5432/|' .env
sed -i 's|REDIS_HOST=localhost|REDIS_HOST=redis|' .env

# Deploy
docker compose up -d --build
docker compose exec backend npx prisma db push
docker compose exec backend npx prisma db seed
```

---

## Documentation

| Dokumen | Isi |
|---------|-----|
| [docs/run-guide.md](docs/run-guide.md) | Panduan menjalankan (Docker + Non-Docker) |
| [docs/architecture.md](docs/architecture.md) | Detail arsitektur sistem |
| [docs/deployment.md](docs/deployment.md) | Deployment guide (Render, VPS) |
| [docs/backend/](docs/backend/) | 5 backend reference docs |
| [docs/frontend/](docs/frontend/) | 5 frontend reference docs |
| [docs/PRD/](docs/PRD/) | Product Requirements Documents |
| [CHANGELOG.md](CHANGELOG.md) | Riwayat perubahan |

---

## Changelog

Lihat [CHANGELOG.md](CHANGELOG.md) untuk riwayat lengkap. Highlights terbaru:

- **2026-06-19** — Race condition fixes, session invalidation, frontend audit, Cloudflare tunnel auto-fetch
- **2026-06-17** — Precision audit, security fixes, 30 AC integration tests (175 tests)

---

<p align="center">
  <b>ServisGadget</b> — Siap deploy tanpa VPS, connect dari mana saja.
</p>
