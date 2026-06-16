# Changelog

## 2026-06-16 — Refactoring Besar-besaran (Code Quality Cleanup)

### Fixed
- **`formatShortDate` bug** — Menampilkan "Xh lalu" untuk range hari, sekarang benar "Xd lalu"
- **`AdminAuthNotifier` hardcoded session** — Sekarang cache session di secure storage, bukan hardcoded fake `AdminSession`
- **`user_session.dart` unsafe parsing** — `DateTime.parse()` → `tryParse()` + null-coalescing, tidak crash lagi

### Added
- **`lib/core/json_helpers.dart`** — Shared deserialization helpers (`moneyFromJson`, `readString`, `jsonMap`, `jsonList`, `jsonString`, `jsonInt`, `jsonNum`, `jsonDouble`, `jsonBool`, `jsonDate`, `jsonDateOrNull`, `jsonStringList`, `jsonIntMap`)
- **`lib/core/domain/order_status.dart`** — Canonical `OrderStatus`, `PaymentRecordStatus`, `DisputeStatus` enums + `PageResult<T>`
- **`createAuthDio()` factory** — Shared Dio instance dengan auth interceptor + automatic 401 refresh-retry logic
- **`unwrap()` / `unwrapList()`** — Shared API response envelope unwrappers di `api_client.dart`
- **Customer domain split** — `customer_models.dart` (492L) → 7 focused files + barrel: `auth_models.dart`, `order_models.dart`, `store_models.dart`, `sparepart_models.dart`, `review_models.dart`, `notification_models.dart`, `home_models.dart`
- **Store admin domain split** — `store_admin_models.dart` (473L) → 9 focused files + barrel: `store_admin_enums.dart`, `store_admin_session.dart`, `store_admin_dashboard_models.dart`, `store_admin_order_models.dart`, `store_admin_inventory_models.dart`, `store_admin_dispute_models.dart`, `store_admin_review_models.dart`, `store_admin_notification_models.dart`, `store_admin_customer_models.dart`

### Changed
- **Backend dead code removed** — 12 empty scaffold directories deleted (`src/auth/`, `src/stores/`, `src/orders/`, `src/payments/`, `src/reviews/`, `src/disputes/`, `src/spareparts/`, `src/notifications/`, `src/jobs/`, `src/upload/`, `src/database/`, `src/redis/`)
- **Frontend dead code removed** — `lib/models/`, `lib/repositories/` scaffold dirs deleted
- **7 dead shared widgets deleted** — `SlaCountdownBadge`, `SectionHeader`, `SearchFilterBar`, `LoadingState`, `KeyValueRow`, `AppInfoCard`, `AsyncPage` (zero imports)
- **Duplicate helper functions eliminated** — `moneyFromJson`/`moneyParse`, `readString`/`strRead`, `_string`/`_int`/`_num`/`_double`/`_bool`/`_date`/`_dateOrNull` consolidated into shared `json_helpers.dart`
- **`CustomerApiClient` refactored** — Inline Dio interceptor → shared `createAuthDio()` factory
- **30+ `.gitkeep` files cleaned up** — Removed from directories that already contain real files

### Removed
- Backend: `src/auth/`, `src/stores/`, `src/orders/`, `src/payments/`, `src/reviews/`, `src/disputes/`, `src/spareparts/`, `src/notifications/`, `src/jobs/`, `src/upload/`, `src/database/`, `src/redis/` (all empty scaffolds)
- Frontend: `lib/models/`, `lib/repositories/` (empty scaffolds)
- Frontend shared_widgets: 7 dead widget files

---

## 2026-06-15 — Sessions, God File Split, Logging, Redis, Tests, Monitoring

### Added
- **Sessions screen** — `GET /me/sessions`, `DELETE /me/sessions/:id`, `DELETE /me/sessions` (backend + frontend)
- **Security screen** — Active sessions count, change password link
- **CI/CD pipeline** — `.github/workflows/ci.yml` (backend typecheck+test, frontend analyze+test)
- **Structured logging** — `nestjs-pino` with pretty-print dev / JSON prod, enhanced error context
- **Redis caching** — `RedisModule` + `RedisService` with cache-aside for store listings (5min TTL)
- **Prometheus metrics** — `/v1/metrics` endpoint with default process metrics
- **WhatsApp email fallback** — `EmailService` (Nodemailer SMTP) when Fonnte 3x retry exhausted
- **Widget tests** — 4 new tests (WelcomeScreen, StatusBadge, EmptyMessage). Total: 23
- **Deployment guide** — `docs/deployment.md` with rollback procedure
- **Shared widgets** — `AsyncPage`, enhanced `EmptyState` with icon, `formatters.dart`

