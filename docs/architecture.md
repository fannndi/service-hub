# ServisGadget — Architecture

> **Versi:** 2.0 — 2026-06-17
> **Status:** Production Ready (175 tests, 30/30 ACs)

---

## 1. System Overview

ServisGadget adalah platform marketplace servis gadget dua sisi:
- **Customer**: Booking perbaikan tanpa daftar akun (stealth account)
- **Store Admin**: Kelola order, diagnosa, stok, pembayaran dari mobile app
- **Platform Admin**: Buat toko, set device types, kelola akun

---

## 2. Tech Stack

### Backend
| Component | Version |
|-----------|---------|
| Node.js | 20.x LTS |
| TypeScript | 5.x (strict: true) |
| NestJS | 10.x |
| Prisma | 5.x |
| PostgreSQL | 16 |
| Redis | 7.x |
| Jest | 29.x |

### Frontend
| Component | Version |
|-----------|---------|
| Flutter | 3.4+ |
| Dart | 3.x |
| Riverpod | 2.5.1 |
| GoRouter | 14.2.0 |
| Dio | 5.4.3+1 |

---

## 3. Backend Architecture

### Module Structure (15 modules)

```
backend/src/
├── common/                        Shared layer
│   ├── config.controller.ts       Public /config endpoint
│   ├── health.controller.ts       /v1/health endpoint
│   ├── maintenance.middleware.ts   Global maintenance mode
│   ├── constants/                 SLA constants
│   ├── decorators/                @GetUser, @Roles
│   ├── exceptions/                19 custom exception classes
│   ├── filters/                   GlobalExceptionFilter
│   ├── guards/                    Jwt, StoreJwt, Roles, FirstLogin
│   ├── interceptors/              ResponseInterceptor
│   ├── logger/                    nestjs-pino config
│   ├── prisma/                    PrismaService
│   ├── types/                     JwtPayload, AuthenticatedUser
│   └── utils/                     phone, nanoid, password, encryption
│
├── config/                        Typed environment configuration
│   └── configuration.ts
│
└── modules/
    ├── auth/                      Customer authentication
    │   ├── auth.controller.ts       POST /auth/login, /auth/refresh, /auth/change-password
    │   ├── auth.service.ts          Login, refresh, changePassword, autoCreateAccount
    │   └── strategies/              JwtAccess, JwtRefresh
    │
    ├── store-auth/                Store admin authentication
    │   ├── store-auth.controller.ts POST /store/auth/login, /store/auth/change-password
    │   ├── store-auth.service.ts    Login with storeId JWT, store.isActive check
    │   └── strategies/              StoreJwtAccess, StoreJwtRefresh
    │
    ├── platform-admin/            Platform admin authentication
    │   ├── platform-admin.controller.ts  POST /platform/login, /platform/stores
    │   ├── platform-admin.service.ts     Admin login, store provisioning
    │   ├── platform-admin.guard.ts       Role-based guard
    │   └── strategies/                   PlatformAdminJwtStrategy
    │
    ├── users/                     Customer self-service
    │   ├── users.controller.ts      /me endpoints
    │   └── users.service.ts         Profile, coupons, notifications, sessions
    │
    ├── stores/                    Store management + dashboard
    │   ├── stores.controller.ts     Public store list, match, dashboard, analytics
    │   └── stores.service.ts        findStore, getDashboard, getAnalytics, updateConfig
    │
    ├── store-register/            Store self-registration
    │   └── store-register.service.ts  Register new store
    │
    ├── spareparts/                Inventory management
    │   ├── spareparts.controller.ts CRUD spareparts
    │   └── spareparts.service.ts    create, update (qty guard), delete, findAvailable
    │
    ├── orders/                    Order lifecycle (CORE)
    │   ├── orders.controller.ts     Customer endpoints: create, approve, reject
    │   ├── store-orders.controller.ts  Store endpoints: status, diagnosis, tracking
    │   ├── orders.service.ts        Business logic: stock, state machine, diagnosis
    │   └── utils/state-machine.util.ts  11-state transition validator
    │
    ├── payments/                  Payment processing
    │   ├── payments.controller.ts   createPayment, confirmPayment
    │   └── payments.service.ts      Warranty assignment, totalCompleted
    │
    ├── reviews/                   Customer reviews
    │   ├── reviews.controller.ts    createReview
    │   └── reviews.service.ts       Rating recalculation, coupon generation
    │
    ├── disputes/                  Warranty claims
    │   ├── disputes.controller.ts   createDispute, respondDispute
    │   └── disputes.service.ts      Warranty order creation
    │
    ├── notifications/             WhatsApp + Email
    │   └── notifications.service.ts 3x retry, email fallback, templates
    │
    ├── uploads/                   File upload (S3 presigned)
    │   ├── uploads.controller.ts    POST /uploads/presign
    │   └── uploads.service.ts       S3 presigned URL generation
    │
    ├── jobs/                      Background cron jobs
    │   ├── sla-monitor.job.ts       30s cron — SLA breach detection + auto-cancel
    │   └── credential-cleaner.job.ts  30min cron — credential cleanup
    │
    └── redis/                     Cache layer
        └── redis.service.ts         Cache-aside with graceful degradation
```

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| 3 JWT systems | Customer, Store Admin, Platform Admin — different secrets, different payload |
| Stealth accounts | Customer booking tanpa daftar — akun dibuat otomatis |
| State machine | 11 order statuses, 15 valid transitions, strict validation |
| Stock reservation | qtyReserved increment at booking, qty decrement at approval |
| SLA system | Per-stage SLA (24h/48h), auto-cancel after 24h breach |

