# TODO — Remaining Tasks for AI Agent

> **Untuk AI Agent:** Baca file ini + dokumentasi di `docs/backend/` dan `docs/frontend/` sebelum mengerjakan.
> Setiap task sudah self-contained — cukup baca konteks di sini + file yang disebutkan.
> **Wajib:** Setelah selesai 1 task, update dokumentasi terkait di `docs/` agar sinkron dengan kode.

---

## P0 — Critical (Kerjakan Dulu)

### P0-0: Implement Dynamic Device Model Dropdown from Sparepart Data

**Goal:** Brand & device model di Service Now Step 1 dan StoreListScreen berisi data real-time dari sparepart di semua toko, bukan hardcoded.

**Backend — `StoresController` (path `stores`):**

1. **Tambah endpoint** `GET /stores/device-models` di `stores.controller.ts`:
   - **Kenapa di `StoresController`?** Karena `SparepartsController` ada di path `store/spareparts` (namespace store admin, pakai auth guard). `StoresController` di path `stores` sudah public (tanpa `@UseGuards`). Lihat `src/modules/stores/stores.controller.ts:9-10`.
   - Route: `@Get('device-models')`
   - Method baru di `StoresService`:
     ```typescript
     async getDeviceModels() {
       const results = await this.prisma.sparePart.findMany({
         where: { status: { not: 'discontinued' } },
         select: { brand: true, deviceModel: true },
         distinct: ['brand', 'deviceModel'],
         orderBy: [{ brand: 'asc' }, { deviceModel: 'asc' }],
       });
       const map = new Map<string, string[]>();
       for (const r of results) {
         if (!map.has(r.brand)) map.set(r.brand, []);
         map.get(r.brand)!.push(r.deviceModel);
       }
       return Array.from(map.entries()).map(([brand, models]) => ({ brand, models }));
     }
     ```
   - Response: `[{ brand: "Google", models: ["Pixel 3", "Pixel 4"] }, ...]`
     (interceptor otomatis bungkus ke `{ success: true, data: [...], timestamp: "..." }`)
   - No auth required (public endpoint)

**Frontend — Model baru:**

2. **File baru:** `frontend/lib/features/customer/domain/device_model.dart`
   ```dart
   class DeviceModelGroup {
     final String brand;
     final List<String> models;
     const DeviceModelGroup({required this.brand, required this.models});

     factory DeviceModelGroup.fromJson(Map<String, dynamic> json) =>
         DeviceModelGroup(
           brand: json['brand'] as String,
           models: (json['models'] as List).cast<String>(),
         );
   }
   ```

**Frontend — Repository:**

3. **Edit `customer_repositories.dart`** — tambah method di `StoreDiscoveryRepository`:
   ```dart
   Future<List<DeviceModelGroup>> getDeviceModels() async {
     final response = await _api.publicDio.get('/stores/device-models');
     return CustomerApiClient.unwrapList(response.data)
         .map(DeviceModelGroup.fromJson)
         .toList();
   }
   ```
   **WAJIB** pakai `_api.publicDio` (bukan `authDio`) karena Service Now bisa diakses sebelum login. File `customer_repositories.dart:178` saat ini salah pake `authDio` untuk `getStores()` — jangan ditiru.

**Frontend — Provider baru:**

4. **Edit `customer_providers.dart`** — tambah:
   ```dart
   final deviceModelsProvider = FutureProvider<List<DeviceModelGroup>>((ref) =>
       ref.watch(storeDiscoveryRepositoryProvider).getDeviceModels());
   ```

**Frontend — ServiceFlowScreen Step 1 (`customer_screens.dart:810-837`):**

5. **Edit class `_ServiceFlowScreenState`:**
   - **Ganti state:** `final _brand = TextEditingController()` → `String? _selectedBrand`
   - **Ganti state:** `final _model = TextEditingController()` → `String? _selectedModel`
   - Hapus `_brand.dispose()` dan `_model.dispose()` dari `dispose()`
   - **Ganti UI:** `TextField` → `DropdownButtonFormField<String>` untuk brand dan model
   - Brand dropdown: `ref.watch(deviceModelsProvider)`, pilih brand → simpan di `_selectedBrand`
   - Model dropdown: filter `models` dari brand yang dipilih, sorted alphabetical
   - User WAJIB klik (no auto-select, bahkan jika cuma 1 pilihan)
   - Loading state: `CircularProgressIndicator`
   - Empty state: "Belum ada sparepart tersedia"
   - Update `_matchStores()`: kirim `_selectedBrand!` dan `_selectedModel!` (bukan `_brand.text`)
   - Update `_createBooking()`: kirim `_selectedBrand!` dan `_selectedModel!` (bukan `_brand.text`)
   - Update `_nextStep()` (line 718): validasi `_selectedBrand != null && _selectedModel != null`