### Changed
- **God file split** — `booking_form_screen.dart` (2002→476 lines) split into 24 individual screen files
- **ServiceFlowScreen performance** — 5 step widgets extracted with `IndexedStack` (only active step rebuilds)
- **Dio clients consolidated** — Shared `createApiClient()` factory, 3 client instances refactored
- **Dead code removed** — Deleted `dio_client.dart`, `base_repository.dart`, `api_response.dart`
- **Unused routers removed** — `customerRouterProvider`, `storeAdminRouterProvider`, `adminRouterProvider`
- **Docker compose hardened** — `restart: unless-stopped`, resource limits, health checks on all services
- **jest config fixed** — `rootDir` updated to include `test/` directory (55 tests, 4 suites)
- **DB index added** — `@@index([createdAt])` on `ServiceOrder`
- **Errors/Warnings fixed** — 4 unused imports, 1 unused variable, 5 const constructor warnings
- **const constructors** — `AppConfig`, `Card`, `ListTile`, test map literals

### Docs
- `docs/deployment.md` — New runbook
- `backend/BACKEND_API_REFERENCE.md` — Sessions endpoints
- `frontend/FRONTEND_CUSTOMER.md` — SessionsScreen, SecurityScreen
- `.env.example` — SMTP config for email fallback

---

### Changed
- Added Nest throttling to public `POST /v1/orders`, limiting booking creation to 5 requests per minute per IP.

### Docs
- Documented the public order rate limit in backend API and business logic docs.

---

## 2026-06-15 — Dynamic Customer Device Models

### Added
- Added public `GET /v1/stores/device-models` endpoint backed by non-discontinued sparepart brand/model data.
- Added `DeviceModelGroup`, `StoreDiscoveryRepository.getDeviceModels()`, and `deviceModelsProvider`.

### Changed
- Customer Service Now Step 1 now uses required dynamic dropdowns for brand and device model instead of free-text inputs.
- Customer Store List brand filter chips now come from live sparepart device-model data.
- `StoreDiscoveryRepository.getStores()` now uses the public Dio client because store discovery is public.

### Docs
- Updated backend API reference and frontend customer docs for device-model discovery.

---

## 2026-06-11 — Major Refactor (Production Readiness)

### Backend Rewrite (Phase 1-5)
- **Common infrastructure:** Consolidated `normalizePhone`, `nanoid`, `password`, `encryption` into `common/utils/`
- **Config:** Added `validateConfig()` fail-fast for required env vars, removed JWT secret fallback
- **Types:** Added `AuthenticatedUser` interface, proper typing across all guards/decorators
- **Guards:** Fixed `any` types in `JwtAuthGuard`, `StoreJwtAuthGuard`, `RolesGuard`, `FirstLoginGuard`
- **Exceptions:** Added `ForbiddenException`, `NotFoundException`, `RateLimitExceededException`, `FileValidationException`
- **Health:** Added DB connectivity check, uptime, memory usage
- **Main:** Added `helmet()`, `compression()`, env validation, `enableShutdownHooks()`, conditional Swagger
- **Auth:** Fixed `changePassword` to only clear credentials on first login, proper typing
- **Store-auth:** Fixed imports, proper typing
- **Platform-admin:** Fixed imports, proper typing
- **Users:** Fixed `updateProfile` to use `UpdateProfileDto`, proper typing
- **Stores:** Fixed `findAll` to filter by brand/deviceModel, fixed `updateStoreProfile` to update store fields
- **Orders:** Fixed imports from `common/utils`, fixed `approveOrder` stock check, added `mark_complete` action, removed duplicate PATCH diagnosis
- **Payments:** Proper typing, `StoreConfig` interface
- **Reviews:** Use `generateCouponCode` from common utils, return `{ reviewId, couponCode }`
- **Disputes:** Use `generateOrderNumber` from common utils, proper typing
- **Spareparts:** Fixed delete to check OrderItem references, use `NotFoundException`
- **Notifications:** Added gateway URL validation, proper error typing
- **Uploads:** Added file type whitelist validation, proper typing
- **Jobs:** Fixed error typing in SLA monitor and credential cleaner
- **Dockerfile:** Moved `prisma generate` to build stage, added `USER node`, health check
- **tsconfig:** Enabled `noImplicitAny: true`, `noUnusedLocals`, `noUnusedParameters`
- **package.json:** Added `helmet`, `compression`, `@types/compression`, `lint` script