---

## 4. Frontend Architecture

### Feature Structure

```
frontend/lib/
├── main.dart                    App entry, GoRouter, auth redirect
├── core/
│   ├── app_config.dart          Environment config (local/production)
│   ├── config/config_service.dart  Server config fetch (maintenance mode)
│   ├── domain/order_status.dart   Canonical enums (OrderStatus, PaymentRecordStatus, DisputeStatus)
│   ├── domain/address_models.dart  Indonesian address hierarchy
│   ├── data/address_repository.dart  Local JSON asset loader
│   ├── widgets/address_dropdowns.dart  Cascading Province→City→District→Village
│   ├── json_helpers.dart        12+ shared JSON helpers
│   └── api_exception.dart       Custom exception class
├── network/
│   ├── api_client.dart          createApiClient + createAuthDio (401→refresh→retry)
│   └── network_error_mapper.dart  DioError → ApiException mapping
├── storage/
│   └── token_storage.dart       FlutterSecureStorage abstraction
├── shared_widgets/
│   ├── status_badge.dart        Colored pill badge
│   ├── empty_state.dart         Empty state placeholder
│   ├── error_state.dart         Error + retry widget
│   └── formatters.dart          formatRupiah(), formatShortDate()
└── features/
    ├── customer/                28 screens, 10 models, 16+ providers
    │   ├── presentation/        screens/, widgets/, routing/
    │   ├── application/         customer_providers.dart
    │   ├── data/                customer_repositories.dart (11 classes)
    │   └── domain/              10 model files + barrel
    ├── store_admin/             17 screens, 9 models, 14+ providers
    │   ├── presentation/        screens, widgets, routing (responsive)
    │   ├── application/         store_admin_providers.dart
    │   ├── data/                store_admin_repositories.dart (3 classes)
    │   └── domain/              9 model files + barrel
    ├── platform_admin/          2 screens, 2 providers
    │   ├── presentation/        screens, routing
    │   ├── application/         platform_admin_providers.dart
    │   ├── data/                platform_admin_repositories.dart
    │   └── domain/              platform_admin_models.dart
    └── maintenance/             1 screen (offline/maintenance mode)
```

### Responsive Layout Breakpoints

| Width | Layout |
|-------|--------|
| >= 1200px | NavigationRail (extended) + large content |
| >= 900px | NavigationRail (compact) |
| < 900px | NavigationBar (bottom) + Drawer (mobile) |

---

## 5. Testing Architecture

| Layer | Tests | Suites | Tools |
|-------|-------|--------|-------|
| Backend unit | 57 | 5 | Jest + ts-jest |
| Backend security | 30 | 3 | Jest + PrismaMock |
| Backend integration | 65 | 4 | Jest + PrismaMock |
| Frontend widget | 9 | 3 | flutter_test |
| Frontend model/unit | 14 | 2 | flutter_test |
| **Total** | **175** | **17** | |

### Test Infrastructure

- **PrismaMock**: In-memory Prisma substitute (CRUD, transactions, aggregations)
- **TestFactory**: Seed data generators (stores, users, admins, spareparts)
- **TDD Workflow**: RED→GREEN→REFACTOR with evidence reports

---

## 6. Security Model

| Check | Location | Severity |
|-------|----------|----------|
| IDOR protection | submitDiagnosis — orderItem ownership | HIGH |
| Stock over-commitment | sparepart update — qty < qtyReserved | HIGH |
| Store deactivation | store auth login — store.isActive | HIGH |
| Rate limiting | store login — 5 req/60s | MEDIUM |
| JWT separation | 3 systems with different secrets | CRITICAL |
| Credential encryption | AES-256-GCM for stealth passwords | HIGH |
| SLA monitoring | Auto-cancel with stock rollback | MEDIUM |

---

*Architecture v2.0 — ServisGadget Production Ready*