**Frontend — StoreListScreen brand chips (line 482-489):**

6. **Edit `StoreListScreen`:**
   ```dart
   // Sebelum:
   ['All', 'Samsung', 'Apple', 'Xiaomi', 'Oppo', 'Realme', 'Vivo']
   // Sesudah:
   final deviceModels = ref.watch(deviceModelsProvider);
   final brands = deviceModels.valueOrNull?.map((g) => g.brand).toList() ?? [];
   ['All', ...brands]
   ```

**Post-task:**
- Update `docs/backend/BACKEND_API_REFERENCE.md` §4 — tambah endpoint `GET /stores/device-models`
- Update `docs/frontend/FRONTEND_CUSTOMER.md` — update §1 (tambah model `DeviceModelGroup`), §2 (method `getDeviceModels`), §4 (perubahan Step 1 UI)

---

### P0-1: Split `customer_screens.dart` God File

**File:** `frontend/lib/features/customer/presentation/screens/customer_screens.dart` (2162 baris)

**Masalah:** 25 screen classes dalam 1 file. Sulit di-maintain, lambat di-compile, tidak scalable.

**Tugas:**
1. Buat folder `frontend/lib/features/customer/presentation/screens/` (sudah ada)
2. Pecah setiap screen class ke file terpisah:
   - `splash_screen.dart` — `SplashScreen`
   - `welcome_screen.dart` — `WelcomeScreen`
   - `login_screen.dart` — `LoginScreen`
   - `change_password_screen.dart` — `ChangePasswordScreen`
   - `home_screen.dart` — `HomeScreen`
   - `store_list_screen.dart` — `StoreListScreen`
   - `store_detail_screen.dart` — `StoreDetailScreen`
   - `service_flow_screen.dart` — `ServiceFlowScreen` (5-step wizard, 482 baris sendiri)
   - `booking_form_screen.dart` — `BookingFormScreen`
   - `booking_success_screen.dart` — `BookingSuccessScreen`
   - `order_list_screen.dart` — `OrderListScreen`
   - `order_detail_screen.dart` — `OrderDetailScreen`
   - `tracking_screen.dart` — `TrackingScreen`
   - `payment_upload_screen.dart` — `PaymentUploadScreen`
   - `review_form_screen.dart` — `ReviewFormScreen`
   - `review_success_screen.dart` — `ReviewSuccessScreen`
   - `warranty_claim_screen.dart` — `WarrantyClaimScreen`
   - `profile_screen.dart` — `ProfileScreen`
   - `coupons_screen.dart` — `CouponsScreen`
   - `notifications_screen.dart` — `NotificationsScreen`
   - `notification_detail_screen.dart` — `NotificationDetailScreen`
   - `notification_preferences_screen.dart` — `NotificationPreferencesScreen`
   - `sessions_screen.dart` — `SessionsScreen`
   - `security_screen.dart` — `SecurityScreen`
   - `diagnosis_approval_card.dart` — `DiagnosisApprovalCard` (widget, bukan screen)
3. Setiap file harus import dari `../../domain/customer_models.dart` dan `../../application/customer_providers.dart`
4. Update `customer_router.dart` untuk import dari file-file baru
5. Hapus `customer_screens.dart` setelah semua dipindah
6. Pastikan `flutter analyze` pass tanpa error

**Post-task:**
- Update `docs/frontend/FRONTEND_CUSTOMER.md` §4 — update jadi file list (bukan 1 file)
- Update `docs/frontend/FRONTEND_ARCHITECTURE.md` §2 — update tree structure

---

### P0-2: Fix `ServiceFlowScreen` Performance

**File:** `frontend/lib/features/customer/presentation/screens/service_flow_screen.dart` (setelah P0-1 split)

**Masalah:** 5-step wizard (482 baris) dengan 8 `TextEditingController`, `PageController`. Setiap `setState` rebuild seluruh wizard termasuk step yang tidak aktif.

