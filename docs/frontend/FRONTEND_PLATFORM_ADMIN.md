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
  final bool isActive;
  final double ratingAvg;
  final int totalCompleted;
  final List<String> deviceTypes;
  final List<AdminInfo> admins;
}

class AdminInfo {
  final String id;
  final String fullName;
  final String phoneNumber;
}
```

---

## 2. Repositories

> File: `lib/features/platform_admin/data/platform_admin_repositories.dart` (90 baris)

### Session Storage

```dart
class AdminSessionStorage {
  // Keys:
  // - 'admin_access_token'
  // - 'admin_id', 'admin_username', 'admin_full_name'

  Future<void> saveSession(String token, AdminSession admin);
  Future<String?> getAccessToken();
  Future<AdminSession?> getAdmin();
  Future<void> clearSession();
}
```

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
| `createStore(dto)` | `POST /platform/stores` | Buat store baru + admin |
| `logout()` | - | Clear local session |

### Create Store DTO

```dart
class CreateStoreDto {
  final String storeName;
  final String address;
  final String phoneNumber;
  final String adminFullName;
  final String adminPhoneNumber;
  final String? adminPassword;   // Optional, auto-generated jika null
  final List<String> deviceTypes; // ['android', 'ios']
}
```

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
  // - restore() → AdminSession? (dari cache)
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
  - Status (Active/Inactive badge)
  - Rating
  - Total Completed
  - Admins
- Search/filter functionality

**Section 2: Create Store Form**

```
Form Fields:
1. storeName (Text) — Nama toko
2. address (Text) — Alamat lengkap
3. phoneNumber (Text) — Nomor HP toko
4. adminFullName (Text) — Nama admin toko
5. adminPhoneNumber (Text) — Nomor HP admin
6. adminPassword (Text, optional) — Password (auto-generated jika kosong)
7. deviceTypes (Chip select) — ['android', 'ios']

Submit → POST /platform/stores
```

**Section 3: Response**
- Show created store info
- Show generated password (if auto-generated)
- Success/error feedback

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
