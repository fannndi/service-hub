# ServisGadget

> Platform Marketplace Servis Gadget Dua Sisi — Backendless dengan Supabase

---

## Tech Stack

| Layer | Tech |
|-------|------|
| Backend | Supabase (PostgreSQL + Auth + Edge Functions) |
| Frontend | Flutter 3.4+, Dart 3, Riverpod 2.6, GoRouter 14, Supabase Flutter |
| Auth | Supabase Auth — 3 roles (customer, store_admin, platform_admin) |
| Storage | Supabase Storage |

---

## Quick Start

```bash
# 1. Clone
git clone https://github.com/fannndi/service-hub.git && cd service-hub

# 2. Setup backend (SQL + Edge Functions)
#    a) Buka Supabase SQL Editor:
#       https://supabase.com/dashboard/project/eboplbemgtvmviwhdlfa/sql/new
#    b) Copy-paste dan run urut:
#       supabase/migrations/001_init.sql
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
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_sLbPJCOjGT9GRGZBosGlsQ_4cpeOMRV

# 5. Install di HP → buka apps
```

---

## Login

| Role | Email Format | Password |
|------|-------------|----------|
| Platform Admin | `admin@admin.servisgadget.com` | `admin` |
| Store Admin | `{phone}@store.servisgadget.com` | Dibuat dari platform admin |
| Customer | `{phone}@customer.servisgadget.com` | Auto-created saat booking |

---

## Project Structure

```
service-hub/
├── supabase/
│   ├── migrations/              SQL schema + RLS + functions
│   │   ├── 001_init.sql         14 tables, 13 enums, indexes
│   │   ├── 002_rls.sql          50 RLS policies
│   │   ├── 003_functions.sql    Atomic stock, SLA, auth triggers
│   │   └── 004_seed.sql         Platform admin seed
│   ├── functions/               Edge Functions (Deno)
│   │   ├── orders/              Order state machine
│   │   ├── payments/            Payment confirmation
│   │   ├── disputes/            Warranty orders
│   │   └── admin/               Create store + SLA cron
│   └── config.toml              Supabase CLI config
│
├── frontend/                    Flutter mobile app
│   └── lib/
│       ├── core/                SupabaseService, Config
│       ├── ui/                  Theme, widgets (Material 3)
│       └── features/
│           ├── customer/        24 screens
│           ├── store_admin/     17 screens
│           └── platform_admin/  2 screens
│
├── scripts/                     Deployment helpers
│   ├── deploy.sh                One-command deploy guide
│   └── push-sql.js              SQL push via Management API
│
└── docs/                        Documentation
```

---

## Backend Architecture

**Tidak ada server — backendless.** Semua logic di:

| Layer | Lokasi | Fungsi |
|-------|--------|--------|
| Database | Supabase PostgreSQL | Data storage, RLS policies |
| Auth | Supabase Auth | 3 roles, JWT, session management |
| Business Logic | Edge Functions | Order flow, stock, disputes |
| Cache | Supabase DB cache-aside | Store list cache |

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

## Deployment

### Backend (Supabase)

1. **SQL Migrations** — via SQL Editor atau `node scripts/push-sql.js`
2. **Edge Functions** — `supabase functions deploy`

### Frontend (APK)

```bash
cd frontend
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://eboplbemgtvmviwhdlfa.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_sLbPJCOjGT9GRZBosGlsQ_4cpeOMRV
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## Documentation

| File | Content |
|------|---------|
| `docs/PRD/00_MASTER_PRD.md` | Master product requirements |
| `docs/architecture.md` | System architecture |
| `CHANGELOG.md` | Version history |