**Tugas:**
1. Pecah `_buildStep1` sampai `_buildStep5` menjadi separate `StatefulWidget` classes
2. Setiap step widget terima callback `onNext(Map<String, dynamic> data)` untuk pass data ke parent
3. Parent `ServiceFlowScreen` simpan data per-step di `Map<String, dynamic> _stepData`
4. Hanya rebuild step yang aktif (gunakan `IndexedStack` atau conditional rendering)
5. Tambahkan `const` constructors di mana memungkinkan

**Post-task:**
- Update `docs/frontend/FRONTEND_CUSTOMER.md` §4 — update deskripsi ServiceFlowScreen

---

## P1 — High Priority

### P1-1: Consolidate Duplicate Widgets

**Masalah:** Widget serupa di-duplicate di 3 tempat:

| Widget | customer_widgets.dart | store_admin_widgets.dart | shared_widgets/ |
|--------|----------------------|-------------------------|-----------------|
| Status pill/badge | `StatusPill` | `StatusPill` | `StatusBadge` |
| Empty state | `EmptyMessage` | `EmptyPanel` | `EmptyState` |
| Error state | (inline) | `ErrorPanel` | `ErrorState` |
| Money formatter | `rupiah()` | `money()` | — |
| Date formatter | `shortDate()` | `dateText()` | — |
| Async page | `AsyncPage<T>` (AsyncValue) | `AsyncPage<T>` (AsyncSnapshot) | — |

**Tugas:**
1. Buat unified widgets di `shared_widgets/`:
   - `status_badge.dart` — sudah ada, extend untuk support `OrderStatus` enum (warna otomatis per status)
   - `empty_state.dart` — sudah ada, pastikan API konsisten
   - `error_state.dart` — sudah ada, tambahkan `onRetry` callback
   - Buat `formatters.dart` baru — `rupiah(num)`, `shortDate(DateTime?)`
   - Buat `async_page.dart` baru — support `AsyncValue` (Riverpod)
2. Update `customer_widgets.dart` dan `store_admin_widgets.dart` untuk import dari `shared_widgets/`
3. Hapus duplicate definitions

**Post-task:**
- Update `docs/frontend/FRONTEND_CUSTOMER.md` §5 — hapus duplicate widgets
- Update `docs/frontend/FRONTEND_STORE_ADMIN.md` §5 — hapus duplicate widgets
- Update `docs/frontend/FRONTEND_ARCHITECTURE.md` §7 — sinkronkan daftar shared_widgets

---

### P1-2: Implement Sessions Screen + Backend Endpoints

> **Gabungan P1-2 + P2-5.** Kedua task ini punya dependency: SessionsScreen butuh backend endpoints dulu.

**Backend — `UsersController` (path `me`):**

1. **Tambah `GET /me/sessions`** di `users.controller.ts`:
   - Route: `@Get('sessions')`
   - Service: query `UserSession` where `userId`, select `id, deviceInfo, ipAddress, lastActiveAt, isActive, createdAt`
   - Order by `lastActiveAt: desc`

2. **Tambah `DELETE /me/sessions/:id`** di `users.controller.ts`:
   - Route: `@Delete('sessions/:id')`
   - Service: `update` set `isActive: false` where `id` AND `userId` (security: cuma bisa hapus session sendiri)

3. **Tambah `DELETE /me/sessions`** (logout all) di `users.controller.ts`:
   - Route: `@Delete('sessions')`
   - Service: `updateMany` set `isActive: false` where `userId`

4. **Prisma:** Model `UserSession` sudah ada di `schema.prisma:504-516`.

**Frontend — `UsersController` bagian session belum ada endpoint sessions. UsersController saat ini (users.controller.ts:1-55) cuma punya profile, summary, coupons, orders, notifications.**

**Frontend — Repository:**

5. **Tambah method di repo (customer/data atau buat baru):**
   ```dart
   Future<List<UserSession>> getSessions() async { ... }
   Future<void> revokeSession(String id) async { ... }
   Future<void> logoutAll() async { ... }
   ```
   Semua pake `_api.authDio` (perlu login).

6. **Model baru `UserSession`:**
   ```dart
   class UserSession {
     final String id;
     final Map<String, dynamic>? deviceInfo;
     final String? ipAddress;
     final DateTime lastActiveAt;
     final bool isActive;
     final DateTime createdAt;
   }
   ```