### Frontend Rewrite (Phase 6-10)
- **Core:** Fixed `app_config.dart` with `required` parameter, `api_exception.dart` with `const`
- **Network:** Fixed `dio_client.dart` timeout to 15s, fixed `network_error_mapper.dart` to extract `user_message`
- **Shared widgets:** Fixed `SearchFilterBar` with `onSearch` callback and `searchController`
- **Customer:** Fixed token key collision (`customer_access_token` instead of `access_token`)
- **Store admin:** Fixed `changePassword` field name (`oldPassword`), fixed `resolveDispute` format (`decision`/`storeResponse`), prefixed all routes with `/store/`, fixed `FutureBuilder` infinite loop in `TrackingScreen`, added form validation, added edit capability to `StoreSettingsScreen`
- **Platform admin:** Fixed session restore in `AdminAuthNotifier.build()`
- **main.dart:** Fixed all route conflicts with `/store/` prefix namespacing

### Play Store Readiness (Phase 11)
- **build.gradle.kts:** Added release signing config with `key.properties`, set `minSdk = 21`, enabled `minifyEnabled` and `shrinkResources`, added ProGuard rules
- **AndroidManifest.xml:** Fixed app label to `ServisGadget`, added `INTERNET`, `CAMERA`, `READ_MEDIA_IMAGES`, `READ_EXTERNAL_STORAGE` permissions
- **pubspec.yaml:** Updated version to `1.0.0+1`, added `assets/images/` section, removed unused `freezed_annotation`, `json_annotation`, `build_runner`, `freezed`, `json_serializable`
- **proguard-rules.pro:** Created with Flutter, flutter_secure_storage, image_picker, OkHttp rules
- **key.properties:** Created template (gitignored)
- **.gitignore:** Added `key.properties`, `*.jks`, `*.keystore`

### Testing (Phase 12)
- **Backend:** Added tests for state machine transitions, password generation, encryption roundtrip, phone normalization
- **Frontend:** Fixed `normalizePhone` test expectations (`0xxx` format), added `OrderStatus` tests, `CustomerUser` tests, `CouponReward` tests, `StoreOrderStatus` tests, `Sparepart` tests, `StoreAdminSession` tests, `DisputeStatus` tests

---

## 2026-06-10 — Comprehensive Documentation Update

### Documentation Restructure
- Split docs into `docs/backend/` and `docs/frontend/` for separate role clarity
- Created 5 backend docs + 5 frontend docs = 10 new comprehensive documentation files

### Backend Docs
- `BACKEND_API_REFERENCE.md` — Complete API reference (all endpoints, request/response, error codes)
- `BACKEND_DATABASE_SCHEMA.md` — Prisma schema documentation (21 models, 20+ enums, relationships, indexes)
- `BACKEND_AUTH_SYSTEM.md` — 3 JWT auth systems (Customer, Store Admin, Platform Admin), stealth accounts, credential encryption, security features
- `BACKEND_BUSINESS_LOGIC.md` — Order lifecycle, state machine, SLA system, payments, reviews, disputes, store matching, notifications
- `BACKEND_SETUP.md` — Environment variables, Docker setup, deployment (Render), project structure

### Frontend Docs
- `FRONTEND_ARCHITECTURE.md` — Flutter app structure, clean architecture layers, Riverpod providers, GoRouter routing, shared widgets
- `FRONTEND_CUSTOMER.md` — Customer feature docs (models, repos, providers, 24+ screens, widgets)
- `FRONTEND_STORE_ADMIN.md` — Store admin feature docs (models, repos, providers, 18+ screens, responsive layout)
- `FRONTEND_PLATFORM_ADMIN.md` — Platform admin feature docs (models, repos, 2 screens)
- `FRONTEND_NETWORK_LAYER.md` — Dio client, error handling, token management, repository pattern, provider system

