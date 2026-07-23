# Service Me (ServisGadget)

> Gadget repair marketplace — 100% serverless on Supabase. No VPS, no Docker, no NestJS.

Platform dua sisi: customer booking servis gadget, store admin mengelola perbaikan, platform admin mengawasi toko.

---

## Tech Stack

| Layer | Tech |
|-------|------|
| Frontend | Flutter 3.4+, Dart 3, Riverpod 2.6, GoRouter 14 |
| Backend | Supabase (Edge Functions + Auth + PostgreSQL + Storage) |
| Auth | Supabase Auth — email-based, 3 roles |
| Payments | Midtrans Snap (sandbox) via Edge Function webhook |
| Push | Firebase Cloud Messaging |
| Crash | Firebase Crashlytics |
| Font | Google Fonts |

### Edge Functions (11)

| Function | Auth | Purpose |
|----------|------|---------|
| `guest` | None | Booking tanpa login, tracking guest, resend credentials |
| `orders` | JWT | Create order, diagnosis, approve/reject, status transitions |
| `payments` | JWT | Upload payment proof (customer), confirm payment (store admin) |
| `midtrans` | None | Generate Snap token, process Midtrans webhook |
| `disputes` | JWT | Create warranty claim, store accept/reject |
| `reviews` | JWT | Create review + auto-generate coupon reward |
| `notifications` | JWT | Broadcast to role, send email (platform admin only) |
| `admin` | JWT | Approve stores, manage users, delete accounts |
| `store-applications` | None | Submit store registration |
| `cron-sla` | CRON_SECRET | Auto-cancel orders past SLA deadline |
| `seed-admin` | None | One-shot platform admin creation |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                       Flutter App                           │
│  (Riverpod + GoRouter + supabase_flutter)                   │
│  27 Customer · 16 Store Admin · 3 Platform Admin screens    │
└───────┬──────────────────────────────┬──────────────────────┘
        │                              │
        ▼                              ▼
┌───────────────┐          ┌──────────────────────┐
│  Supabase DB  │          │   Supabase Auth       │
│  (PostgreSQL) │◄─RLS──►  │   (email + password)  │
│  15+ tables   │          │   3 roles             │
│  21 migrations│          └──────────────────────┘
└───────┬───────┘
        │
        ▼
┌──────────────────────────────────────────────────────────────┐
│                Edge Functions (11 Deno/TS)                   │
│  guest  │  orders  │  payments  │  midtrans  │  disputes    │
│  reviews │ notifications │ admin │ store-applications        │
│  cron-sla │ seed-admin                                       │
│  ┌────────────────────────────────────┐                      │
│  │ _shared/                           │                      │
│  │  helpers.ts — state machine + responses                   │
│  │  cors.ts    — CORS headers                                │
│  │  crypto.ts  — order number + password + coupon generation │
│  └────────────────────────────────────┘                      │
└──────────────────────────────────────────────────────────────┘
        │                              │
        ▼                              ▼