**Frontend — SessionsScreen (`customer_screens.dart:2107-2117` — saat ini stub):**

7. **Rewrite `SessionsScreen`:**
   - Fetch sessions via provider
   - Tampilkan list session: device info, IP, last active, status badge
   - Tombol "Revoke" per session (kecuali session saat ini)
   - Tombol "Logout All" di AppBar
   - Konfirmasi dialog sebelum revoke/logout all
   - Loading/error state

**Frontend — SecurityScreen (`customer_screens.dart:2120-2133` — saat ini stub):**

8. **Rewrite `SecurityScreen`:**
   - Tampilkan: last password change date, active sessions count
   - Tombol "Ganti Password" (link ke `/change-password`)
   - Informasi nomor HP (hanya bisa diubah via support)

**Post-task:**
- Update `docs/backend/BACKEND_API_REFERENCE.md` §3 — tambah `GET /me/sessions`, `DELETE /me/sessions/:id`, `DELETE /me/sessions`
- Update `docs/frontend/FRONTEND_CUSTOMER.md` §4 — update SessionsScreen, SecurityScreen

---

### P1-3: Add Integration Tests (Backend)

**Files to create:**
- `backend/test/orders/orders.service.spec.ts`
- `backend/test/payments/payments.service.spec.ts`
- `backend/test/disputes/disputes.service.spec.ts`
- `backend/test/auth/auth.service.spec.ts`

**Test cases untuk orders.service.spec.ts:**
1. `createOrder` — success with stealth account creation
2. `createOrder` — success with existing user
3. `createOrder` — fails with inactive store
4. `createOrder` — fails with insufficient stock
5. `createOrder` — applies coupon discount correctly
6. `createOrder` — rejects expired coupon
7. `createOrder` — rejects coupon not owned by user
8. `approveOrder` — decrements qty and qtyReserved correctly
9. `approveOrder` — rejects invalid status transition
10. `rejectOrder` — decrements qtyReserved only
11. `submitDiagnosis` — calculates finalPrice correctly
12. `submitDiagnosis` — handles replaced sparepart stock swap

**Test cases untuk payments.service.spec.ts:**
1. `createPayment` — requires proofUrl for transfer_bank
2. `createPayment` — rejects order not in waiting_payment
3. `confirmPayment` — sets warranty, increments totalCompleted
4. `confirmPayment` — rejects order not in waiting_payment

**Test cases untuk disputes.service.spec.ts:**
1. `createDispute` — rejects expired warranty
2. `createDispute` — rejects duplicate active dispute
3. `respondDispute` — accepted creates warranty order
4. `respondDispute` — rejected updates status only

**Test cases untuk auth.service.spec.ts:**
1. `login` — locks account after 5 failed attempts
2. `login` — resets counter on success
3. `changePassword` — invalidates all sessions
4. `changePassword` — only clears credentialPlainEnc on first login
5. `refresh` — rotates token (invalidates old session)

**Setup:** Mock `PrismaService` dengan `jest.mock()`. Gunakan `@nestjs/testing` `Test.createTestingModule()`.

**Post-task:**
- Update `docs/backend/BACKEND_BUSINESS_LOGIC.md` — tambah catatan test coverage

---

### P1-4: Replace App Icon Placeholder

**File:** `frontend/assets/images/logo.png`

**Masalah:** File saat ini hanya placeholder text, bukan gambar asli. Di `main.dart:136` ada `errorBuilder` yang nangani kegagalan load (artinya icon memang rusak).

**Tugas:**
1. **Buat app icon 1024×1024 PNG** (gunakan AI image generator, Canva, atau minta desainer)
   - Tema: teal/green "ServisGadget" — huruf "SG" atau ikon kunci+obeng
2. Simpan sebagai `assets/images/logo.png` (TIMPA file placeholder yang ada)
3. Generate semua ukuran mipmap menggunakan `flutter_launcher_icons`:
   ```yaml
   # Tambah ke pubspec.yaml dev_dependencies:
   flutter_launcher_icons: ^0.13.1

   # Tambah config:
   flutter_launcher_icons:
     android: true
     image_path: "assets/images/logo.png"
     adaptive_icon_background: "#00897B"
     adaptive_icon_foreground: "assets/images/logo.png"
   ```
