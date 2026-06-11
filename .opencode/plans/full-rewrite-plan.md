# ServisGadget — Full Rewrite Plan

## Overview

Major refactor seluruh codebase ServisGadget (backend NestJS + frontend Flutter) untuk mencapai production-ready quality. Berdasarkan analisis mendalam yang menemukan **183+ issues** termasuk bugs, security vulnerabilities, missing implementations, dan code quality problems.

**Goal:** App siap deploy ke Play Store dengan skor kesiapan 9/10 (dari 4/10 saat ini).

---

## Execution Strategy: Full Rewrite Per Module

Setiap module di-rewrite dari awal dengan:
- Proper TypeScript strict mode (no `any`)
- DTO validation di semua endpoints
- Consolidated shared utilities
- Security hardening
- Production-ready deployment config

---

## Phase 1: Backend Common Infrastructure

### 1.1 New Files to Create

#### `src/common/utils/phone.util.ts`
- Single `normalizePhone()` function (consolidate dari 3 definisi)
- Format: `0xxx` (strip non-digits, convert `62xxx` → `0xxx`)

#### `src/common/utils/nanoid.util.ts`
- Single `nid` instance (consolidate dari 3 inisialisasi)
- `generateOrderNumber()` → `SG-YYYYMMDD-XXXX`
- `generateCouponCode()` → `RWD-{timestamp36}-{rand4}`

#### `src/common/utils/password.util.ts`
- `generatePassword(fullName, phoneNumber)` — deterministic dari nama + 4 digit terakhir phone

#### `src/common/utils/encryption.util.ts`
- `encryptCredential(plaintext, hexKey)` — AES-256-GCM
- `decryptCredential(ciphertext, hexKey)` — AES-256-GCM
- Key passed as parameter (bukan `process.env` langsung)

#### `src/common/utils/index.ts`
- Barrel export semua utilities

### 1.2 Files to Rewrite

#### `src/config/configuration.ts`
- **Add:** `validate()` function — fail-fast jika required env vars missing
- **Fix:** Remove `platformAdminSecret` fallback ke `storeAccessSecret`
- **Add:** Type-safe config interface

#### `src/common/types/jwt-payload.type.ts`
- **Add:** `PlatformAdminPayload` interface
- **Add:** `AuthenticatedUser` interface (proper typing, no `any`)

#### `src/common/guards/jwt-auth.guard.ts`
- **Fix:** Remove `any` types, use `AuthenticatedUser`

#### `src/common/guards/store-jwt-auth.guard.ts`
- **Fix:** Remove `any` types

#### `src/common/guards/roles.guard.ts`
- **Fix:** Proper typing

#### `src/common/guards/first-login.guard.ts`
- **Fix:** Proper typing

#### `src/common/decorators/get-user.decorator.ts`
- **Fix:** Return `AuthenticatedUser` instead of `any`

#### `src/common/filters/global-exception.filter.ts`
- **Add:** Request ID correlation
- **Fix:** Remove `as any` assertions
- **Add:** Log request context (method, url, IP)

#### `src/common/interceptors/response.interceptor.ts`
- **Add:** Response time header
- **Fix:** Remove `any` types

#### `src/common/exceptions/index.ts`
- **Add:** `ForbiddenException` (generic)
- **Add:** `NotFoundException` (generic)
- **Add:** `RateLimitExceededException`
- **Add:** `FileValidationException`

#### `src/common/health.controller.ts`
- **Fix:** Verify DB connectivity via `prisma.$queryRaw`
- **Add:** Check Redis connectivity
- **Add:** Return uptime, memory usage

#### `src/main.ts`
- **Add:** `helmet()` middleware
- **Add:** `compression()` middleware
- **Add:** Env validation at startup (call `validate()`)
- **Add:** `app.enableShutdownHooks()`
- **Fix:** Conditional Swagger (only in development)
- **Fix:** Multi-origin CORS support
- **Add:** Request logging middleware
- **Add:** Graceful shutdown handler

#### `src/app.module.ts`
- **Fix:** Import order (common modules first)
- **Add:** `CommonModule` that exports shared utilities

### 1.3 Config Files

#### `tsconfig.json`
- **Fix:** `noImplicitAny: true`
- **Add:** `noUnusedLocals: true`
- **Add:** `noUnusedParameters: true`

#### `package.json`
- **Add:** `helmet` dependency
- **Add:** `compression` dependency
- **Add:** `lint` script
- **Add:** `@types/compression` devDependency