┌──────────────┐          ┌──────────────────────┐
│ Supabase     │          │  Midtrans Snap       │
│ Storage      │          │  (sandbox)           │
│ (proofs,     │          │  token + webhook     │
│  avatars)    │          └──────────────────────┘
└──────────────┘
```

### Key Design Decisions

- **RLS over app-level auth**: Flutter reads DB directly via Supabase client with RLS policies. Edge Functions use service_role for admin operations.
- **Guest booking flow**: Customer books without account → auto-creates suspended user → store "device_received" triggers auto-activation → credentials sent via notification.
- **Idempotent payments**: Midtrans webhook dedup by `midtrans_transaction_id` unique constraint.
- **SLA enforcement**: `cron-sla` Edge Function checks stalled orders and auto-cancels past deadline.

---

## Features

### Customer (27 screens)

Booking, tracking, upload payment, review, warranty claim, guest tracking, profile, settings, notifications, coupons, session management.

### Store Admin (16 screens)

Dashboard, order management, diagnosis, inventory, sparepart CRUD, payment confirmation, analytics, disputes, reviews, tracking.

### Platform Admin (3 screens)

Login, dashboard, store management, user management, notifications.

---

## Database Schema

### Enums

| Enum | Values |
|------|--------|
| `account_status` | active, suspended, deleted |
| `device_type` | android, ios |
| `delivery_method` | walk_in, courier_pickup |
| `order_status` | 11 states (see state machine) |
| `payment_status` | unpaid, partially_paid, paid, refunded |
| `payment_method` | transfer_bank, qris, cash, ewallet, midtrans |
| `payment_type` | deposit, final_payment, refund |
| `payment_record_status` | pending, confirmed, failed, refunded |
| `sparepart_status` | available, preorder, discontinued |
| `order_item_status` | pending, confirmed, replaced, cancelled |
| `dispute_type` | warranty_claim, service_quality, wrong_diagnosis, other |
| `dispute_status` | open, store_accepted, store_rejected, escalated, resolved, closed |
| `created_by_type` | customer, store_admin, system |
| `application_status` | pending, approved, rejected |

### Core Tables

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `users` | Customer accounts | phone_number (unique), account_status, is_first_login |
| `stores` | Repair stores | store_name, config (JSONB — warranty_days, etc) |
| `store_admins` | Staff per store | store_id (FK), is_active |
| `store_applications` | Store registration queue | status, business_license_url, id_card_url |
| `service_orders` | Service orders | user_id, store_id, status, order_number (unique), final_price, sla_deadline |
| `order_items` | Line items per order | sparepart_id, service_type, complaint, item_price, final_item_price |
| `service_tracking` | Status history per order | status, note, created_by_type |
| `spareparts` | Inventory per store | qty, qty_reserved, price, brand, device_model |
| `payments` | Payment records | amount, status, proof_url, midtrans fields |
| `reviews` | Customer reviews | rating (1-5), comment, is_public |
| `coupons` | Review reward coupons | code (unique), amount, is_used, expired_at |
| `disputes` | Warranty claims | dispute_type, status, evidence_urls (JSONB) |
| `notifications` | In-app notifications | role, type, title, message, is_read |
| `platform_admins` | Super admin accounts | username (unique) |

### RLS

All tables have RLS enabled. Flutter client queries go through per-row policies:
- Customers see only their own orders/payments/reviews
- Store admins see only their store's data (via `store_id` from `store_admins`)
- Platform admins use Edge Functions exclusively (no direct DB access from app)

---

## Order State Machine

```
pending ──→ waiting_device ──→ device_received ──→ diagnosing ──→ waiting_approval
                  │                  │                  │               │
                  │                  │                  │               │
                  ▼                  ▼                  ▼               ▼
              cancelled          cancelled          cancelled       cancelled
                                                                        │
                                                                        ▼
                                                              ┌─────────────────┐
                                                              │  waiting_approval│
                                                              └────────┬────────┘
                                                                       │
                                                  ┌────────────────────┤
                                                  ▼                    ▼
                                          repairing ◄─── waiting_sparepart
                                              │
                                              ▼
                                        quality_check
                                              │
                                              ▼
                                       waiting_payment ──→ completed ──→ disputed
                                              │                  │            │
                                              ▼                  ▼            ▼
                                          cancelled        (done)      resolved / cancelled
```

Valid transitions (enforced in `_shared/helpers.ts`):

| From | To |
|------|----|
| `waiting_device` | device_received, cancelled |
| `device_received` | diagnosing, cancelled |
| `diagnosing` | waiting_approval, cancelled |
| `waiting_approval` | repairing, waiting_sparepart, cancelled |
| `waiting_sparepart` | repairing, cancelled |
| `repairing` | quality_check, cancelled |
| `quality_check` | waiting_payment, cancelled |
| `waiting_payment` | completed, cancelled |
| `completed` | disputed |
| `disputed` | completed |

**SLA**: Most states have 24h SLA deadline enforced by `cron-sla` Edge Function. `waiting_payment` has 48h. Breach auto-cancels.

---

## Auth Roles

| Role | Email Format | Access |
|------|-------------|--------|
| Customer | `{phone}@customer.servisgadget.com` | Own orders, payments, reviews |
| Store Admin | `{phone}@store.servisgadget.com` | Store orders, inventory, analytics |
| Platform Admin | `{username}@servisgadget.com` | All stores, applications, users |

Supabase Auth native — no custom auth backend. Role stored in `user_metadata.role`. Edge Functions verify via JWT claims.

### Guest Booking Flow

```
User opens app → fills booking form → Edge Function `guest` (create-order)
  → Auto-create Supabase Auth user (suspended)
  → Order saved with status \`waiting_device\`

Store receives device → updates status to \`device_received\`
  → Edge Function \`orders\` auto-activates user

User can now login with their email + password
```

---

## Environment Variables

### Supabase Secrets (`supabase secrets set`)

