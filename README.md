# ServisGadget

> Platform Marketplace Servis Gadget Dua Sisi
>
> UAS Team Project — fannndi, dryns, Nisa Aulia.

## Tech Stack

| Layer | Tech |
|-------|------|
| Backend | Supabase (Edge Functions + PostgreSQL + Auth + Storage) — Serverless |
| Frontend | Flutter 3.4+, Dart 3, Riverpod 2.6, GoRouter 14, Supabase Flutter |
| Auth | Supabase Auth — 3 roles (customer, store_admin, platform_admin) |
| Payments | Midtrans Sandbox (via Supabase Edge Function) |
| Storage | Supabase Storage |
| Infra | Supabase (serverless) — no Docker/NestJS needed |

---

## Quick Start

```bash
# 1. Clone
git clone https://github.com/fannndi/service-hub.git && cd service-hub

# 2. Deploy Edge Functions + DB
#    a) Link project + deploy functions:
#       npx supabase login
#       npx supabase link --project-ref eboplbemgtvmviwhdlfa
#       npx supabase secrets set MIDTRANS_SERVER_KEY=Mid-server-xxx
#       npx supabase functions deploy orders disputes payments admin guest midtrans reviews notifications store-applications cron-sla
#       npx supabase db push
#    b) Atau jalankan SQL manual via Supabase Dashboard:
#       https://supabase.com/dashboard/project/eboplbemgtvmviwhdlfa/sql/new
#       jalankan file di supabase/migrations/ urut
#       supabase/migrations/002_rls.sql
#       supabase/migrations/003_functions.sql
#       supabase/migrations/004_seed.sql

# 3. Deploy Edge Functions
supabase login
supabase link --project-ref eboplbemgtvmviwhdlfa
supabase functions deploy orders
supabase functions deploy payments
supabase functions deploy disputes
supabase functions deploy admin
supabase functions deploy cron-sla

# 4. Build APK
cd frontend
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://eboplbemgtvmviwhdlfa.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_sLbPJCOjGT9GRZBosGlsQ_4cpeOMRV \
  --dart-define=API_BASE_URL=http://localhost:3000/v1

# 5. Install di HP → buka apps
```

---

## Guest Account Flow

Aplikasi ini punya mekanisme **guest account** seperti game — user bisa langsung booking tanpa login:

```
User → [Ajukan Servis]
  → Isi form (device, keluhan, toko, nama, no hp)
  → Submit → NestJS POST /v1/orders (no auth)
     → autoCreateAccount() → Prisma user = SUSPENDED + credential encrypted
     → Order dibuat, link ke user
  → [GuestBookingSuccessScreen] → catat nomor order

User → [Cek Pesanan] (dari welcome atau langsung)
  → Input nomor order + WhatsApp
  → NestJS POST /v1/orders/guest/track
  → Lihat tracking + credential (masked)
  → Jika status < device_received:
       "Menunggu toko menerima perangkat..."
       Credential card: nama, username (phone), password (masked)
       Tombol "Hubungkan Akun" disabled
  → Jika status >= device_received:
       Akun otomatis aktif + sync ke Supabase Auth
       User bisa login via Supabase Auth normal

[Store Admin] → terima device → POST /v1/store/orders/:id/status { status: device_received }
  → Backend activateGuestAccount():
     1. Decrypt credential dari Prisma
     2. Panggil Supabase Admin API → create Auth user
        email: {phone}@customer.servisgadget.com
        password: auto-generated
     3. Prisma user: accountStatus = active, credentialPlainEnc = null
     4. WhatsApp notif: "Akun aktif! Login dengan..."
```

### Key Components

