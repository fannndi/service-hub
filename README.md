# ServisGadget

> Platform Marketplace Servis Gadget Dua Sisi — **100% Serverless**
>
> UAS Team Project — fannndi, dryns, Nisa Aulia.

## Tech Stack

| Layer | Tech |
|-------|------|
| Backend | **Supabase only** (Edge Functions + PostgreSQL + Auth + Storage) |
| Frontend | Flutter 3.4+, Dart 3, Riverpod 2.6, GoRouter 14, Supabase Flutter |
| Auth | Supabase Auth — 3 roles (customer, store_admin, platform_admin) |
| Payments | Midtrans (via Supabase Edge Function) |
| Storage | Supabase Storage |
| Infra | **Serverless** — no VPS, no Docker, no NestJS needed |

**Tidak perlu sewa server/VPS.** Semua jalan di Supabase free tier (500 MB DB, 50K Edge invocations/hari, 1 GB Storage).

---

## Quick Start

```bash
# 1. Clone
git clone https://github.com/fannndi/service-hub.git && cd service-hub

# 2. Deploy database + Edge Functions ke Supabase
npx supabase login
npx supabase link --project-ref eboplbemgtvmviwhdlfa
npx supabase db push                             # Migrate DB
npx supabase functions deploy orders              # Order lifecycle
npx supabase functions deploy guest               # Guest booking
npx supabase functions deploy payments            # Payment flow
npx supabase functions deploy midtrans            # Midtrans gateway
npx supabase functions deploy disputes            # Warranty
npx supabase functions deploy reviews             # Reviews
npx supabase functions deploy notifications       # Notifications
npx supabase functions deploy admin               # Admin ops
npx supabase functions deploy store-applications  # Store registration
npx supabase functions deploy cron-sla            # SLA monitoring
npx supabase secrets set MIDTRANS_SERVER_KEY=your-key
npx supabase secrets set WA_GATEWAY_URL=your-wa-url
npx supabase secrets set WA_GATEWAY_TOKEN=your-token

# 3. Build APK
cd frontend
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://eboplbemgtvmviwhdlfa.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_sLbPJCOjGT9GRZBosGlsQ_4cpeOMRV

# 4. Install APK ke HP
```

---

## Guest Account Flow

Aplikasi punya mekanisme **guest account** — user bisa booking tanpa login. Semua via Supabase Edge Function `guest/index.ts`:

```
User → [Ajukan Servis]
  → Isi form (device, keluhan, toko, nama, no hp)
  → Submit → Edge Function `guest` (action: 'create-order', no auth)
     → Auto-create user di Supabase DB (status: suspended)
     → Order dibuat
  → [GuestBookingSuccessScreen] → catat nomor order

User → [Cek Pesanan]
  → Input nomor order + WhatsApp
  → Edge Function `guest` (action: 'track', no auth)
  → Lihat status tracking

[Store Admin] → terima device
  → Edge Function `orders` (action: 'status', status: 'device_received')
  → autoActivateGuest() dipanggil:
     1. Create Supabase Auth user via Admin API
        email: {phone}@customer.servisgadget.com
        password: auto-generated
     2. Set account_status = active di DB
     3. WhatsApp notif
```

### Key Components

| Component | Lokasi | Fungsi |
|-----------|--------|--------|
| Guest Edge Function | `supabase/functions/guest/index.ts` | Create order, track, credentials (all no-auth) |
| Orders Edge Function | `supabase/functions/orders/index.ts` | Order lifecycle + auto-activate guest |
| `GuestBookingSuccessScreen` | `frontend/.../guest_booking_success_screen.dart` | Booking success |
| `GuestTrackingScreen` | `frontend/.../guest_tracking_screen.dart` | Tracking + credential card |

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
├── frontend/                    Flutter mobile app (45 screens)
│   └── lib/
│       ├── main.dart            App entry, GoRouter, splash
│       ├── core/                SupabaseService, Config, helpers
│       ├── ui/                  Theme (Material 3), widgets
│       ├── shared_widgets/      Cross-feature reusable widgets
│       └── features/
│           ├── customer/        Customer: booking, orders, payments, reviews
│           │   ├── application/ Riverpod providers
│           │   ├── data/        Repositories
│           │   ├── domain/      Models
│           │   └── presentation/25 screens
│           ├── store_admin/     Store: dashboard, orders, inventory
│           │   ├── application/ Providers
│           │   ├── data/        Repositories
│           │   ├── domain/      Models
│           │   └── presentation/16 screens
│           └── platform_admin/  Admin: login + dashboard
│               ├── application/ 3 providers
│               ├── data/        4 repositories
│               ├── domain/      6 models
│               └── presentation/2 screens
│
├── supabase/                    Supabase DB + Edge Functions (serverless)
│   ├── migrations/              15 SQL files (schema, RLS, functions, seed)
│   └── functions/               11 Edge Functions (orders, guest, payments, midtrans, dll)
│       └── _shared/             Cors, helpers, WhatsApp shared
│
├── scripts/                     Build helpers
└── docs/                        PRD, architecture, testing

