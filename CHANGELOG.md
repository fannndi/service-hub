# Changelog

## 2026-06-06 — Phase 3 Store Admin Merge + API Alignment

### Added (Phase 3 — Flutter Frontend)
- `frontend/lib/features/store_admin/` — complete store admin app:
  - GoRouter with auth guard, store login/change-password, dashboard (60s polling)
  - Screens: StoreLogin, StoreChangePassword, Dashboard, OrderList, OrderDetail, Diagnosis, Tracking, Inventory, SparepartForm, PaymentConfirmation, DisputeList, DisputeDetail, Settings
  - Providers: StoreAuthController, DashboardSummary (Stream), StoreOrderDetail, InventoryList
  - Repositories: StoreAuthRepository, StoreOrderRepository, StoreInventoryRepository, StoreDisputeRepository
  - Widgets: CredentialPanelCard, DiagnosisItemRow, InventoryItemCard, SlaCountdownBadge, PaymentProofViewer
  - Models: ServiceOrder, Sparepart, DisputeCase, DashboardSummary, CredentialPanel, StoreSession, ReviewItem, AnalyticsData
  - Tests: store_admin_model_test, updated widget_test for store admin login

### Added (Backend for Store Admin)
- `POST /v1/store/auth/logout` — store admin logout
- `POST /v1/store/orders/:id/actions/:action` — dynamic action endpoint (maps action → status)
- `GET /v1/store/orders/:id/tracking` — store admin tracking timeline
- `POST /v1/store/orders/:id/tracking` — add manual tracking entry
- `GET /v1/store/customers` — customer list per store
- `GET /v1/store/payments` — payment list per store
- `GET /v1/store/reviews` — review list per store
- `POST /v1/store/reviews/:id/response` — respond to review
- `GET /v1/store/notifications` — store notification feed
- `GET /v1/store/profile` — store admin profile + store info
- `PATCH /v1/store/profile` — update store admin profile
- `GET /v1/store/analytics` — 30-day analytics (orders, revenue, rating)
- `POST /v1/store/orders/:id/payments/:paymentId/confirm` — payment confirm (nested path)
- `PATCH /v1/store/orders/:id/diagnosis` — diagnosis update (Patch variant alongside Post)
- Combined main.dart: role-based splash router that checks customer vs store admin auth

### Changed
- API path alignment for Store Admin to match frontend contract
- StoreOrdersController: Post + Patch for diagnosis/status, action endpoint mapping
- StoresService: extended with customers, payments, reviews, notifications, profile, analytics methods
- OrdersService: added getStoreOrderTracking + addStoreOrderTracking

### Scope
- Phase 1 Foundation: complete backend
- Phase 2 Customer: complete app
- Phase 3 Store Admin: complete app
- All 3 phases merged into main with full API alignment

## 2026-06-06 — Phase 1 Foundation Complete + Phase 2 Customer Merge

### Added (Phase 1 Foundation — Backend)
- Orders module: createOrder (stealth account, stock reservation, coupon validation, nanoid), approveOrder (decrement qty+qtyReserved), rejectOrder (rollback qtyReserved), updateStatus (state machine + SLA reset), submitDiagnosis (replaced sparepart swap, finalPrice calc)
- Payments module: createPayment (proof validation), confirmPayment (warranty assignment from store.config.warranty_days, totalCompleted increment)
- Reviews module: createReview (duplicate check, ratingAvg recalculation, reward coupon creation in transaction)
- Disputes module: createDispute (warranty check, active dispute guard), respondDispute (warranty order creation on store_accepted)
- Notifications module: WA send with 3x exponential retry + FailedNotification logging, sendNewOrderToStore, sendWaitingPayment, sendDiagnosisResult, sendOrderCompleted
- Uploads module: S3 presigned URL generation via @aws-sdk/s3-request-presigner
- Jobs module: SlaMonitorJob (30s cron, slaWarnedAt + breach tracking, notify store + customer), CredentialCleanerJob (30min cron, clear credentialPlainEnc after 24h)
- SLA constants and state-machine utility (assertValidTransition with full transition map)
- Prisma seed file: store, admin, customers, spareparts sample data
- Bug fixes per PRD: B1 (itemPrice from sparepart.price), B2 (qtyReserved increment), B3 (decrement both qty+qtyReserved), B4 (POST /v1/orders PUBLIC), B5 (separate store auth), B6 (coupon ownership), B7 (warrantyDays from store.config), B8 (ratingAvg recalculation), B9 (coupon in review transaction), B10 (nanoid order number), B11 (replacedSparepartId validation)