| Component | File | Fungsi |
|-----------|------|--------|
| `CredentialService` | `auth/credential.service.ts` | Auto-create account → set status `suspended` |
| `GuestOrdersService` | `orders/guest-orders.service.ts` | Verify tracking, activate account, sync ke Supabase Auth |
| `GuestOrdersController` | `orders/guest-orders.controller.ts` | Public endpoints: track, credentials, activate |
| `OrderStatusService` | `orders/order-status.service.ts` | Hook: on `device_received` → activate guest account |
| `GuestBookingSuccessScreen` | `frontend/.../guest_booking_success_screen.dart` | Booking success tanpa login |
| `GuestTrackingScreen` | `frontend/.../guest_tracking_screen.dart` | Tracking + credential card + CTA login |
| `ApiClient` | `frontend/core/api_client.dart` | HTTP client ke NestJS backend |

### Endpoints

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| `POST` | `/v1/orders` | No | Guest order creation (auto-create suspended account) |
| `POST` | `/v1/orders/guest/track` | No | Tracking + status by orderNumber + phone |
| `POST` | `/v1/orders/guest/credentials` | No | Get credential status (masked password) |
| `POST` | `/v1/orders/guest/:orderId/activate` | Store Admin | Activate guest account (hook from device_received) |

### Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│                      WELCOME SCREEN                      │
│  [Ajukan Servis]  [Cek Pesanan]  [Pelanggan]  [Toko]    │
└──────────┬──────────────────┬────────────────────────────┘
           │                  │
     Ajukan Servis      Cek Pesanan
           │                  │
           ▼                  ▼
  ┌─────────────────┐  ┌──────────────────┐
  │ Service Flow    │  │ Guest Tracking   │
  │ (5-step wizard) │  │ (order+phone)    │
  └────────┬────────┘  └────────┬─────────┘
           │                    │
     POST /v1/orders       POST /v1/orders/guest/track
     (no auth)                  │
           │                    ├── status < device_received
           ▼                    │   → card credential (disabled)
  ┌────────────────────┐        │
  │ Booking Success    │        ├── status >= device_received
  │ (catat order no)   │        │   → "Akun Aktif, Silakan Login"
  └────────────────────┘        │
                                ▼
                         ┌──────────────┐
                         │ Login Screen │
                         │ (Supabase)   │
                         └──────────────┘

  ┌─────────────────────────────────────────────────────┐
  │              STORE ADMIN SIDE                        │
  │                                                     │
  │  Menerima device → POST /v1/store/orders/:id/status │
  │  { status: "device_received" }                      │
  │       ↓                                              │
  │  OrderStatusService.updateStatus()                   │
  │       ↓                                              │
  │  GuestOrdersService.activateGuestAccount()           │
  │      1. Decrypt credential                            │
  │      2. Create Supabase Auth user via Admin API       │
  │      3. Set accountStatus = active                    │
  │      4. WA notif ke customer                          │
  └─────────────────────────────────────────────────────┘