4. Run `dart run flutter_launcher_icons`
5. Verifikasi icon muncul di emulator (reboot app)

**Post-task:**
- Update `docs/frontend/FRONTEND_ARCHITECTURE.md` §2 — update assets tree

---

### P1-5: Add Rate Limiting for POST /orders

**File:** `backend/src/modules/orders/orders.controller.ts`

**Masalah:** `POST /orders` adalah endpoint publik (tanpa auth). Bisa di-spam untuk DoS. Lihat `orders.controller.ts:25-28`.

**Tugas:**
1. Import `@Throttle` dari `@nestjs/throttler`
2. Tambahkan decorator `@Throttle({ default: { limit: 5, ttl: 60000 } })` di method `createOrder`
3. Ini membatasi 5 request per menit per IP untuk endpoint ini
4. Test: kirim 6 request berturut-turut, pastikan request ke-6 return 429

**Post-task:**
- Update `docs/backend/BACKEND_API_REFERENCE.md` §5 — tambah catatan rate limiting
- Update `docs/backend/BACKEND_BUSINESS_LOGIC.md` §1 — tambah catatan di Order Creation

---

### P1-6: Consolidate Dio Client + Remove Dead Code

> **Gabungan P0-2 + P2-2.** Kerjakan sequential: step 1-3 dulu (consolidate), baru step 4-6 (hapus).

**Step 1 — Buat shared factory:**

Buat `frontend/lib/network/api_client.dart`:
```dart
Dio createApiClient(String baseUrl, {Future<String?> Function()? readToken}) {
  final dio = Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 20)));
  if (readToken != null) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await readToken();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
    ));
  }
  return dio;
}
```

**Step 2 — Refactor 3 feature Dio instances:**

- `CustomerApiClient` (`customer_repositories.dart:73-106`): ganti konstruksi Dio pake `createApiClient()`
- `storeAdminDioProvider` (`store_admin_repositories.dart`): ganti pake factory
- `AdminApiClient` (`platform_admin_repositories.dart`): ganti pake factory

**Step 3 — Hapus file dead code:**
- `frontend/lib/network/dio_client.dart` (27 baris) — `dioClientProvider` tidak dipakai siapapun
- `frontend/lib/repositories/base_repository.dart` (7 baris) — tidak di-extend
- `frontend/lib/models/api_response.dart` (5 baris) — tidak dipakai

**Step 4 — Hapus 3 router provider yang tidak dipakai:**
- `customer_router.dart:41-59` — `customerRouterProvider` tidak dipakai (main.dart pake `appRouterProvider`). Hapus `customerRouterProvider` dan `_RouterRefresh`, keep `customerRoutes` saja.
- `store_admin_router.dart:30-44` — `storeAdminRouterProvider` tidak dipakai. Hapus `storeAdminRouterProvider` dan `_RouterRefresh`, keep `storeAdminRoutes` saja.
- `platform_admin_router.dart:13-26` — `adminRouterProvider` tidak dipakai. Hapus `adminRouterProvider` dan `_AdminRefresh`, keep `adminRoutes` saja.

**Verifikasi:** `flutter analyze` harus pass, app harus bisa run.

**Post-task:**
- Update `docs/frontend/FRONTEND_ARCHITECTURE.md` §6 — update Network Layer section
- Update `docs/frontend/FRONTEND_CUSTOMER.md` §2 — hapus `dio_client.dart`
- Update `docs/frontend/FRONTEND_STORE_ADMIN.md` §2 — update Dio reference
- Update `docs/frontend/FRONTEND_ARCHITECTURE.md` §2 — remove `base_repository.dart` dan `api_response.dart` dari tree

---

## P2 — Medium Priority

### P2-1: Add CI/CD Pipeline

**File:** `.github/workflows/ci.yml` (baru)

**Tugas:**
```yaml
name: CI
on: [push, pull_request]
jobs:
  backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - run: cd backend && npm ci
      - run: cd backend && npx prisma generate
      - run: cd backend && npm run typecheck
      - run: cd backend && npm test

  frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.24.x' }
      - run: cd frontend && flutter pub get
      - run: cd frontend && flutter analyze
      - run: cd frontend && flutter test
```

**Post-task:**
- Update `README.md` — tambah badge CI status

---

### P2-2: Add Widget Tests