#### `Dockerfile`
- **Fix:** Move `prisma generate` ke build stage
- **Fix:** Use `npm ci --omit=dev` di runner stage
- **Add:** `USER node` directive
- **Add:** Health check

#### `.dockerignore` (new)
- Exclude `node_modules`, `.git`, `dist`, `.env`

#### `prisma/seed.ts`
- **Fix:** Use env vars for all passwords
- **Fix:** Add proper error handling
- **Add:** Idempotent seeding

---

## Phase 2: Backend Auth Module Rewrite

### `src/modules/auth/`

#### `dto/auth.dto.ts`
- **Fix:** Import `normalizePhone` dari `common/utils` (hapus definisi lokal)
- **Add:** Proper validation decorators

#### `auth.service.ts`
- **Fix:** Import utilities dari `common/utils`
- **Fix:** `changePassword` — only clear `credentialPlainEnc` jika `isFirstLogin`
- **Add:** Proper typing (no `any`)
- **Fix:** `autoCreateAccount` — use shared `generatePassword` + `encryptCredential`

#### `auth.controller.ts`
- **Fix:** Use proper DTO types (no inline types)
- **Add:** Rate limiting decorator untuk login endpoint

#### `strategies/jwt-access.strategy.ts`
- **Fix:** Validate `jwt.accessSecret` exists at startup
- **Fix:** Return `AuthenticatedUser` type

#### `strategies/jwt-refresh.strategy.ts`
- **Fix:** Same as above

#### `utils/password.util.ts` → DELETE (moved to common/utils)
#### `utils/encryption.util.ts` → DELETE (moved to common/utils)

---

## Phase 3: Backend Store-Auth Module Rewrite

### `src/modules/store-auth/`

#### `store-auth.service.ts`
- **Fix:** Add session tracking (create `StoreAdminSession` or use token blacklist)
- **Fix:** `changePassword` — invalidate all sessions
- **Fix:** Import utilities dari `common/utils`

#### `store-auth.controller.ts`
- **Fix:** Implement proper logout (token invalidation)
- **Add:** Refresh token endpoint (currently missing)

#### `strategies/store-jwt-access.strategy.ts`
- **Fix:** Validate secret at startup
- **Fix:** Return proper typed user

---

## Phase 4: Backend Platform-Admin Module Rewrite

### `src/modules/platform-admin/`

#### `platform-admin.service.ts`
- **Fix:** `createStore` — set default config (`service_fee`, `warranty_days`)
- **Add:** Store application review endpoints
- **Add:** Store suspension/activation

#### `platform-admin.controller.ts`
- **Fix:** Use proper DTOs
- **Add:** Endpoints for store management

#### `dto/platform-admin.dto.ts`
- **Add:** `UpdateStoreDto`, `SuspendStoreDto`

---

## Phase 5: Backend Business Modules Rewrite

### `src/modules/users/`
- **Fix:** `updateProfile` — use `UpdateProfileDto` (currently inline type, no validation)
- **Fix:** Remove `_userId` naming convention

### `src/modules/stores/`
- **Fix:** `findAll` — implement brand/deviceModel filtering
- **Fix:** `updateStoreProfile` — actually update storeName, operationalHours
- **Fix:** `updateConfig` — add DTO validation
- **Fix:** `respondToReview` — persist response (currently no-op)
- **Fix:** Consolidate store-facing endpoints

### `src/modules/orders/`
- **Fix:** `createOrder` — add rate limiting for public endpoint
- **Fix:** `approveOrder` — fix stock check (`qty - qtyReserved`)
- **Fix:** Import `nanoid` dari `common/utils`
- **Fix:** `submitDiagnosis` — remove duplicate PATCH endpoint
- **Fix:** `mark_complete` action — implement or remove from action map
- **Fix:** Use proper DTOs everywhere

#### `utils/state-machine.util.ts`
- **Fix:** Add `mark_complete` → `completed` transition
- **Add:** Export `ACTION_STATUS_MAP`

#### `dto/order.dto.ts`
- **Fix:** Import `normalizePhone` dari `common/utils`
- **Add:** `deliveryAddress` validation for `courier_pickup`

### `src/modules/payments/`
- **Fix:** Use proper DTOs
- **Fix:** `confirmPayment` — proper error handling