```

---

## Login

| Role | Email Format | Password |
|------|-------------|----------|
| Platform Admin | `admin@admin.servisgadget.com` | `admin` |
| Store Admin | `{phone}@store.servisgadget.com` | Dibuat dari platform admin |
| Customer | `{phone}@customer.servisgadget.com` | Auto-generated saat guest booking, diaktifkan saat toko approve |

---

## Project Structure

```
service-hub/
├── backend/                     NestJS API server
│   ├── prisma/                  Prisma schema & migrations
│   ├── src/
│   │   ├── main.ts              Bootstrap (Swagger, CORS, validation)
│   │   ├── app.module.ts        Root module
│   │   ├── config/              App configuration (JWT, SLA, storage, Supabase)
│   │   └── common/              Shared infrastructure
│   │       ├── prisma/          PrismaClient wrapper
│   │       ├── exceptions/      24 exception classes (1 per file)
│   │       ├── guards/          JWT auth guards
│   │       ├── filters/         Global exception filter
│   │       ├── interceptors/    Response wrapper
│   │       ├── decorators/      @GetUser() param decorator
│   │       ├── types/           JWT payload types
│   │       ├── logger/          Pino logger module
│   │       ├── utils/           Phone, password, encryption, nanoid
│   │       ├── health.controller.ts
│   │       └── config.controller.ts
│   └── modules/                 Feature modules (1 class = 1 file)
│       ├── auth/                4 files (auth, credential services)
│       ├── users/               3 files
│       ├── stores/              6 files (discovery, dashboard, profile)
│       ├── store-auth/          4 files
│       ├── store-register/      3 files
│       ├── orders/              15 files (creation, diagnosis, status, query, tracking, guest)
│       ├── payments/            4 files (customer + store controllers)
│       ├── disputes/            4 files (customer + store controllers)
│       ├── reviews/             3 files
│       ├── spareparts/          3 files
│       ├── uploads/             3 files
│       ├── notifications/       5 files (wa, email, in-app, controller)
│       ├── platform-admin/      7 files (auth, store, user, mgmt services)
│       ├── redis/               2 files
│       └── jobs/                3 files (SLA monitor, credential cleaner)
│
├── frontend/                    Flutter mobile app
│   └── lib/
│       ├── main.dart            App entry, GoRouter, splash
│       ├── core/                SupabaseService, ApiClient, Config, JSON helpers
│       ├── ui/                  Theme (Material 3), design system widgets
│       ├── shared_widgets/      Cross-feature reusable widgets
│       └── features/            Domain-driven feature modules
│           ├── customer/
│           │   ├── application/ 10 provider files (1 per concern)
│           │       ├── data/        9 repository files (1 per domain, notifications via Supabase)
│           │   ├── domain/      15 model files (1 per class)
│           │   └── presentation/
│           │       ├── routing/ 1 router (25 routes)
│           │       ├── screens/ 25 screen files (1 per screen, includes guest*)
│           │       └── widgets/ 11 widget files (1 per widget)
│           ├── store_admin/
│           │   ├── application/ 11 provider files
│           │   ├── data/        10 repository files
│           │   ├── domain/      14 model files
│           │   └── presentation/
│           │       ├── routing/ 1 router
│           │       ├── screens/ 16 screen files
│           │       └── widgets/ 15 widget files
│           └── platform_admin/
│               ├── application/ 3 provider files
│               ├── data/        4 repository files
│               ├── domain/      6 model files
│               └── presentation/
│                   ├── routing/ 1 router
│                   └── screens/ 2 screen files
│
├── supabase/                    Supabase SQL + Edge Functions
│   ├── migrations/              SQL schema, RLS, functions, seed
│   └── functions/               Edge Functions (orders, payments, disputes, admin, cron-sla)
│
├── scripts/                     Deployment helpers
├── docker-compose.yml           Postgres + Redis + Backend
└── docs/                        PRD, architecture, changelog
```

**Modularity principle:** 1 class = 1 file. Every controller, service, DTO, repository, provider, model, and widget gets its own file. Barrel files re-export for backward-compatible imports.

---

## Backend Architecture

**Dual-layer architecture:**

| Layer | Lokasi | Fungsi |
|-------|--------|--------|
| Auth & Queries | Supabase (Auth + RLS + DB) | Customer login, order tracking, store discovery |
| Business Logic | NestJS + Prisma | Order creation, guest account, store admin ops, credentials |
| Edge Functions | Supabase Functions | Order flow, stock management, disputes |
| Cache | Redis | Session, rate limiting |

### NestJS API Endpoints

| Prefix | Controller | Auth |
|--------|-----------|------|
| `POST /v1/orders` | OrdersController | No (guest order) |
| `GET /v1/orders/me` | OrdersController | Customer JWT |
| `GET /v1/orders/:id` | OrdersController | Customer JWT |
| `POST /v1/orders/guest/track` | GuestOrdersController | No |
| `POST /v1/orders/guest/credentials` | GuestOrdersController | No |
| `POST /v1/orders/guest/:orderId/activate` | GuestOrdersController | Store Admin JWT |
| `GET /v1/notifications` | NotificationsController | Customer JWT |
| `GET /v1/notifications/unread-count` | NotificationsController | Customer JWT |
| `PATCH /v1/notifications/:id/read` | NotificationsController | Customer JWT |
| `PATCH /v1/notifications/read-all` | NotificationsController | Customer JWT |
| `POST /v1/notifications/test` | NotificationsController | Customer JWT |
| `POST /v1/notifications/broadcast` | NotificationsController | Platform Admin |
| `GET /v1/store/notifications` | StoreNotificationsController | Store Admin JWT |
| `PATCH /v1/store/notifications/:id/read` | StoreNotificationsController | Store Admin JWT |
| `POST /v1/store/notifications/test` | StoreNotificationsController | Store Admin JWT |
| `POST /v1/auth/login` | AuthController | No |
| `POST /v1/store/orders/*` | StoreOrdersController | Store Admin JWT |

---

## Notification System

Aplikasi punya **dual notification channel**: WhatsApp (external) + In-App (internal).

### In-App Notifications

| Event | Target | Type | Trigger |
|-------|--------|------|---------|
| Order created | Store Admin | `new_order` | `order-creation.service.ts` |
| Device received | Customer | `device_received` | `order-status.service.ts` |
| Diagnosing | Customer | `diagnosing` | `order-status.service.ts` |
| Diagnosis ready | Customer | `diagnosis_result` | `order-diagnosis.service.ts` |
| Order approved | Store Admin | `order_approved` | `order-diagnosis.service.ts` |
| Repair started | Customer | `repairing` | `order-status.service.ts` |
| Quality check | Customer | `quality_check` | `order-status.service.ts` |
| Waiting payment | Customer | `waiting_payment` | `order-status.service.ts` |
| Payment confirmed | Both | `payment_confirmed` | `payments.service.ts` |
| Order completed | Customer | `completed` | `payments.service.ts` |
| Order cancelled | Customer | `cancelled` | `order-status.service.ts` |
| Account activated | Customer | `account_activated` | `guest-orders.service.ts` |
| Broadcast | All | `broadcast` | Admin dashboard |
| Test | Self | `test` | Test button |

### Backend API

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| `GET` | `/v1/notifications` | Customer JWT | List notifikasi pelanggan |
| `GET` | `/v1/notifications/unread-count` | Customer JWT | Badge count |
| `PATCH` | `/v1/notifications/:id/read` | Customer JWT | Mark one as read |
| `PATCH` | `/v1/notifications/read-all` | Customer JWT | Mark all read |
| `POST` | `/v1/notifications/test` | Customer JWT | Test notification |
| `POST` | `/v1/notifications/broadcast` | Platform Admin | Broadcast to role |
| `GET` | `/v1/store/notifications` | Store JWT | List notifikasi toko |
| `GET` | `/v1/store/notifications/unread-count` | Store JWT | Badge count |
| `PATCH` | `/v1/store/notifications/:id/read` | Store JWT | Mark one read |
| `POST` | `/v1/store/notifications/test` | Store JWT | Test notification |

### Frontend Badge

- Customer: badge on bell icon in AppBar (HomeScreen)
- Store Admin: badge on bell icon in AppBar (StoreAdminScaffold)
- Auto-refresh setiap 30s
- Mark as read otomatis saat notifikasi ditekan
- Deep link ke halaman order terkait

### Database

Table `notifications`:
- `id, user_id, store_id, role, title, message, type, is_read, link_to, created_at`
- RLS: customer hanya lihat miliknya, store admin lihat per store
- Migration: `supabase/migrations/005_notifications.sql`

### WhatsApp Notifications (existing)

| Method | messageType | Recipient |
|--------|-------------|-----------|
| `sendNewOrderToStore()` | `new_order`, `stealth_account` | Store + Customer |
| `sendWaitingPayment()` | `waiting_payment` | Customer |
| `sendDiagnosisResult()` | `diagnosis_result` | Customer |
| `sendOrderCompleted()` | `order_completed` | Customer |
| `send()` (generic) | `order_approved`, `sla_*`, `dispute_*`, `account_activated` | Various |

---

## Edge Functions

| Function | Auth | Fungsi |
|----------|------|--------|
| `orders` | User JWT | Buat/approve/reject/diagnosis/update status |
| `payments` | User JWT | Konfirmasi pembayaran |
| `disputes` | User JWT | Resolusi klaim garansi |
| `admin` | User JWT | Buat toko baru (platform admin) |
| `cron-sla` | None | Auto-cancel SLA breach + credential cleanup |

---

## Environment Variables

### Required (backend)

| Variable | Deskripsi |
|----------|-----------|
| `DATABASE_URL` | PostgreSQL connection string |
| `JWT_ACCESS_SECRET` | Customer JWT access token secret |
| `JWT_REFRESH_SECRET` | Customer JWT refresh token secret |
| `JWT_STORE_ACCESS_SECRET` | Store admin JWT access secret |
| `JWT_STORE_REFRESH_SECRET` | Store admin JWT refresh secret |
| `JWT_PLATFORM_ADMIN_SECRET` | Platform admin JWT secret |
| `CREDENTIAL_ENCRYPTION_KEY` | AES-256-GCM key for guest credentials (32-byte hex) |
| `MIDTRANS_SERVER_KEY` | Midtrans payment server key |
| `SUPABASE_PROJECT_REF` | Supabase project ref (for Admin API) |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service_role key (for guest sync) |

### Frontend build args

| Arg | Default | Deskripsi |
|-----|---------|-----------|
| `SUPABASE_URL` | `''` | Supabase project URL |
| `SUPABASE_ANON_KEY` | `''` | Supabase anon key |
| `API_BASE_URL` | `http://localhost:3000/v1` | NestJS backend URL |

---

## Workflow Skenario

### Skenario 1: Guest Booking + Activation (Happy Path)

1. User buka app → tap **Ajukan Servis**
2. Pilih device (brand + model), jenis kerusakan, pilih toko, isi nama & WA
3. Tap **Booking** → order terkirim via NestJS API
4. System auto-generate credential (password random), user status = **suspended**
5. Muncul **GuestBookingSuccessScreen** dengan nomor order
6. User tap **Cek Status Pesanan** → masuk **GuestTrackingScreen**
7. Input nomor order + WA → lihat tracking + **credential card (disabled)**
8. Store admin terima device → update status → `device_received`
9. Backend otomatis activate guest account:
   - Buat Supabase Auth user (`{phone}@customer.servisgadget.com`)
   - Set `accountStatus = active` di Prisma
   - Kirim notif WA: "Akun aktif!"
10. User refresh tracking → credential card berubah jadi **"Akun Aktif, Silakan Login"**
11. User tap **Login** → login via Supabase Auth dengan credential dari card

### Skenario 2: Guest — Store Belum Terima Device

1. User booking + dapat nomor order
2. Cek tracking → lihat status `waiting_device`
3. Credential card muncul tapi **disabled** + pesan "Menunggu toko menerima perangkat"
4. User harus tunggu sampai store admin update status

### Skenario 3: Customer Login (Existing User)

1. User tap **Pelanggan** → login screen
2. Input phone + password → login via Supabase Auth
3. Redirect ke **HomeScreen** dengan order history

### Skenario 4: Store Admin — Menerima Device + Auto-Activate

1. Store admin login, buka order detail
2. Tap **Terima Perangkat** → `POST /v1/store/orders/:id/status` dengan `device_received`
3. Backend `OrderStatusService.updateStatus()` hook:
   - Update status order
   - Panggil `GuestOrdersService.activateGuestAccount()`
   - Jika user punya `credentialPlainEnc` (guest): sync ke Supabase Auth + update status
4. Customer dapat notif WA akun aktif

---

## Deployment

### Backend (Docker Compose)

```bash
docker compose up -d
```

### Frontend (APK)

```bash
cd frontend
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://eboplbemgtvmviwhdlfa.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_sLbPJCOjGT9GRZBosGlsQ_4cpeOMRV \
  --dart-define=API_BASE_URL=http://YOUR_SERVER_IP:3000/v1
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## Documentation

| File | Content |
|------|---------|
| `docs/PRD/00_MASTER_PRD.md` | Master product requirements |
| `docs/architecture.md` | System architecture |
| `CHANGELOG.md` | Version history |