### Purpose
- Enable AI agents to understand the full codebase by reading documentation alone
- Provide team members clear reference without reading source code
- Standardize documentation format across frontend/backend

---

## 2026-06-06 — UI/UX Rework, Admin Platform, Play Store Readiness

### Welcome Page Rework
- 4-button landing page: Service Now, Pelanggan, Toko, Admin
- Service Now → multi-step booking flow (5 steps sesuai PRD master)
- Pelanggan → customer login, Toko → store admin login, Admin → platform admin login

### Multi-Step Booking Flow (PRD Master Alignment)
- Step 1: Pilih device type (Android/iOS) + brand + model
- Step 2: Pilih layanan + isi complaint
- Step 3: Auto-match toko via Matching Engine (`GET /v1/stores/match`)
- Step 4: Isi data diri + metode pengiriman
- Step 5: Konfirmasi estimasi + buat booking

### Matching Engine (New)
- `GET /v1/stores/match?brand=&deviceModel=&partType=` — filter toko by brand, model, part type, stock > 0, isActive
- Return store info, matched spareparts, estimated cost

### Bug Fixes (Backend)
- **itemPrice**: sekarang hanya `sparepart.price`, tidak lagi include `service_fee` (PRD AC-11)
- **Approve stock leak**: `approveOrder` dan `updateStatus` sekarang handle semua item (confirmed + replaced)
- **DTO**: backend menerima `fullName` dan `customerName` via `@Transform`
- **Route conflict**: store admin login `/login` → `/store-login`

### Platform Admin (New)
- Model: `PlatformAdmin` — username, password_hash, full_name
- `POST /v1/platform/login` — admin login (JWT 12h)
- `POST /v1/platform/stores` — buat toko + admin toko sekaligus, set device types (Android/iOS)
- `GET /v1/platform/stores` — daftar semua toko
- Frontend: `/admin/login`, `/admin/dashboard` — create store form + store list
- Seed: username `admin` / password `admin`

### Phone Format: +62 → 08
- Semua `normalizePhone` di backend dan frontend diubah ke format `08xxxxxxxx`
- UI prefixText diubah dari `+62` ke `08`
- Seed data diupdate

### Dummy Cleanup
- 28 file dibersihkan: 24 dummy screens + 4 demo auth/data/widgets

### Deployment Ready
- Dockerfile optimized untuk cloud deployment (multi-stage build)
- `render.yaml` untuk one-click Render deploy
- `app_config.dart` mendukung `--dart-define=API_BASE_URL=` untuk production
- Tidak ada ketergantungan Docker/Redis untuk development (langsung `npm run start:dev`)
- `.env.example` lengkap dengan semua required env vars

### Store Registration (New)
- `POST /v1/store/register` — public endpoint untuk self-registration toko
- DTO: storeName, address, storePhone, applicantName, applicantPhone, password

---

## 2026-06-06 — Phase 3 Store Admin Merge + Full API Alignment

### Backend (15+ Endpoint Baru)
- `POST /v1/store/auth/logout` — store admin logout
- `POST /v1/store/orders/:id/actions/:action` — dynamic action endpoint (state machine mapping)
- `GET /v1/store/orders/:id/tracking` — tracking timeline
- `POST /v1/store/orders/:id/tracking` — manual tracking entry
- `GET /v1/store/customers` — customer list per store
- `GET /v1/store/payments` — payment list per store
- `GET /v1/store/reviews` — review list per store
- `POST /v1/store/reviews/:id/response` — respond to review
- `GET /v1/store/notifications` — notification feed
- `GET /v1/store/profile` — store admin profile + store info
- `PATCH /v1/store/profile` — update profile
- `GET /v1/store/analytics` — 30-day analytics (orders, revenue, rating)
- `POST /v1/store/orders/:id/payments/:paymentId/confirm` — payment confirmation
- `PATCH /v1/store/orders/:id/diagnosis` — diagnosis update
- Extended StoresService, OrdersService, StoreOrdersController