### `src/modules/reviews/`
- **Fix:** Import `nanoid` dari `common/utils`
- **Fix:** Response shape — return `{ reviewId, couponCode }` consistently

### `src/modules/disputes/`
- **Fix:** Use proper DTOs
- **Fix:** `respondDispute` — accept `{ decision, storeResponse }` format

### `src/modules/spareparts/`
- **Fix:** `delete` — check OrderItem references before delete
- **Fix:** Implement `search` query param
- **Fix:** Proper error (not `StoreNotActiveException` for "not found")

### `src/modules/notifications/`
- **Fix:** Validate `WA_GATEWAY_URL` before sending
- **Fix:** Use `axios` field names correctly (`target`, `message`, `countryCode`)
- **Add:** Proper error handling (don't crash on undefined URL)

### `src/modules/uploads/`
- **Fix:** Add file type whitelist (image/* only)
- **Fix:** Add file size limit (5MB)
- **Fix:** Response field — return `{ uploadUrl, fileUrl }` (align with frontend)

### `src/modules/jobs/`
- **Fix:** `sla-monitor.job.ts` — fix cron schedule docs (30s not 5min)
- **Fix:** Stock reversal logic consistency
- **Fix:** `credential-cleaner.job.ts` — proper error handling

---

## Phase 6: Frontend Core + Shared Layer Rewrite

### `lib/core/`
- **Fix:** `app_config.dart` — use `String.fromEnvironment` with `required`
- **Fix:** `api_exception.dart` — add `const` constructor

### `lib/network/`
- **Fix:** `dio_client.dart` — timeout 15s, proper error mapping
- **Fix:** `network_error_mapper.dart` — return `DioException` with `ApiException`

### `lib/storage/token_storage.dart`
- **Fix:** Interface methods: `saveAccessToken`, `readAccessToken`, `clear`
- **Fix:** Use separate keys per role (`customer_access_token`, `store_access_token`, `admin_access_token`)

### `lib/shared_widgets/`
- **Consolidate:** Merge all duplicate widgets into single implementations
- **Fix:** `SearchFilterBar` — add `onChanged` callback
- **Remove:** Dead code widgets that are never used

### `lib/models/api_response.dart`
- **Remove:** Dead code (never used)

### `lib/repositories/base_repository.dart`
- **Remove:** Dead code (never extended)

---

## Phase 7: Frontend Customer Feature Rewrite

### `lib/features/customer/domain/`
- **Split:** `customer_models.dart` (524 lines) into individual model files
- **Fix:** All model field names and types per source code

### `lib/features/customer/data/`
- **Fix:** `customer_repositories.dart` — fix token key collision, endpoint paths
- **Fix:** `normalizePhone` — align with backend format
- **Fix:** `parseApiError` — safe cast for error codes

### `lib/features/customer/application/`
- **Fix:** `customer_providers.dart` — add `.autoDispose` to polling providers
- **Fix:** Provider return types

### `lib/features/customer/presentation/`
- **Split:** `customer_screens.dart` (2162 lines) into individual screen files
- **Fix:** Route conflicts (prefix with `/customer/` where needed)
- **Fix:** `DropdownButtonFormField` — `initialValue` → `value`
- **Fix:** Text controller initialization (move to `initState`)
- **Fix:** `StoreListScreen` search — add debounced live search
- **Add:** Form validation where missing

### `lib/features/customer/presentation/routing/`
- **Fix:** Remove duplicate routes that conflict with `main.dart`
- **Fix:** Remove dead `customerRouterProvider`

---

## Phase 8: Frontend Store Admin Feature Rewrite

### `lib/features/store_admin/domain/`
- **Split:** `store_admin_models.dart` (483 lines) into individual files
- **Fix:** All model field names (`adminId`, `adminName`, `statusBreakdown`, etc.)

### `lib/features/store_admin/data/`
- **Fix:** `store_admin_repositories.dart` — fix `changePassword` field name, `resolveDispute` format
- **Fix:** Session storage method names

### `lib/features/store_admin/application/`
- **Fix:** Provider names (`storeAuthControllerProvider`)
- **Fix:** Add `.autoDispose` to polling providers
- **Fix:** Provider types (`AsyncNotifierProvider` for payments/disputes)

### `lib/features/store_admin/presentation/`
- **Split:** `store_admin_screens.dart` into individual files
- **Fix:** Route conflicts (prefix with `/store/`)
- **Fix:** `FutureBuilder` infinite loop in `TrackingScreen`
- **Add:** Form validation for all forms
- **Fix:** Export button implementation
- **Fix:** `StoreSettingsScreen` — add edit capability

---

## Phase 9: Frontend Platform Admin Feature Rewrite

### `lib/features/platform_admin/`
- **Fix:** `AdminAuthNotifier.build()` — implement session restore
- **Fix:** Password field — add `obscureText`
- **Fix:** `StoreListItem.createdAt` type (`String` not `DateTime`)

---

## Phase 10: Frontend main.dart Rewrite

### `lib/main.dart`
- **Fix:** Route conflicts — use namespaced routes:
  - Customer: `/customer/*`
  - Store Admin: `/store/*`
  - Platform Admin: `/admin/*`
- **Fix:** Splash logic — proper role-based redirect
- **Fix:** Remove duplicate route definitions
- **Add:** Proper loading states during auth check

---

## Phase 11: Play Store Readiness

### `android/app/build.gradle.kts`
- **Fix:** Release signing config (create keystore)
- **Fix:** Set `minSdk = 21`
- **Add:** `minifyEnabled = true` for release
- **Add:** ProGuard rules

### `android/app/src/main/AndroidManifest.xml`
- **Fix:** App label → `ServisGadget`
- **Add:** `INTERNET` permission
- **Add:** `CAMERA` permission
- **Add:** `READ_MEDIA_IMAGES` permission

### `pubspec.yaml`
- **Fix:** Version → `1.0.0+1`
- **Add:** `assets:` section
- **Remove:** Unused dependencies (`freezed_annotation`, `json_annotation` if not implementing)
- **Add:** `flutter_launcher_icons` config

### App Icon + Splash
- Replace default Flutter icon with branded ServisGadget icon
- Configure branded splash screen

---

## Phase 12: Testing

### Backend Tests (new files)
- `test/utils/phone.util.spec.ts` — normalizePhone tests
- `test/utils/password.util.spec.ts` — generatePassword tests
- `test/utils/encryption.util.spec.ts` — encrypt/decrypt roundtrip
- `test/orders/state-machine.spec.ts` — all valid transitions
- `test/orders/orders.service.spec.ts` — createOrder, approveOrder, rejectOrder
- `test/payments/payments.service.spec.ts` — confirmPayment
- `test/disputes/disputes.service.spec.ts` — respondDispute
- `test/auth/auth.service.spec.ts` — login lockout, token rotation

### Frontend Tests (fix + new)
- **Fix:** `customer_repository_test.dart` — normalizePhone expectations
- **Add:** Model parsing tests for all models
- **Add:** Provider tests for auth controllers
- **Add:** Widget tests for key screens

---

## Phase 13: Documentation Sync

- Fix all 28 remaining doc discrepancies
- Update PRD phone format
- Fix password examples
- Fix SLA cron schedule
- Fix WhatsApp gateway field names
- Fix model counts (17 not 21)
- Fix screen counts
- Update CHANGELOG

---

## File Change Summary

| Category | New Files | Modified Files | Deleted Files |
|----------|-----------|----------------|---------------|
| Backend common | 5 | 15 | 0 |
| Backend modules | 0 | 14 | 4 |
| Backend config | 1 | 4 | 0 |
| Frontend core | 0 | 5 | 2 |
| Frontend customer | ~25 | 5 | 0 |
| Frontend store_admin | ~18 | 5 | 0 |
| Frontend platform_admin | 0 | 5 | 0 |
| Frontend main | 0 | 1 | 0 |
| Play Store config | 2 | 4 | 0 |
| Tests | ~12 | 1 | 0 |
| Docs | 0 | 10 | 0 |
| **Total** | **~63** | **~69** | **~6** |

---

## Execution Order

```
Phase 1  → Backend common infrastructure
Phase 2  → Backend auth module
Phase 3  → Backend store-auth module
Phase 4  → Backend platform-admin module
Phase 5  → Backend business modules (users, stores, orders, payments, reviews, disputes, spareparts, notifications, uploads, jobs)
Phase 6  → Frontend core + shared layer
Phase 7  → Frontend customer feature
Phase 8  → Frontend store admin feature
Phase 9  → Frontend platform admin feature
Phase 10 → Frontend main.dart (route conflicts)
Phase 11 → Play Store readiness
Phase 12 → Testing
Phase 13 → Documentation sync
```

Each phase will be committed separately for clean git history.
