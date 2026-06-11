# TODO — Remaining Tasks for AI Agent

> **Untuk AI Agent:** Baca file ini + dokumentasi di `docs/backend/` dan `docs/frontend/` sebelum mengerjakan.
> Setiap task sudah self-contained — cukup baca konteks di sini + file yang disebutkan.

---

## P0 — Critical (Kerjakan Dulu)

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

**Referensi:** `docs/frontend/FRONTEND_CUSTOMER.md` §4 Screens

---

### P0-2: Remove Dead Code

**Files to check:**
- `frontend/lib/network/dio_client.dart` — `dioClientProvider` tidak pernah dipakai. Setiap feature (customer, store_admin, platform_admin) buat Dio instance sendiri. **Hapus file ini** atau refactor semua feature untuk pakai shared Dio.
- `frontend/lib/repositories/base_repository.dart` — `BaseRepository` tidak pernah di-extend. **Hapus file ini.**
- `frontend/lib/models/api_response.dart` — `ApiResponse<T>` tidak pernah dipakai. **Hapus file ini.**
- `frontend/lib/features/customer/presentation/routing/customer_router.dart` — `customerRouterProvider` dan `_RouterRefresh` tidak pernah dipakai (main.dart pakai `appRouterProvider`). **Hapus** `customerRouterProvider` dan `_RouterRefresh`, keep `customerRoutes` list saja.
- `frontend/lib/features/store_admin/presentation/routing/store_admin_router.dart` — `storeAdminRouterProvider` dan `_RouterRefresh` tidak pernah dipakai. **Hapus** keduanya, keep `storeAdminRoutes` list saja.
- `frontend/lib/features/platform_admin/presentation/routing/platform_admin_router.dart` — `adminRouterProvider` dan `_AdminRefresh` tidak pernah dipakai. **Hapus** keduanya, keep `adminRoutes` list saja.

**Verifikasi:** `flutter analyze` harus pass, app harus bisa run.

---

### P0-3: Fix `ServiceFlowScreen` Performance

**File:** `frontend/lib/features/customer/presentation/screens/service_flow_screen.dart` (setelah P0-1 split)

**Masalah:** 5-step wizard (482 baris) dengan 8 `TextEditingController`, `PageController`. Setiap `setState` rebuild seluruh wizard termasuk step yang tidak aktif.

**Tugas:**
1. Pecah `_buildStep1` sampai `_buildStep5` menjadi separate `StatefulWidget` classes
2. Setiap step widget terima callback `onNext(Map<String, dynamic> data)` untuk pass data ke parent
3. Parent `ServiceFlowScreen` simpan data per-step di `Map<String, dynamic> _stepData`
4. Hanya rebuild step yang aktif (gunakan `IndexedStack` atau conditional rendering)
5. Tambahkan `const` constructors di mana memungkinkan

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
   - `status_badge.dart` — sudah ada, extend untuk support `OrderStatus` enum
   - `empty_state.dart` — sudah ada, pastikan API konsisten
   - `error_state.dart` — sudah ada, tambahkan `onRetry` callback
   - Buat `formatters.dart` baru — `rupiah(num)`, `shortDate(DateTime?)`
   - Buat `async_page.dart` baru — support `AsyncValue` (Riverpod)
2. Update `customer_widgets.dart` dan `store_admin_widgets.dart` untuk import dari `shared_widgets/`
3. Hapus duplicate definitions

---

### P1-2: Implement Sessions & Security Screens

**File:** `frontend/lib/features/customer/presentation/screens/sessions_screen.dart` (setelah P0-1 split)

**Masalah:** `SessionsScreen` dan `SecurityScreen` masih stub — hanya tampilkan teks statis.

**Tugas untuk SessionsScreen:**
1. Tambah endpoint backend: `GET /v1/me/sessions` — return list `UserSession` (id, deviceInfo, ipAddress, lastActiveAt, isActive)
2. Tambah endpoint backend: `DELETE /v1/me/sessions/:id` — revoke specific session
3. Frontend: tampilkan list session aktif, tombol "Revoke" per session, "Logout All" button
4. Repository method: `getSessions()`, `revokeSession(id)`, `logoutAll()`

**Tugas untuk SecurityScreen:**
1. Tampilkan: last password change date, active sessions count, link ke change password
2. Tambah toggle "Enable biometric login" (future feature, bisa stub dulu)

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

---

### P1-4: Replace App Icon Placeholder

**File:** `frontend/assets/images/logo.png`

**Masalah:** File saat ini hanya placeholder text, bukan gambar asli.

**Tugas:**
1. Desain app icon 1024x1024 PNG (atau minta desainer)
2. Generate semua ukuran mipmap menggunakan `flutter_launcher_icons`:
   ```yaml
   # Tambah ke pubspec.yaml dev_dependencies:
   flutter_launcher_icons: ^0.13.1

   # Tambah config:
   flutter_launcher_icons:
     android: true
     image_path: "assets/images/logo.png"
     adaptive_icon_background: "#00897B"
     adaptive_icon_foreground: "assets/images/logo_foreground.png"
   ```
3. Run `dart run flutter_launcher_icons`
4. Verifikasi icon muncul di emulator

---

### P1-5: Add Rate Limiting for POST /orders

**File:** `backend/src/modules/orders/orders.controller.ts`

**Masalah:** `POST /orders` adalah endpoint publik (tanpa auth). Bisa di-spam untuk DoS.

**Tugas:**
1. Import `@Throttle` dari `@nestjs/throttler`
2. Tambahkan decorator `@Throttle({ default: { limit: 5, ttl: 60000 } })` di method `createOrder`
3. Ini membatasi 5 request per menit per IP untuk endpoint ini
4. Test: kirim 6 request berturut-turut, pastikan request ke-6 return 429

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

### P2-2: Consolidate Dio Client Setup

**Masalah:** 3 Dio instances dibuat terpisah (customer, store_admin, platform_admin) dengan interceptor pattern yang sama.

**Tugas:**
1. Buat `frontend/lib/network/api_client.dart` — factory function yang terima `tokenStorage` dan return configured `Dio`
2. Refactor `CustomerApiClient`, `storeAdminDioProvider`, `AdminApiClient` untuk pakai factory ini
3. Hapus `dio_client.dart` yang lama (sudah dead code)

### P2-3: Add Widget Tests

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

### P2-4: Implement Branded Splash Screen

**File:** `frontend/android/app/src/main/res/drawable/launch_background.xml`

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

### P2-5: Add `GET /me/sessions` and `DELETE /me/sessions/:id` Endpoints

**File:** `backend/src/modules/users/users.controller.ts` dan `users.service.ts`

**Tugas:**
1. `GET /me/sessions` — return `UserSession[]` untuk userId, select: id, deviceInfo, ipAddress, lastActiveAt, isActive, createdAt
2. `DELETE /me/sessions/:id` — set `isActive: false` untuk session dengan matching userId
3. `DELETE /me/sessions` (logout all) — set `isActive: false` untuk semua session userId
4. Add DTO: `SessionResponseDto` (exclude tokenHash dari response)

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
  lib/network/               ← Dio client, error mapper
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