**Files to create:**
- `frontend/test/screens/home_screen_test.dart`
- `frontend/test/screens/login_screen_test.dart`
- `frontend/test/screens/order_list_screen_test.dart`
- `frontend/test/widgets/status_pill_test.dart`
- `frontend/test/widgets/store_card_test.dart`

**Test cases:**
1. HomeScreen renders summary tiles
2. LoginScreen shows error on invalid credentials
3. OrderListScreen shows 3 tabs (active/completed/cancelled)
4. StatusPill shows correct color per OrderStatus
5. StoreCard shows store name, address, rating

**Post-task:**
- Update `docs/frontend/FRONTEND_ARCHITECTURE.md` — tambah catatan test

---

### P2-3: Implement Branded Splash Screen

**File:** `frontend/android/app/src/main/res/drawable/launch_background.xml`

**Prasyarat:** P1-4 harus selesai dulu (file `logo.png` asli sudah ada).

**Tugas:**
1. Tambah `flutter_native_splash` ke dev_dependencies
2. Config di pubspec.yaml:
   ```yaml
   flutter_native_splash:
     color: "#00897B"
     image: assets/images/logo.png
     android: true
   ```
3. Run `dart run flutter_native_splash:create`
4. Verifikasi splash muncul sebelum app load

**Post-task:**
- Update `docs/frontend/FRONTEND_ARCHITECTURE.md` §8 — update Entry Point & Splash Logic

---

## Quick Reference

### File Structure
```
backend/
  src/common/utils/          ← Shared utilities (phone, nanoid, password, encryption)
  src/modules/               ← Business modules (auth, orders, payments, dll)
  prisma/schema.prisma       ← Database schema
  test/                      ← Backend tests

frontend/
  lib/core/                  ← AppConfig, ApiException
  lib/network/               ← Dio client, error mapper (api_client.dart setelah P1-6)
  lib/storage/               ← Token storage
  lib/shared_widgets/        ← Reusable widgets
  lib/features/customer/     ← Customer feature (clean architecture)
  lib/features/store_admin/  ← Store admin feature
  lib/features/platform_admin/ ← Platform admin feature
  test/                      ← Frontend tests
```

### Key Commands
```bash
# Backend
cd backend && npm run typecheck    # Type check
cd backend && npm test             # Run tests
cd backend && npm run start:dev    # Dev server

# Frontend
cd frontend && flutter analyze     # Lint + type check
cd frontend && flutter test        # Run tests
cd frontend && flutter run         # Run on emulator
```

### Documentation
- `docs/backend/BACKEND_API_REFERENCE.md` — All API endpoints
- `docs/backend/BACKEND_BUSINESS_LOGIC.md` — Order lifecycle, state machine
- `docs/backend/BACKEND_DATABASE_SCHEMA.md` — Prisma models
- `docs/frontend/FRONTEND_ARCHITECTURE.md` — Flutter app structure
- `docs/frontend/FRONTEND_CUSTOMER.md` — Customer feature details
- `docs/frontend/FRONTEND_STORE_ADMIN.md` — Store admin feature details

---

## P3 — AI Agent Tasks (ECC-Powered)

> Tasks ini dirancang untuk AI agent partner. Setiap task menunjuk skill ECC yang relevan.
> Baca `opencode-setup/Skill/skill-list.md` untuk detail skill.
> Baca `docs/` project untuk konteks bisnis sebelum mulai.

### P3-1: Full Security Audit

**ECC Skills:** `security-review`

**Scope:** 3 auth systems, payment flow, public endpoints, file uploads, secrets.

**Files to audit:**
- `backend/src/modules/auth/` — Customer JWT
- `backend/src/modules/store-auth/` — Store admin JWT
- `backend/src/modules/platform-admin/` — Platform admin JWT
- `backend/src/modules/orders/` — Public POST /orders (stealth)
- `backend/src/modules/payments/` — Payment flow
- `backend/src/common/guards/` — All guards

**Checklist:**
1. Rate limiting on ALL public endpoints
2. CSRF on payment endpoints
3. Input validation on all file uploads
4. No sensitive data in error responses
5. JWT secrets strength (256-bit minimum)
6. SQL injection: parameterized queries via Prisma
7. XSS: user content sanitized before render

**Deliverable:** `docs/security-audit.md`

---

### P3-2: Add Structured Logging