### Added (Phase 2 Customer — Flutter Frontend)
- `frontend/lib/features/customer/` — complete customer app:
  - GoRouter configuration with auth guard redirect
  - Screens: Splash, Login, ChangePassword, Home, StoreList, StoreDetail, BookingForm, BookingSuccess, OrderList, OrderDetail, Tracking, PaymentUpload, ReviewForm, ReviewSuccess, WarrantyClaim, Profile, Sessions
  - Providers: AuthNotifier (login/logout/session), OrderTracking (30s polling Stream), CustomerOrders (filtered pagination), OrderDetail
  - Repositories: CustomerAuthRepository, StoreRepository, OrderRepository, PaymentRepository, ReviewRepository, DisputeRepository — all implementing Master PRD API contracts
  - Session storage: Dio client with interceptor, token refresh, public Dio for booking
  - Widgets: OrderStatusTimeline, StoreCard, DiagnosisApprovalCard, SparePartSelectorSheet, CouponRewardBanner
  - Error handler mapping API error codes to user-friendly Bahasa Indonesia messages
  - Tests: customer provider test, customer repository test, updated widget test

### Changed (API Path Alignment)
- `POST /v1/payments/:orderId` → `POST /v1/orders/:id/payments` (Master PRD contract)
- `POST /v1/reviews/:orderId` → `POST /v1/orders/:id/reviews` (Master PRD contract)
- `POST /v1/disputes/:orderId` → `POST /v1/orders/:id/disputes` (Master PRD contract)
- `POST /v1/uploads/presigned-url` → `POST /v1/uploads/presign` (frontend contract)
- `POST /v1/store/orders/:id/status` → `PATCH /v1/store/orders/:id/status` (Master PRD AC-17)
- `POST /v1/store/orders/:id/diagnosis` → `PATCH /v1/store/orders/:id/diagnosis` (Master PRD AC-15)
- `GET /v1/store/spareparts` — now PUBLIC for customer store detail screen (takes ?storeId= param)
- Added `GET /v1/me/orders` (customer orders list alias)
- Added `GET /v1/me/summary` (home screen: activeOrders, activeCoupons, activeWarranty)
- Added `GET /v1/me/orders/:id/progress` (tracking timeline for 30s polling)
- Added `GET /v1/me/notifications` (recent tracking events)

### Fixed
- Prisma schema: BOM encoding stripped, enums formatted multi-line, named relation OrderCoupon/CouponUsage fixed
- GetUser decorator: relaxed typing for id/storeId access across all controllers
- tsconfig: strictPropertyInitialization disabled (class-validator DTOs)
- .gitignore: added backend/dist/
- Spareparts controller: GET made public (customer store detail), admin mutations remain StoreJWT-guarded

### Scope
- Phase 1 Foundation backend: complete with all business rules + bug fixes from PRD
- Phase 2 Customer Flutter app: complete UI + routing + providers + repositories
- Phase 3 Store Admin: pending (branch phase-03)
- All Master PRD API contracts aligned between backend and frontend








## 2026-06-02 — Final safe scaffold pass before stop

### Added
- Added shared change-password shell.
- Added Store Admin inventory form shell.
- Added Store Admin dispute detail/respond shell.
- Connected Customer profile to coupons and change password.
- Connected Store inventory add action to inventory form.
- Connected Store dispute list to dispute detail.
- Added final handoff doc at `docs/final-partial-handoff-phase-02-03.md`.

### Stop Decision
- This is the maximum safe helper scope for Phase 02/03.
- Further work should be done by Phase 02/03 owners because it requires final provider architecture, backend/Supabase wiring, persistence, validation, and PRD acceptance testing.
## 2026-06-02 — Thin stop-boundary and filter scaffolds

### Added
- Added `docs/stop-boundary-phase-02-03.md` to define safe stopping point for helper work.
- Added reusable `SearchFilterBar` widget.
- Added filter/search UI to Customer order list.
- Added filter/search UI to Store Admin order list.
- Added Customer dispute/warranty claim shell.
- Connected Customer warranty claim actions to dispute shell.

### Stop Reminder
- Stop before backend/Supabase integration, real persistence, business state transitions, upload implementation, and final provider architecture.
- Phase 02/03 owners should finalize repositories, state management, UX validation, and API wiring.
## 2026-06-02 — Role bottom navigation scaffolds

### Added
- Added shared loading, error, and app info card widgets.
- Added Customer bottom navigation shell: Home, Order, Kupon, Profil.
- Added Store Admin bottom navigation shell: Home, Order, Stok, Setting.
- Updated app entrypoint to route logged-in dummy users into role-specific shells.

### Scope Note
- Navigation remains local Flutter-only.
- Older home screens are kept as reference but no longer used by `main.dart`.
## 2026-06-02 — Thin UX helpers for Phase 02/03 review

### Added
- Shared `StatusBadge`, `SectionHeader`, and `KeyValueRow` widgets.
- Customer notifications screen.
- Customer coupons screen.
- Store notifications screen.
- Store SLA countdown badge widget.
- Store credential panel card matching Phase 03 credential handoff concept.
- Connected notification/coupon shortcuts on Customer home.
- Connected store notification shortcut and credential panel on Store order detail.

