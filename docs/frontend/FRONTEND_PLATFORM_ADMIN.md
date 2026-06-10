# Frontend - Platform Admin Feature

> Dokumentasi lengkap fitur Platform Admin di aplikasi ServisGadget Flutter.

---

## Table of Contents

1. [Data Models](#1-data-models)
2. [Repositories](#2-repositories)
3. [Providers](#3-providers)
4. [Screens](#4-screens)
5. [Router](#5-router)

---

## 1. Data Models

> File: `lib/features/platform_admin/domain/platform_admin_models.dart` (70 baris)

### Core Models

```dart
class AdminSession {
  final String id;
  final String username;
  final String fullName;
}

class AdminLoginResult {
  final String accessToken;
  final AdminSession admin;
}

class StoreListItem {
  final String id;
  final String storeName;
  final String address;
  final String phoneNumber;
  final double ratingAvg;
  final int totalCompleted;
  final String createdAt;       // String, bukan DateTime
  final Map<String, dynamic>? deviceTypes;
  final List<Map<String, dynamic>> admins;
}
```

**Note:** `deviceTypes` berbentuk `Map<String, dynamic>?` (bukan `List<String>`), dan `admins` berbentuk `List<Map<String, dynamic>>` (bukan `List<AdminInfo>`).

---

## 2. Repositories

> File: `lib/features/platform_admin/data/platform_admin_repositories.dart` (90 baris)

### Session Storage

```dart
class AdminSessionStorage {
  // Keys:
  // - 'admin_access_token'

  Future<void> saveToken(String token);
  Future<String?> readToken();
  Future<void> clear();
}
```

**Note:** Hanya menyimpan token, tidak menyimpan data admin di storage. Data admin di-cache di memory saja.

### API Client

```dart
class AdminApiClient {
  // Dio with token interceptor
  // Base URL: AppConfig.apiBaseUrl
  // Auto-refresh: Tidak ada (admin hanya 1 token)
}
```

### AdminRepository

| Method | Endpoint | Description |
|--------|----------|-------------|
| `login(username, password)` | `POST /platform/login` | Login admin |
| `listStores()` | `GET /platform/stores` | Daftar semua stores |
| `createStore(storeName, address, storePhone, adminName, adminPhone, password, handlesAndroid, handlesIos)` | `POST /platform/stores` | Buat store baru + admin |
| `logout()` | - | Clear local session |

### Create Store Parameters

```dart
// Parameter individual (bukan DTO)
Future<void> createStore({
  required String storeName,
  required String address,
  required String storePhone,
  required String adminName,
  required String adminPhone,
  required String password,
  required bool handlesAndroid,
  required bool handlesIos,
});
```

**Field Notes:**
- `storePhone`: Nomor HP toko
- `adminName`: Nama lengkap admin toko
- `adminPhone`: Nomor HP admin toko
- `password`: Password admin (wajib)
- `handlesAndroid`: Toko handle perangkat Android (boolean)
- `handlesIos`: Toko handle perangkat iOS (boolean)

---

## 3. Providers

> File: `lib/features/platform_admin/application/platform_admin_providers.dart` (37 baris)

### Auth Provider

```dart
final adminAuthProvider = AsyncNotifierProvider<AdminAuthNotifier, AdminSession?>(
  AdminAuthNotifier.new,
);

class AdminAuthNotifier extends AsyncNotifier<AdminSession?> {
  // Methods:
  // - login(username, password) → AdminSession?
  // - restore() → AdminSession? (dari token storage)
  // - logout()
}
```

### Store List Provider

```dart
final storeListProvider = FutureProvider<List<StoreListItem>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.listStores();
});
```

---

## 4. Screens

> File: `lib/features/platform_admin/presentation/screens/platform_admin_screens.dart` (264 baris)

### Screen List

| Screen | Route | Fungsi |
|--------|-------|--------|
| `AdminLoginScreen` | `/admin/login` | Username + password |
| `AdminDashboardScreen` | `/admin/dashboard` | Store list + create store |

### AdminLoginScreen

Simple login form:
- Username field
- Password field
- Login button
- Error display (Indonesian messages)

### AdminDashboardScreen

**Section 1: Store List**
- Table dengan columns:
  - Nama Toko
  - Alamat
  - Rating
  - Total Completed
  - Admins

**Section 2: Create Store Form**

```
Form Fields:
1. storeName (Text) — Nama toko
2. address (Text) — Alamat lengkap
3. storePhone (Text) — Nomor HP toko
4. adminName (Text) — Nama admin toko
5. adminPhone (Text) — Nomor HP admin
6. password (Text) — Password admin (wajib)
7. handlesAndroid (Checkbox) — Handle perangkat Android
8. handlesIos (Checkbox) — Handle perangkat iOS

Submit → POST /platform/stores
```

---

## 5. Router

> File: `lib/features/platform_admin/presentation/routing/platform_admin_router.dart` (33 baris)

### Router Configuration

```dart
final adminRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/admin/login',
    redirect: (context, state) {
      final isAuth = ref.watch(adminAuthProvider).valueOrNull != null;

      if (!isAuth && state.matchedLocation != '/admin/login') return '/admin/login';
      if (isAuth && state.matchedLocation == '/admin/login') return '/admin/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/admin/login', builder: (_, __) => AdminLoginScreen()),
      GoRoute(path: '/admin/dashboard', builder: (_, __) => AdminDashboardScreen()),
    ],
  );
});
```

### Key Differences from Other Routers

- **No FirstLoginGuard** — Admin langsung bisa akses semua
- **No auto-refresh** — Simple token-based auth
- **Only 2 routes** — Minimal feature set
- **Separate router** — Tidak di-share dengan customer/store admin