**Serverless:** No backend server needed. Semua via Supabase (Auth + DB + Functions + Storage).
```

---

## Architecture

**True serverless — no backend server needed:**

| Layer | Lokasi | Fungsi |
|-------|--------|--------|
| Auth | Supabase Auth native | Login 3 roles (customer, store_admin, platform_admin) |
| Database | Supabase PostgreSQL | All tables + RLS per role |
| Business Logic | 11 Edge Functions | Order lifecycle, guest flow, payments, disputes |
| Payments | Edge Function `midtrans` | Midtrans Snap + webhook |
| Storage | Supabase Storage | File uploads (payment proof, avatars) |
| Notifications | Edge Function | In-app + WhatsApp gateway |

### Edge Functions API

| Function | Auth | Action | Fungsi |
|----------|------|--------|--------|
| `guest` | None | `create-order` | Guest booking (auto-create suspended user) |
| `guest` | None | `track` | Cek status by order number |
| `guest` | None | `credentials` | Lihat credential (masked) |
| `orders` | User JWT | `orders` | Buat order (customer) |
| `orders` | User JWT | `approve/reject` | Setujui/tolak diagnosa (customer) |
| `orders` | User JWT | `status` | Update status order (store admin) |
| `orders` | User JWT | `diagnosis` | Kirim diagnosa (store admin) |
| `payments` | User JWT | `create` | Upload bukti bayar |
| `payments` | User JWT | `confirm` | Konfirmasi bayar (store admin) |
| `midtrans` | None | — | Midtrans Snap token + webhook |
| `disputes` | User JWT | — | Klaim garansi |
| `reviews` | User JWT | — | Kirim review |
| `notifications` | User JWT | — | Notifikasi in-app + WA |
| `admin` | User JWT | — | Admin panel (create store, dll) |
| `store-applications` | None | — | Pendaftaran toko baru |
| `cron-sla` | None | — | Auto-cancel SLA breach |

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

### Supabase Edge Functions secrets (`supabase secrets set`)

| Variable | Deskripsi |
|----------|-----------|
| `MIDTRANS_SERVER_KEY` | Midtrans payment server key |
| `MIDTRANS_CLIENT_KEY` | Midtrans client key |
| `WA_GATEWAY_URL` | WhatsApp gateway URL |
| `WA_GATEWAY_TOKEN` | WhatsApp gateway token |
| `WA_SENDER_NUMBER` | Nomor pengirim WA |

### Frontend build args

| Arg | Contoh | Deskripsi |
|-----|--------|-----------|
| `SUPABASE_URL` | `https://eboplbemgtvmviwhdlfa.supabase.co` | Supabase project URL |
| `SUPABASE_ANON_KEY` | `sb_publishable_xxxx` | Supabase anon key |

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://eboplbemgtvmviwhdlfa.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_xxxx
```

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

### 1. Database + Edge Functions

```bash
supabase login
supabase link --project-ref eboplbemgtvmviwhdlfa
supabase db push
supabase functions deploy orders guest payments midtrans disputes reviews notifications admin store-applications cron-sla
supabase secrets set MIDTRANS_SERVER_KEY=xxx WA_GATEWAY_URL=xxx WA_GATEWAY_TOKEN=xxx
```

### 2. Build APK

```bash
cd frontend
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://eboplbemgtvmviwhdlfa.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_sLbPJCOjGT9GRZBosGlsQ_4cpeOMRV
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### 3. Publish ke Play Store

```bash
cd frontend
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

Upload `build/app/outputs/bundle/release/app-release.aab` ke Play Console.

**Biaya:** $0 — Supabase free tier + Play Store $25 developer fee (sekali).

---

## Documentation

| File | Content |
|------|---------|
| `docs/PRD/00_MASTER_PRD.md` | Master product requirements |
| `docs/architecture.md` | System architecture |
| `CHANGELOG.md` | Version history |