**ECC Skills:** `error-handling`

**Files:**
- `backend/src/common/logger/` — New Pino logger module
- `backend/src/common/filters/global-exception-filter.ts` — Enhance

**Tugas:**
1. `npm install nestjs-pino pino-http`
2. Log all requests: method, path, status, duration
3. Enhance exception filter: log full context (stack, body, user ID)
4. Environment-based log level (debug dev, info prod)

---

### P3-3: Redis Caching Layer

**ECC Skills:** `redis-patterns`

**Files:** `backend/src/modules/redis/` (empty placeholder → implement)

**Tugas:**
1. `RedisModule` + `RedisService` with cache-aside pattern
2. Cache `GET /stores` (TTL 300s)
3. Cache `GET /stores/match` (TTL 60s)
4. Invalidate on store update
5. Graceful degradation: fallback DB if Redis down

---

### P3-4: Production Readiness Audit

**ECC Skills:** `production-audit`, `deployment-patterns`, `docker-patterns`

**Files to audit:**
- `backend/Dockerfile` — Non-root, multi-stage, size
- `docker-compose.yml` — Resource limits, restart
- `render.yaml` — Deploy config

**Deliverable:** `docs/deployment.md` with runbook.

---

### P3-5: Database Query Optimization

**ECC Skills:** `postgres-patterns`, `prisma-patterns`

**Files:** `prisma/schema.prisma` + all service files

**Tugas:**
1. Fix N+1 queries (missing `include`/`select`)
2. Add `@@index` on frequently filtered fields
3. Pagination on `GET /stores`, `GET /orders`
4. Audit `distinct` queries on large tables

---

### P3-6: E2E API Tests

**ECC Skills:** `e2e-testing`

**Files:** `backend/test/e2e/` (new)

**Critical flows:**
1. Login → create order (stealth) → payment → success
2. Store admin login → manage orders → diagnosis
3. Platform admin → create store
4. Error: invalid JWT, expired, wrong role
5. Rate limiting: 6th request → 429

---

### P3-7: Code Quality Audit

**ECC Skills:** `refactor-cleaner`, `coding-standards`

**Tugas:**
1. Scan unused imports, `any` types
2. Replace `print()` with logger
3. Verify all responses use `{success, data, timestamp}` envelope
4. No empty `catch {}` blocks
5. Remove `// ignore_for_file` — fix root causes

---

### P3-8: Monitoring Metrics

**ECC Skills:** `dashboard-builder`

**Tugas:**
1. `@nestjs/terminus` + Prometheus metrics
2. Export: request count/duration, order rate, payment rate
3. Health checks: PostgreSQL, Redis, WhatsApp API

---

### P3-9: Flutter Performance

**ECC Skills:** `dart-flutter-patterns`

**Tugas:**
1. Add missing `const` constructors
2. Use `ListView.builder` + `itemExtent`
3. Image caching, preloading
4. Report APK size with `flutter build apk --release`
5. Profile startup with `--trace-startup`

---

### P3-10: WhatsApp Notification Fallback

**ECC Skills:** `error-handling`

**Current:** 3x retry Fonnte WhatsApp, no fallback.

**Tugas:**
1. Email fallback (SendGrid/SMTP) for critical: order created, payment confirmed
2. BullMQ queue for notifications with dead letter queue
3. Dashboard: notification failure rate

---

### Priority Reference

| Task | ECC Skill | Effort | Impact |
|------|-----------|--------|--------|
| P3-1: Security Audit | security-review | 2h | 🔴 Production safety |
| P3-2: Structured Logging | error-handling | 3h | 🔴 Debugging |
| P3-3: Redis Caching | redis-patterns | 4h | 🟡 Performance |
| P3-4: Production Audit | production-audit | 2h | 🔴 Deployment safety |
| P3-5: DB Optimization | postgres-patterns | 3h | 🟡 Query speed |
| P3-6: E2E Tests | e2e-testing | 6h | 🟢 Reliability |
| P3-7: Code Quality | refactor-cleaner | 2h | 🟢 Maintainability |
| P3-8: Monitoring | dashboard-builder | 4h | 🔴 Observability |
| P3-9: Flutter Perf | dart-flutter-patterns | 3h | 🟡 App speed |
| P3-10: WA Fallback | error-handling | 5h | 🟡 Reliability |
