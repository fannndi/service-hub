# ServisGadget

> Platform marketplace servis gadget dua sisi — **100% serverless. Tanpa VPS.**

## Tech Stack

| Layer | Tech | Biaya |
|-------|------|-------|
| Backend | Supabase (Edge Functions + PostgreSQL + Auth + Storage) | ✅ Free tier |
| Frontend | Flutter 3.4+, Dart 3, Riverpod 2.6, GoRouter 14 | ✅ Gratis |
| Auth | Supabase Auth — 3 roles (customer, store_admin, platform_admin) | ✅ Included |
| Payments | Midtrans via Edge Function | ✅ Per transaksi |
| Infra | **Tidak perlu server/Docker/NestJS** | **$0/bulan** |

---

## Quick Start (5 menit)

```bash
# 1. Clone
git clone https://github.com/fannndi/service-hub.git && cd service-hub

# 2. Deploy ke Supabase
npx supabase login
npx supabase link --project-ref eboplbemgtvmviwhdlfa
npx supabase db push                              # Migrate database
npx supabase functions deploy orders guest payments midtrans disputes reviews notifications admin store-applications cron-sla
npx supabase secrets set MIDTRANS_SERVER_KEY=xxx WA_GATEWAY_URL=xxx WA_GATEWAY_TOKEN=xxx

# 3. Build APK
cd frontend
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://eboplbemgtvmviwhdlfa.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_xxxx

# 4. Install APK ke HP
```

---

## Fitur

### 👤 Customer (27 layar)
Booking servis, lacak pesanan (tanpa login), upload pembayaran, review, klaim garansi.

### 🏪 Store Admin (16 layar)
Dashboard, manajemen order, diagnosis, inventory sparepart, payment confirmation, analytics.

### 🛡️ Platform Admin (2 layar)
Login + dashboard, kelola toko, manage users.

---

## Alur Utama: Guest Booking → Aktifasi Akun

Aplikasi ini punya mekanisme unik: **user bisa booking tanpa daftar akun**.

```
👤 User: Buka app → Ajukan Servis → Isi form → Booking
   ↓
⚡ Edge Function `guest` (action: create-order)
   ├── Auto-buat user di DB (status: suspended)
   ├── Generate password random
   └── Order tersimpan
   ↓
👤 User: Dapat nomor order → Lacak via Guest Tracking
   ↓
🏪 Store Admin: Terima device → Update status → `device_received`
   ↓
⚡ Edge Function `orders` (action: status)
   └── Auto-activate: create Supabase Auth user + WA notif
   ↓
👤 User: Akun aktif → Login pakai phone + password
```

**11 state order machine:**
```
pending → waiting_device → device_received → diagnosing → waiting_approval
→ waiting_sparepart → repairing → quality_check → waiting_payment
→ completed → [disputed → resolved/cancelled]
```

---

## Arsitektur

```
Flutter App ──┬── Supabase Auth (login 3 roles, native)
              ├── Supabase DB (langsung via RLS — SELECT/INSERT aman)
              ├── Edge Functions (11 function, business logic)
              │     ├── guest       — Booking tanpa auth
              │     ├── orders      — Order lifecycle + auto-activate
              │     ├── payments    — Payment CRUD
              │     ├── midtrans    — Midtrans Snap + webhook
              │     ├── disputes    — Klaim garansi
              │     ├── reviews     — Review + rating
              │     ├── notifications — In-app + WhatsApp
              │     ├── admin       — Platform admin
              │     ├── store-applications — Registrasi toko
              │     └── cron-sla    — Auto-cancel SLA breach
              └── Supabase Storage — Upload file (bukti bayar, avatar)
```

### Kenapa Serverless?

| Traditional | ServisGadget |
|-------------|-------------|
| Sewa VPS $5-20/bulan | **$0** — Supabase free tier |
| Install Node.js, Redis, Docker | **Tidak perlu** |
| Update OS, security patches | **Otomatis** oleh Supabase |
| Scaling manual | **Auto-scale** |
| Monitoring sendiri | **Built-in** dashboard |

---

## Auth 3 Role

| Role | Email Format | Login via |
|------|-------------|-----------|
| Customer | `{phone}@customer.servisgadget.com` | Supabase Auth |
| Store Admin | `{phone}@store.servisgadget.com` | Supabase Auth |
| Platform Admin | `{username}@servisgadget.com` | Supabase Auth |

Semua login pakai **Supabase Auth native** — tidak ada backend custom.

---

## Environment Variables

### Supabase Secrets (`supabase secrets set`)

| Variable | Kegunaan |
|----------|----------|
| `MIDTRANS_SERVER_KEY` | Midtrans payment server key |
| `MIDTRANS_CLIENT_KEY` | Midtrans client key |
| `WA_GATEWAY_URL` | WhatsApp gateway URL |
| `WA_GATEWAY_TOKEN` | WhatsApp gateway token |

### Flutter Build Args

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://eboplbemgtvmviwhdlfa.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_xxxx
```

---

## Deployment

### 1. Database + Edge Functions

```bash
supabase functions deploy orders guest payments midtrans disputes reviews notifications admin store-applications cron-sla
supabase db push
supabase secrets set MIDTRANS_SERVER_KEY=xxx
```

### 2. Build APK

```bash
cd frontend
flutter build apk --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### 3. Play Store

```bash
flutter build appbundle --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

Upload `app-release.aab` ke Play Console. Biaya: $25 developer fee (sekali).

---

## Testing

| Jenis | Jumlah | Status |
|-------|--------|--------|
| Backend unit | 57 | ✅ |
| Backend security | 30 | ✅ |
| Backend integration | 65 | ✅ |
| Frontend widget | 9 | ✅ |
| Frontend model | 14 | ✅ |
| **Total** | **175** | ✅ **ALL PASSING** |

---

## Project Structure

```
service-hub/
├── frontend/lib/                Flutter app (45 screens)
│   ├── features/customer/       Customer: 25 screens + 10 providers
│   ├── features/store_admin/    Store Admin: 16 screens + 11 providers
│   └── features/platform_admin/ Platform Admin: 2 screens
├── supabase/
│   ├── migrations/              15 SQL files (schema, RLS, functions)
│   └── functions/               11 Edge Functions
├── docs/                        PRD, architecture, testing report
└── scripts/                     Build helpers
```

---

## Docs

| File | Isi |
|------|-----|
| `docs/PRD/00_MASTER_PRD.md` | Product requirements |
| `docs/architecture.md` | System architecture |
| `docs/testing/verification-report.md` | 175 test results |
| `CHANGELOG.md` | Version history |
