# Task List — ServisGadget v2.0

> **Tim:** 3 orang — Fandi (Backend + Infrastruktur), Andriyan (Customer App), Nissa (Store Admin + Platform Admin)
> **Status:** v2.0 selesai. 175 tests passing. Production-ready.
> **Last updated:** 2026-07-23

---

## 1. Fandi — Backend & Infrastruktur

### Database (PostgreSQL via Supabase)
- [x] 25 migration files — schema, RLS, functions, triggers, seed data
- [x] 15+ tabel: users, stores, store_admins, service_orders, order_items, spareparts, payments, reviews, disputes, coupons, notifications, service_tracking, platform_admins, store_applications, failed_notifications, user_sessions
- [x] 14 enum types: account_status, device_type, delivery_method, order_status (11 states), payment_status, payment_method, payment_type, payment_record_status, sparepart_status, order_item_status, dispute_type, dispute_status, created_by_type, application_status
- [x] 50+ RLS (Row Level Security) policies — customer, store_admin, platform_admin, anon
- [x] PostgreSQL functions: auto_cancel_sla, reserve_stock, release_stock, consume_stock, swap_sparepart, update_rating_avg, get_device_models, handle_new_user, rls_auto_enable, get_home_summary, get_dashboard_summary, get_analytics
- [x] Triggers: handle_new_user (auto-create profile on auth signup), update_updated_at

### Edge Functions (Deno/TypeScript, 11 functions)
- [x] `guest` — Booking tanpa login, auto-create user (suspended), tracking, credential retrieval
- [x] `orders` — CRUD order, state machine (11 status transitions), diagnosis, approval, auto-activate guest
- [x] `payments` — Upload bukti pembayaran, konfirmasi pembayaran store admin, perhitungan fully_paid
- [x] `midtrans` — Generate Snap token, webhook handler (HMAC SHA-512 signature verification), idempotensi
- [x] `disputes` — Warranty claim, store accept/reject
- [x] `reviews` — Create review + auto-generate kupon reward
- [x] `notifications` — Broadcast notifikasi ke role (customer/store_admin)
- [x] `admin` — Approve/reject store applications, create store, manage users, delete account
- [x] `store-applications` — Submit pendaftaran toko (rate-limited, 10 req/10 min per IP)
- [x] `cron-sla` — Auto-cancel order yang melewati SLA deadline (24h/48h)
- [x] `seed-admin` — One-shot platform admin creation

### Security
- [x] RLS enabled di semua 15+ tabel
- [x] JWT verification manual via Supabase Auth API (`requireUser`)
- [x] State machine enforcement (`assertValidTransition`) — mencegah transisi status ilegal
- [x] Rate limiting: store-applications (10 req/10 min), guest (10 req/10 min)
- [x] Rollback logic: stock reservation failure → release all, auth creation failure → delete store
- [x] Idempotensi Midtrans webhook via `midtrans_transaction_id` unique constraint
- [x] CORS headers di semua Edge Functions

### Infrastruktur
- [x] Supabase project: eboplbemgtvmviwhdlfa (Northeast Asia/Seoul)
- [x] Supabase Storage — payment proofs, avatars
- [x] Firebase Cloud Messaging — push notification token registration
- [x] Firebase Crashlytics — crash reporting
- [x] GitHub Actions CI — backend tests

### Testing
- [x] 57 backend unit tests
- [x] 30 backend security tests
- [x] 65 backend integration tests
- [x] **152 backend tests — semua passing**

---

## 2. Andriyan — Customer App (Flutter/Dart)

### Screens (27)
- [x] Welcome screen — entry point dengan hidden admin login (7x tap icon)
- [x] Login screen — email + password, session management
- [x] Service flow (5-step wizard): Device → Damage → Store → Personal Data → Confirmation
- [x] Store list — filter by brand/model, featured stores
- [x] Store detail — info toko, reviews, sparepart listing
- [x] Booking form — brand/model dropdown dari API, sparepart selection
- [x] Booking success — order number + credential info (guest)
- [x] Order list — filter by status (active/completed), pagination
- [x] Order detail — status, items, tracking timeline, payment info
- [x] Order tracking — timeline riwayat status
- [x] Payment upload — transfer_bank, QRIS, ewallet, cash
- [x] Review form — rating 1-5 bintang, komentar
- [x] Review success — tampilkan kupon reward
- [x] Warranty claim — dispute form dengan evidence URLs
- [x] Coupons list — kupon dari review rewards
- [x] Profile screen — edit nama, alamat, phone
- [x] Change password screen
- [x] Sessions screen — kelola sesi login
- [x] Settings screen — theme, language
- [x] Notifications screen — in-app notifications
- [x] Security screen — logout all sessions

