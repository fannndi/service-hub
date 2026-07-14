# Service Hub — Architecture

> **Stack:** Flutter + Supabase (100% serverless)
> **Status:** Production Ready

---

## 1. System Overview

Service Hub adalah platform marketplace servis gadget tiga peran:

- **Customer**: Booking perbaikan, tracking, bayar via Midtrans
- **Store Admin**: Kelola order, diagnosa, stok sparepart, konfirmasi pembayaran
- **Platform Admin**: Buat toko, set device types, kelola semua akun

---

## 2. High-Level Flow

```
User → Supabase Auth → Edge Function → PostgreSQL + Storage
                      → Midtrans API (payment)
                      → Resend API (email notification)
```

Semua backend logic jalan di Supabase Edge Functions. Frontend Flutter invoke langsung via SDK. Tidak ada server, VPS, atau backend framework terpisah.

---

## 3. Tech Stack

### Frontend

| Component | Technology |
|-----------|-----------|
| Framework | Flutter 3.4+ / Dart 3.x |
| State Management | Riverpod 2.6.1 |
| Routing | GoRouter 14.8.1 |
| Supabase SDK | supabase_flutter 2.8.1 |
| Build Output | APK + App Bundle (Play Store) |

### Backend (Serverless)

| Component | Technology |
|-----------|-----------|
| Runtime | Supabase Edge Functions (Deno / TypeScript) |
| Database | Supabase PostgreSQL 16 |
| Auth | Supabase Auth (email/password) |
| Storage | Supabase Storage (file uploads) |
| Payments | Midtrans Snap API |
| Email | Resend.com API |

### Infrastructure

- **Zero server**: Tidak ada VPS, Docker, atau backend framework (NestJS/Express)
- **Zero Redis**: Semua state di PostgreSQL + RLS
- **Zero Prisma**: Query langsung via Supabase SDK / Edge Function `supabase-js`
- **Zero R2**: File di Supabase Storage

---

## 4. Backend Architecture

### Supabase Edge Functions (11 functions)

| Function | Auth | Purpose |
|----------|------|---------|
| `guest` | none | Guest booking + tracking + credential check |
| `orders` | user | Order CRUD, status transitions, stock management |
| `payments` | user | Manual payment confirmation by store admin |
| `midtrans` | user / none (webhook) | Midtrans Snap token + webhook handler |
| `disputes` | user | Warranty claim creation + resolution |
| `reviews` | user | Review creation + coupon generation |
| `notifications` | user | Broadcast notifications + email via Resend |
| `admin` | user + role check | Platform admin: manage stores, users, applications |
| `store-applications` | none | Store registration application |
| `cron-sla` | none (cron) | SLA monitoring every 30 seconds |
| `seed-admin` | none | One-time admin seeding |

Deploy via: `supabase functions deploy <name>`

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
| `failed_notifications` | Failed delivery queue |
| `shipments` | Courier shipping |
| `user_sessions` | Active login sessions |

### RLS Policies (50+ policies, 4 roles)

| Role | Scope |
|------|-------|
| `anon` | Read-only: active stores, available spareparts, public reviews |
| `customer` | Own data only via `auth.uid()` |
| `store_admin` | Store-scoped access via `store_admins` join |
| `platform_admin` | Full access to all tables |

### Order State Machine

```
waiting_device → device_received → diagnosing → waiting_approval
    → repairing → quality_check → waiting_payment → completed → disputed
```

Setiap transisi divalidasi di Edge Function. Status dapat dibatalkan (`cancelled`) dari hampir semua state.

---

## 5. Frontend Architecture

### Feature Structure

```
frontend/lib/
├── main.dart                       App entry, GoRouter, auth redirect
├── core/                           Supabase service, config, shared enums
├── shared_widgets/                 StatusBadge, ErrorState, EmptyState, formatters
├── ui/                             Theme, widgets (ModernCard, Shimmer, etc.)
└── features/
    ├── customer/                   26 screens, 10+ Riverpod providers
    ├── store_admin/                17 screens, 11+ Riverpod providers
    └── platform_admin/             2 screens, 3 Riverpod providers
```

### Frontend → Supabase

- **Database**: Direct via `supabase_flutter` SDK — RLS protects all queries
- **Edge Functions**: Via `SupabaseService.instance.invoke()`
- **Auth**: Via `SupabaseService.instance.signIn()` with synthetic email convention

### State Management (Riverpod)

- `StateNotifierProvider` untuk form state dan mutable data
- `FutureProvider` / `StreamProvider` untuk read-only data dari Supabase
- Auto-dispose pattern untuk resource cleanup

---

## 6. Security Model

| Check | Implementation |
|-------|---------------|
| Row-level security | 50+ RLS policies on all tables |
| JWT authentication | Supabase Auth (3 role separation) |
| State machine validation | Edge Functions + DB procedures |
| Stock atomicity | `reserve_stock` / `consume_stock` RPCs |
| Payment verification | Midtrans HMAC-SHA512 signature |
| Email delivery | Resend.com API key (server-side only) |
| SLA monitoring | Auto-cancel with stock rollback |

---

*Architecture — 100% Serverless Supabase — Service Hub*
