# ServisGadget — Architecture

> **Versi:** 3.0 — 100% Serverless Supabase
> **Status:** Production Ready

---

## 1. System Overview

ServisGadget adalah platform marketplace servis gadget dua sisi:
- **Customer**: Booking perbaikan tanpa daftar akun (stealth account)
- **Store Admin**: Kelola order, diagnosa, stok, pembayaran dari mobile app
- **Platform Admin**: Buat toko, set device types, kelola akun

---

## 2. Tech Stack

### Backend (Serverless)
| Component | Technology |
|-----------|-----------|
| Runtime | Supabase Edge Functions (Deno / TypeScript) |
| Database | Supabase PostgreSQL 16 |
| Auth | Supabase Auth (email/password) |
| Storage | Supabase Storage |
| Payments | Midtrans Snap API via Edge Function |
| Notifications | WhatsApp Gateway via Edge Function |

### Frontend
| Component | Version |
|-----------|---------|
| Flutter | 3.4+ |
| Dart | 3.x |
| State Management | Riverpod 2.6.1 |
| Routing | GoRouter 14.8.1 |
| Supabase SDK | supabase_flutter 2.8.1 |

### Infrastruktur
- **Zero server**: Tidak ada VPS, Docker, atau NestJS
- **Zero Redis**: Semua state di PostgreSQL + RLS
- **Zero CI/CD**: Deploy manual via Supabase CLI + Flutter build

---

## 3. Backend Architecture

### Supabase Edge Functions (11 functions)

| Function | Auth | Purpose |
|----------|------|---------|
| `guest` | none | Guest booking + tracking + credential check |
| `orders` | user | Order CRUD, status transitions, stock management |
| `payments` | user | Manual payment confirmation by store admin |
| `midtrans` | snap: user / notification: none | Midtrans Snap token + webhook handler |
| `disputes` | user | Warranty claim creation + resolution |
| `reviews` | user | Review creation + coupon generation |
| `notifications` | user | Broadcast notifications |
| `admin` | user + role check | Platform admin: manage stores, users, applications |
| `store-applications` | none | Store registration application |
| `cron-sla` | none (cron) | SLA monitoring every 30 seconds |
| `seed-admin` | none | One-time admin seeding |

### Database (17 tables + 22 enums + 10 stored procedures)

| Table | Purpose |
|-------|---------|
| `users` | Customer accounts |
| `stores` | Service stores with config, rating, penalty |
| `store_admins` | Admin accounts per store |
| `store_applications` | Pending store registration |
| `platform_admins` | Platform-level administrators |
| `spareparts` | Inventory per store |
| `service_orders` | Core order records with status/SLA |
| `order_items` | Line items per order |
| `service_tracking` | Timeline entries for each status change |
| `payments` | Payment records (manual + Midtrans) |
| `reviews` | Customer reviews (1-5 stars) |
| `coupons` | Discount coupons from reviews |
| `disputes` | Warranty claims |
| `notifications` | In-app notifications |
| `failed_notifications` | Failed WhatsApp delivery queue |
| `shipments` | Courier shipping |
| `user_sessions` | Active login sessions |

### RLS Policies (50+ policies for 4 roles)
- **anon**: Read-only: active stores, available spareparts, public reviews
- **customer**: Own data only via `auth.uid()`
- **store_admin**: Store-scoped access via `store_admins` join
- **platform_admin**: Full access to all tables

### State Machine (Order Status)
```
waiting_device → device_received → diagnosing → waiting_approval
    → repairing → quality_check → waiting_payment → completed → disputed
```
Setiap transisi divalidasi. Status dapat dibatalkan (`cancelled`) dari hampir semua state.

---

## 4. Frontend Architecture

### Feature Structure
```
frontend/lib/
├── main.dart                          App entry, GoRouter, auth redirect
├── core/                              Supabase service, config, shared enums
├── shared_widgets/                    StatusBadge, ErrorState, EmptyState, formatters
├── ui/                                Theme, widgets (ModernCard, Shimmer, etc.)
└── features/
    ├── customer/                      26 screens, 10+ providers
    ├── store_admin/                   17 screens, 11+ providers
    └── platform_admin/                2 screens, 3 providers
```

### Frontend → Supabase Connection
- **Database**: Direct via `supabase_flutter` SDK (RLS protections)
- **Edge Functions**: Via `SupabaseService.instance.invoke()`
- **Auth**: Via `SupabaseService.instance.signIn()` with synthetic email convention

---

## 5. Security Model

| Check | Implementation | Severity |
|-------|---------------|----------|
| Row-level security | 50+ RLS policies on all tables | CRITICAL |
| JWT authentication | Supabase Auth | CRITICAL |
| State machine validation | Edge Functions + DB procedures | HIGH |
| Stock atomicity | `reserve_stock` / `consume_stock` RPCs | HIGH |
| Payment verification | HMAC-SHA512 signature | HIGH |
| JWT separation | 3 roles with different secrets | CRITICAL |
| SLA monitoring | Auto-cancel with stock rollback | MEDIUM |

---

## 6. Deployment

```bash
# 1. Link Supabase project
supabase link --project-ref <PROJECT_REF>

# 2. Push SQL migrations
supabase db push

# 3. Deploy Edge Functions
supabase functions deploy guest orders payments midtrans disputes reviews notifications admin store-applications cron-sla

# 4. Set secrets
supabase secrets set MIDTRANS_SERVER_KEY=...
supabase secrets set WA_GATEWAY_URL=...
supabase secrets set WA_GATEWAY_TOKEN=...

# 5. Build Flutter APK
cd frontend
flutter build apk --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

---

*Architecture v3.0 — 100% Serverless Supabase — ServisGadget Production Ready*