| Variable | Required | Purpose |
|----------|----------|---------|
| `SUPABASE_URL` | Yes | Supabase project URL |
| `SUPABASE_ANON_KEY` | Yes | Supabase anon/publishable key |
| `SUPABASE_SERVICE_ROLE_KEY` | Yes | Admin operations in Edge Functions |
| `MIDTRANS_SERVER_KEY` | Yes | Midtrans server key (for webhook verification) |
| \`MIDTRANS_CLIENT_KEY\` | Yes | Midtrans client key |
| \`CRON_SECRET\` | No | Protects cron-sla endpoint |
| `SEED_ADMIN_PASSWORD` | No | Seed admin initial password |
| `SEED_ADMIN_SECRET` | No | Protects seed-admin endpoint |

### Flutter Build Args

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://eboplbemgtvmviwhdlfa.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_xxxx
```

---

## Setup

### Prerequisites

- Flutter 3.4+ / Dart 3
- Supabase CLI
- Midtrans account (sandbox)

### 1. Clone & Link

```bash
git clone https://github.com/fannndi/service-hub.git && cd service-hub
npx supabase login
npx supabase link --project-ref eboplbemgtvmviwhdlfa
```

### 2. Deploy Database

```bash
npx supabase db push
```

Applies all 21 migrations (schema, RLS, functions, triggers, seed data).

### 3. Deploy Edge Functions

```bash
npx supabase functions deploy \
  guest orders payments midtrans disputes reviews \
  notifications admin store-applications cron-sla seed-admin
```

### 4. Set Secrets

```bash
npx supabase secrets set MIDTRANS_SERVER_KEY=Mid-server-xxx
npx supabase secrets set MIDTRANS_CLIENT_KEY=Mid-client-xxx
npx supabase secrets set CRON_SECRET=your-cron-secret
npx supabase secrets set SEED_ADMIN_PASSWORD=admin123
```

### 5. Seed Platform Admin

```bash
curl -X POST https://eboplbemgtvmviwhdlfa.supabase.co/functions/v1/seed-admin
```

### 6. Build APK

```bash
cd frontend
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://eboplbemgtvmviwhdlfa.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_xxxx
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## Deployment

### Supabase (production)

```bash
npx supabase db push
npx supabase functions deploy guest orders payments midtrans disputes reviews notifications admin store-applications cron-sla
npx supabase secrets set MIDTRANS_SERVER_KEY=xxx
```

Update `SUPABASE_URL` and `SUPABASE_ANON_KEY` in Flutter build args.

### Play Store

```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console.

---

## Testing

| Type | Count | Status |
|------|-------|--------|
| Backend unit | 57 | ✅ |
| Backend security | 30 | ✅ |
| Backend integration | 65 | ✅ |
| Frontend widget | 9 | ✅ |
| Frontend model | 14 | ✅ |
| **Total** | **175** | ✅ ALL PASSING |

```bash
cd frontend
flutter test
```

---

## Project Structure

```
service-hub/
├── frontend/lib/
│   ├── core/
│   │   ├── cache/               Local caching layer
│   │   ├── data/                Repository implementations
│   │   ├── domain/              Domain models (order_status, etc)
│   │   ├── l10n/                Localization
│   │   ├── widgets/             Shared widgets
│   │   ├── supabase_config.dart Supabase URL + key + email builders
│   │   └── supabase_service.dart Supabase client singleton
│   └── features/
│       ├── customer/            27 screens, providers, domain
│       ├── store_admin/         16 screens, 11 providers, domain
│       └── platform_admin/      3 screens, providers, domain
├── supabase/
│   ├── migrations/              21 SQL migrations
│   └── functions/
│       ├── _shared/             cors.ts, crypto.ts, email.ts, helpers.ts
│       ├── guest/               Guest booking + tracking
│       ├── orders/              Order CRUD + lifecycle
│       ├── payments/            Payment CRUD + confirmation
│       ├── midtrans/            Snap token + webhook
│       ├── disputes/            Warranty claims
│       ├── reviews/             Reviews + coupon generation
│       ├── notifications/       Broadcast + email
│       ├── admin/               Platform admin operations
│       ├── store-applications/  Store registration
│       ├── cron-sla/            SLA breach auto-cancel
│       └── seed-admin/          One-shot admin seeder
├── docs/                        PRD, architecture, testing reports
└── scripts/                     Build helpers
```

---

## Docs

| File | Content |
|------|---------|
| `docs/PRD/00_MASTER_PRD.md` | Product requirements |
| `docs/architecture.md` | System architecture |
| `docs/testing/verification-report.md` | 175 test results |
| `CHANGELOG.md` | Version history |
| `PRIVACY_POLICY.md` | Privacy policy |