### Scope Note
- Components are visual scaffolds only.
- Copy, mark-sent, SLA countdown, and notification delivery are not persisted yet.
## 2026-06-02 — Extra thin Phase 02/03 scaffolds

### Added
- Customer payment upload shell.
- Customer review and coupon shell.
- Customer profile shell.
- Store diagnosis form shell with replaced sparepart field hint.
- Store payment confirmation shell with warranty reminder.
- Store settings shell for warranty days and stock threshold.
- Connected order-detail actions to diagnosis/payment screens.

### Scope Note
- All new actions remain UI-only references for Phase 02/03 implementers.
- Backend, Supabase, validation persistence, and business state transitions are not wired yet.
## 2026-06-02 — Partial Phase 02/03 navigation layer

### Added
- Added dummy service order and sparepart data.
- Added Customer create order shell.
- Added Customer order list and order detail shell.
- Added Store Admin order list and order detail shell.
- Added Store Admin inventory shell.
- Added Store Admin dispute shell.
- Connected Customer and Store Admin home menu cards to dummy screens.

### Scope Note
- Screens are local UI scaffolds only.
- Buttons are visual actions until backend/Supabase contracts are wired.
## 2026-06-02 — Fix Flutter widget test

### Fixed
- Updated `frontend/test/widget_test.dart` from old `MyApp` counter template to `ServisGadgetApp` dummy login smoke test.
## 2026-06-02 — Partial Phase 02/03 dummy login

### Added
- Added local dummy Customer and Store Admin accounts.
- Added login screen with role switcher and quick dummy login.
- Added Customer home shell with Phase 02 placeholder menus.
- Added Store Admin home shell with Phase 03 placeholder menus and simple metrics.
- Added local logout.
- Added handoff doc at `docs/partial-phase-02-03-dummy.md`.

### Dummy Credentials
- Customer: `081234567890` / `customer123`.
- Admin Toko: `081298765432` / `admin123`.

### Scope Note
- This is intentionally partial UI/auth simulation only.
- No backend auth, Supabase, database, or business flow integration yet.
## 2026-06-02 — Audit setelah Flutter launch

### Status
- Flutter Android launch berhasil di mesin user setelah wrapper Android dibuat.
- Repo saat ini valid sebagai bootstrap runnable, bukan implementasi lengkap Phase 1 Foundation.
- Audit detail tersedia di `docs/foundation-status-audit.md`.

### Audit Ringkas
- Ada: NestJS shell, health endpoint, Swagger setup, Prisma schema PRD, Docker Compose, Flutter shared starter.
- Belum ada: auth customer/store, migrations, seed, Prisma module, Redis/BullMQ module, domain CRUD/services, business rules Foundation, jobs, upload, notification, tests scaffold lengkap.
- AC-01 sampai AC-30 belum bisa dianggap hijau.

### Next Work Priority
1. Backend infrastructure: config, database module, Prisma service, Redis module.
2. Prisma migration + seed.
3. CustomerAuthModule dan StoreAuthModule terpisah.
4. Store + Sparepart CRUD.
5. Order/payment/review/dispute services dengan transaction safety.
6. Jobs, upload, notifications.
7. Flutter shared models/repositories sesuai API final.

## 2026-06-02 — Phase 1 Foundation bootstrap

### Added
- Created monorepo layout for Phase 1 Foundation only.
- Added backend NestJS runnable shell under `backend`.
- Added strict TypeScript config, Nest CLI config, Jest config, and package scripts.
- Added `/v1/health` endpoint and Swagger setup at `/docs`.
- Added official Prisma schema extracted from `00_MASTER_PRD.md` into `backend/prisma/schema.prisma`.
- Added Flutter shared foundation under `frontend/lib`:
  - app shell in `main.dart`
  - app config provider
  - Dio client provider
  - token storage abstraction
  - network error mapper
  - base repository
  - shared API response model
  - generic empty state widget
- Added Docker Compose with PostgreSQL 16, Redis 7, and backend service.
- Added backend Dockerfile.
- Added `.env.example` and local `.env` copy.
- Added architecture docs and run guide.

### Scope Guard
- No Customer screens added.
- No Store Admin screens added.
- No dashboard or feature flows added.
- No feature-specific shortcuts added.

### Known Environment Note
- PowerShell blocks `npm.ps1`; use `cmd /c npm ...` or update local execution policy.
- Run Flutter Android generation from `frontend`, not repo root.

### Next Foundation Work
- Install backend dependencies and run Prisma validation.
- Implement typed config module.
- Implement database module with Prisma lifecycle.
- Implement Redis module and BullMQ module.
- Split customer/store auth modules with independent JWT strategies and guards.
- Implement repository/service/controller layers per domain.
- Generate Prisma migration from schema.
- Fill `docs/integration-guide.md` with final contracts after endpoints are implemented.








