# service-hub (ServisGadget) — True Serverless

**Stack:** Flutter + Supabase (Auth + DB + Edge Functions + Storage)
**Arsitektur:** 100% serverless — no NestJS, no Docker, no VPS
**Status:** Production-ready (175 tests passing)

## Architecture

```
Flutter App ──┬── Supabase Auth (login 3 roles)
              ├── Supabase DB (langsung via RLS)
              │     └── 15 migrations, 12 tables
              ├── Edge Functions (11 functions)
              │     ├── guest     — Booking tanpa auth + tracking
              │     ├── orders    — Order lifecycle + auto-activate guest
              │     ├── payments  — Payment CRUD + konfirmasi
              │     ├── midtrans  — Midtrans Snap token + webhook
              │     ├── disputes  — Klaim garansi
              │     ├── reviews   — Review + rating
              │     ├── notifications — In-app + WA gateway
              │     ├── admin     — Platform admin ops
              │     ├── store-applications — Registrasi toko
              │     └── cron-sla  — SLA monitoring auto-cancel
              └── Supabase Storage (upload payment proof, avatar)
```

## Features

| Role | Screens | Description |
|------|---------|-------------|
| Customer | 27 | Booking, orders, guest tracking, payments, reviews, disputes |
| Store Admin | 16 | Dashboard, order management, inventory, payments, analytics |
| Platform Admin | 2 | Login + dashboard, store management |

## Order State Machine (11 states)

```
pending → waiting_device → device_received → diagnosing → waiting_approval
→ waiting_sparepart → repairing → quality_check → waiting_payment
→ completed → [disputed → resolved/cancelled]
```

Setiap transisi divalidasi di Edge Function `shared/helpers.ts`. SLA 24h per stage.

## Auth (3 roles via Supabase Auth)

| Role | Email Format | Example |
|------|-------------|---------|
| Customer | `{phone}@customer.servisgadget.com` | `081234@customer.servisgadget.com` |
| Store Admin | `{phone}@store.servisgadget.com` | `081234@store.servisgadget.com` |
| Platform Admin | `{username}@servisgadget.com` | `admin@servisgadget.com` |

Guest users (belum punya akun) bisa booking via Edge Function `guest`. Akun otomatis dibuat pas booking, diaktifkan pas store terima device.

## Edge Functions

| Function | Auth | Action |
|----------|------|--------|
| `guest` | None | `create-order`, `track`, `credentials` |
| `orders` | User JWT | `orders`, `approve`, `reject`, `diagnosis`, `status` |
| `payments` | User JWT | `create`, `confirm` |
| `midtrans` | None | Snap token + webhook |
| `notifications` | User JWT | CRUD notifikasi in-app |
| `disputes` | User JWT | Klaim garansi |
| `reviews` | User JWT | Kirim + lihat review |
| `admin` | User JWT | Create store, manage users |
| `store-applications` | None | Pendaftaran toko |
| `cron-sla` | None | Auto-cancel SLA breach |

## Deployment

```bash
supabase link --project-ref eboplbemgtvmviwhdlfa
supabase db push
supabase functions deploy orders guest payments midtrans disputes reviews notifications admin store-applications cron-sla
```

```bash
cd frontend
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://eboplbemgtvmviwhdlfa.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_xxxx
```

## Play Store

APK signing ready (`key.properties` + `keystore.jks`). ProGuard enabled. Package: `com.ti23a4.serviceme`. Build appbundle:

```bash
flutter build appbundle --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

Upload `app-release.aab` ke Play Console. Biaya $25 developer fee (sekali).

## Files Referenced

- `frontend/lib/` — 27 customer screens + 16 store screens + 2 admin screens
- `supabase/functions/` — 11 Edge Functions
- `supabase/migrations/` — 15 SQL migrations
- `docs/PRD/00_MASTER_PRD.md` — Product requirements
- `docs/testing/verification-report.md` — 175 test results
