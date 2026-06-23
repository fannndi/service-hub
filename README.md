# ServisGadget

> Platform Marketplace Servis Gadget Dua Sisi — Backendless dengan Supabase

---

## Tech Stack

| Layer | Tech |
|-------|------|
| Backend | NestJS 10+ (TypeScript) + Prisma ORM + Supabase (PostgreSQL + Auth + Edge Functions) |
| Frontend | Flutter 3.4+, Dart 3, Riverpod 2.6, GoRouter 14, Supabase Flutter |
| Auth | Supabase Auth — 3 roles (customer, store_admin, platform_admin) |
| Storage | Supabase Storage |
| Infra | Docker Compose (Postgres + Redis + Backend) |

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
├── backend/                     NestJS API server
│   ├── prisma/                  Prisma schema & migrations
│   ├── src/
│   │   ├── main.ts              Bootstrap (Swagger, CORS, validation)
│   │   ├── app.module.ts        Root module
│   │   ├── config/              App configuration (JWT, SLA, storage)
│   │   └── common/              Shared infrastructure
│   │       ├── prisma/          PrismaClient wrapper
│   │       ├── exceptions/      23 exception classes (1 per file)
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
│       ├── orders/              12 files (creation, diagnosis, status, query, tracking)
│       ├── payments/            4 files (customer + store controllers)
│       ├── disputes/            4 files (customer + store controllers)
│       ├── reviews/             3 files
│       ├── spareparts/          3 files
│       ├── uploads/             3 files
│       ├── notifications/       3 files
│       ├── platform-admin/      7 files (auth, store, user, mgmt services)
│       ├── redis/               2 files
│       └── jobs/                3 files (SLA monitor, credential cleaner)
│
├── frontend/                    Flutter mobile app
│   └── lib/
│       ├── main.dart            App entry, GoRouter, splash
│       ├── core/                SupabaseService, Config, JSON helpers
│       ├── ui/                  Theme (Material 3), design system widgets
│       ├── shared_widgets/      Cross-feature reusable widgets
│       └── features/            Domain-driven feature modules
│           ├── customer/
│           │   ├── application/ 10 provider files (1 per concern)
│           │   ├── data/        9 repository files (1 per domain)
│           │   ├── domain/      15 model files (1 per class)
│           │   └── presentation/
│           │       ├── routing/ 1 router
│           │       ├── screens/ 22 screen files (1 per screen)
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