### Flutter — Store Admin App (Phase 3)
- `frontend/lib/features/store_admin/` — 14+ screens
- GoRouter with auth guard, store login/change-password, dashboard (60s polling)
- Screens: StoreLogin, StoreChangePassword, Dashboard, OrderList, OrderDetail, Diagnosis, Tracking, Inventory, SparepartForm, PaymentConfirmation, DisputeList, DisputeDetail, Settings
- Providers: StoreAuthController, DashboardSummary (Stream), StoreOrderDetail, InventoryList
- Repositories: StoreAuthRepository, StoreOrderRepository, StoreInventoryRepository, StoreDisputeRepository
- Widgets: CredentialPanelCard, DiagnosisItemRow, InventoryItemCard, SlaCountdownBadge, PaymentProofViewer
- Models: ServiceOrder, Sparepart, DisputeCase, DashboardSummary, CredentialPanel, StoreSession, ReviewItem, AnalyticsData

### Flutter — Combined Entrypoint
- Role-based splash router (`main.dart`) — auto-detect customer vs store admin auth session
- Separate Dio clients and token storage per role

---

## 2026-06-06 — Phase 1 Foundation Complete + Phase 2 Customer Merge

### Backend — Phase 1 Foundation (Complete)
- **Orders module**: createOrder (stealth account, stock reservation, coupon validation, nanoid), approveOrder, rejectOrder, updateStatus (state machine + SLA reset), submitDiagnosis
- **Payments module**: createPayment (proof validation), confirmPayment (warranty assignment, totalCompleted)
- **Reviews module**: createReview (duplicate check, ratingAvg recalculation, reward coupon in transaction)
- **Disputes module**: createDispute (warranty check, active guard), respondDispute (warranty order creation)
- **Notifications module**: WhatsApp send with 3x exponential retry + FailedNotification logging
- **Uploads module**: S3 presigned URL generation
- **Jobs module**: SlaMonitorJob (30s cron), CredentialCleanerJob (30min cron)
- **Auth**: Separate customer (`POST /v1/auth/*`) and store admin (`POST /v1/store/auth/*`) JWT strategies
- **11 Bug Fixes** from PRD: B1–B11 (itemPrice, qtyReserved, coupon ownership, warrantyDays, ratingAvg, nanoid, etc.)

### Flutter — Customer App (Phase 2)
- `frontend/lib/features/customer/` — 15+ screens
- GoRouter with auth guard, Riverpod state management
- Screens: Splash, Login, ChangePassword, Home, StoreList, StoreDetail, BookingForm, BookingSuccess, OrderList, OrderDetail, Tracking, PaymentUpload, ReviewForm, ReviewSuccess, WarrantyClaim, Profile, Sessions
- Providers: AuthNotifier, OrderTracking (30s polling Stream), CustomerOrders, OrderDetail
- Repositories: CustomerAuthRepository, StoreRepository, OrderRepository, PaymentRepository, ReviewRepository, DisputeRepository
- Error handler mapping API errors to Bahasa Indonesia messages
- Widgets: OrderStatusTimeline, StoreCard, DiagnosisApprovalCard, SparePartSelectorSheet, CouponRewardBanner

### API Path Alignment
- Payments/Reviews/Disputes nested under `/v1/orders/:id/...` (Master PRD contract)
- Upload presigned URL: `POST /v1/uploads/presign`
- Store diagnosis/status: PATCH instead of POST
- Customer endpoints: `GET /v1/me/orders`, `/v1/me/summary`, `/v1/me/orders/:id/progress`, `/v1/me/notifications`
- Spareparts GET made public for store detail screen

---

## 2026-06-02 — Phase 1 Bootstrap & Early Scaffolds

### Bootstrap
- Monorepo layout: `backend/`, `frontend/`, `docs/`, `infra/`
- NestJS 10.x runnable shell, strict TypeScript config, Swagger at `/docs`
- Prisma schema extracted from Master PRD (21 models, 20+ enums)
- Flutter shared foundation: Dio client, token storage, error mapper, base repository, API models
- Docker Compose: PostgreSQL 16, Redis 7, backend service

### Scaffold Iterations (5 commits)
- Dummy login (Customer + Admin Toko), role-based bottom navigation
- Shell screens for all customer and store admin flows
- Reusable widgets: StatusBadge, SectionHeader, KeyValueRow, SearchFilterBar, SlaCountdownBadge, CredentialPanelCard
- Flutter widget test updated from counter template to ServisGadgetApp

### Audit
- Foundation status audit: identified 37+ gaps
- Flutter Android launch verified successfully
- Stop boundary defined for Phase 2/3 work

---

**Status: All 3 phases complete — merged into `main`.**