### State Management
- [x] Riverpod 2.6 — providers untuk auth, orders, stores, payments, reviews, disputes
- [x] GoRouter 14 — auth guards, deep linking, parameter passing
- [x] Supabase client singleton — `SupabaseService`

### Features
- [x] Auto-login setelah guest booking — credentials langsung aktif
- [x] Token refresh mutex — mencegah race condition
- [x] Error handling — snackbar + retry untuk network error
- [x] Session invalidation — logout di semua device
- [x] Theme support — light/dark mode

### Testing
- [x] 9 widget tests
- [x] 14 model tests
- [x] **23 frontend tests — semua passing**

---

## 3. Nissa — Store Admin + Platform Admin (Flutter/Dart)

### Store Admin Screens (16)
- [x] Dashboard — statistik order harian (new, repairing, completed)
- [x] Order list — filter by status, search
- [x] Order detail — customer info, items, payment, tracking
- [x] Diagnosis screen — form diagnosis dengan sparepart replacement
- [x] Order tracking — update status, SLA deadline management
- [x] Inventory screen — sparepart CRUD, brand/model filter
- [x] Sparepart form — add/edit sparepart dengan qty management
- [x] Payments screen — verifikasi bukti pembayaran
- [x] Customers screen — riwayat customer
- [x] Reviews screen — lihat review toko
- [x] Disputes screen — warranty claims management
- [x] Notifications screen
- [x] Analytics screen — chart order per status
- [x] Store settings — update profil toko
- [x] Store login screen
- [x] Change password screen

### Platform Admin Screens (3)
- [x] Admin login screen (hidden: 7x tap icon di welcome)
- [x] Dashboard — list stores, store applications
- [x] Notifications screen

### Features
- [x] POS-style inventory — brand/model dropdown, +/- stock
- [x] Dashboard KPI — total orders, revenue, rating
- [x] Analytics — bar chart per status order
- [x] Responsive layout — NavigationRail/NavigationBar/Drawer
- [x] Store admin session — auto-refresh

### Testing
- [x] Integration test — app_test.dart, deep_flow_test.dart
- [x] Widget tests

---

## 4. Shared — DevOps & Dokumentasi

### CI/CD
- [x] GitHub Actions — backend tests

### Build & Deploy
- [x] `flutter build apk --release` — production APK
- [x] `flutter build appbundle --release` — Play Store AAB
- [x] `build_apk.bat` — script build dengan env vars
- [x] `run_emulator.bat` — script run dengan env vars
- [x] `switch-env.sh` — switch environment (local/production)

### Dokumentasi
- [x] `docs/PRD/00_MASTER_PRD.md` — Product Requirements Document
- [x] `docs/PRD/01_PHASE_FOUNDATION.md` — Phase 1: Foundation
- [x] `docs/PRD/02_PHASE_CUSTOMER.md` — Phase 2: Customer
- [x] `docs/PRD/03_PHASE_STORE_ADMIN.md` — Phase 3: Store Admin
- [x] `docs/architecture.md` — System architecture
- [x] `docs/deployment.md` — Deployment guide
- [x] `docs/run-guide.md` — Setup & run instructions
- [x] `docs/frontend/FRONTEND_CUSTOMER.md` — Customer frontend docs
- [x] `docs/frontend/FRONTEND_STORE_ADMIN.md` — Store admin frontend docs
- [x] `docs/frontend/FRONTEND_PLATFORM_ADMIN.md` — Platform admin frontend docs
- [x] `docs/frontend/FRONTEND_NETWORK_LAYER.md` — Network layer docs
- [x] `docs/testing/verification-report.md` — 175 test results
- [x] `README.md` — Project overview
- [x] `CHANGELOG.md` — Version history
- [x] `PRIVACY_POLICY.md` — Privacy policy (Play Store required)

---

## Ringkasan Progress

| Bagian | Selesai | Test |
|--------|---------|------|
| Fandi (Backend + Infra) | 25 migrations, 11 Edge Functions, 15+ tables, 50+ RLS | 152 ✅ |
| Andriyan (Customer App) | 27 screens, 5-step wizard, Riverpod + GoRouter | 23 ✅ |
| Nissa (Store + Platform Admin) | 19 screens, dashboard, POS inventory, analytics | passing ✅ |
| Shared (DevOps + Docs) | CI/CD, build scripts, 15+ docs | — |
| **Total** | **45+ screens, 11 Edge Functions, 175 tests** | **ALL PASSING** |

| Metrik | Nilai |
|--------|-------|
| Database migrations | 25 |
| Edge Functions | 11 |
| RLS policies | 50+ |
| Flutter screens | 45+ |
| Backend tests | 152 ✅ |
| Frontend tests | 23 ✅ |
| Total tests | 175 ✅ |
| PRD phases | 3 (Foundation, Customer, Store Admin) |
| Git commits | 500+ |
