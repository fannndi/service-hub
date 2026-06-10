# Frontend - Network Layer & Providers

> Dokumentasi detail network layer, repository pattern, dan provider system di Flutter frontend.

---

## Table of Contents

1. [Network Architecture](#1-network-architecture)
2. [Dio Client](#2-dio-client)
3. [Error Handling](#3-error-handling)
4. [Token Management](#4-token-management)
5. [Repository Pattern](#5-repository-pattern)
6. [Provider System](#6-provider-system)
7. [API Response Format](#7-api-response-format)

---

## 1. Network Architecture

```
┌─────────────────────────────────────────────────┐
│                   Screens                        │
│  (Listen to providers, build UI)                 │
└─────────────┬───────────────────────────────────┘
              │ Watch/Read providers
              ▼
┌─────────────────────────────────────────────────┐
│              Providers (Riverpod)                │
│  (AsyncNotifier, FutureProvider, StateProvider)  │
└─────────────┬───────────────────────────────────┘
              │ Call repository methods
              ▼
┌─────────────────────────────────────────────────┐
│             Repositories                        │
│  (Business logic, API calls, cache)             │
└─────────────┬───────────────────────────────────┘
              │ Use Dio
              ▼
┌─────────────────────────────────────────────────┐
│              Dio Client                         │
│  (HTTP, interceptors, token injection)          │
└─────────────┬───────────────────────────────────┘
              │ HTTP requests
              ▼
┌─────────────────────────────────────────────────┐
│           Backend API (NestJS)                  │
│  http://localhost:3000/v1/*                     │
└─────────────────────────────────────────────────┘
```

---

## 2. Dio Client

> File: `lib/network/dio_client.dart` (20 baris)

### Setup

```dart
final dioClientProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      // 1. Get token from storage
      final token = await tokenStorage.getAccessToken();

      // 2. Inject Bearer token
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      handler.next(options);
    },
    onError: (error, handler) async {
      // 3. Auto-refresh on 401
      if (error.response?.statusCode == 401) {
        final refreshed = await _attemptTokenRefresh(dio, tokenStorage);
        if (refreshed) {
          // Retry original request
          final newToken = await tokenStorage.getAccessToken();
          error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final response = await dio.fetch(error.requestOptions);
          return handler.resolve(response);
        }
      }
      handler.next(error);
    },
  ));

  return dio;
});
```

### API Base URL

```dart
// Default: http://10.0.2.2:3000/v1 (Android emulator localhost)
// Override via --dart-define:
//   flutter run --dart-define=API_BASE_URL=https://api.example.com/v1

class AppConfig {
  static final String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:3000/v1');
}
```

---

## 3. Error Handling

> File: `lib/network/network_error_mapper.dart` (10 baris)

### Error Mapping

```dart
ApiException mapNetworkError(DioException e) {
  // Extract user_message from backend error response
  final data = e.response?.data;
  if (data is Map<String, dynamic> && data['error']?['user_message'] != null) {
    return ApiException(data['error']['user_message']);
  }

  // Fallback by error type
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
      return ApiException('Koneksi timeout. Periksa jaringan Anda.');
    case DioExceptionType.connectionError:
      return ApiException('Tidak ada koneksi internet.');
    case DioExceptionType.receiveTimeout:
      return ApiException('Server lambat merespon. Coba lagi.');
    case DioExceptionType.badResponse:
      return ApiException('Terjadi kesalahan server.');
    default:
      return ApiException('Terjadi kesalahan. Coba lagi nanti.');
  }
}
```

### Custom Exception

```dart
// File: lib/core/api_exception.dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
}
```

### Error Response Format (from Backend)

```json
{
  "success": false,
  "error": {
    "code": "INVALID_CREDENTIALS",
    "message": "Wrong credentials",
    "user_message": "Nomor HP atau password salah."
  }
}
```

---

## 4. Token Management

> File: `lib/storage/token_storage.dart` (26 baris)

### Interface

```dart
abstract class TokenStorage {
  Future<void> saveAccessToken(String token);
  Future<String?> getAccessToken();
  Future<void> saveRefreshToken(String token);
  Future<String?> getRefreshToken();
  Future<void> clearAll();
}
```

### Implementation

```dart
class SecureTokenStorage implements TokenStorage {
  final _storage = FlutterSecureStorage();

  @override
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: 'access_token', value: token);

  @override
  Future<String?> getAccessToken() =>
      _storage.read(key: 'access_token');

  @override
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: 'refresh_token', value: token);

  @override
  Future<String?> getRefreshToken() =>
      _storage.read(key: 'refresh_token');

  @override
  Future<void> clearAll() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return SecureTokenStorage();
});
```

### Storage Keys Summary

| Feature | Keys |
|---------|------|
| Customer | `access_token`, `refresh_token`, `cached_profile`, `notification_pref` |
| Store Admin | `store_access_token`, `store_refresh_token`, `store_admin_id`, `store_admin_name`, `store_admin_phone`, `store_id`, `store_name`, `store_is_first_login` |
| Platform Admin | `admin_access_token`, `admin_id`, `admin_username`, `admin_full_name` |

---

## 5. Repository Pattern

> File: `lib/repositories/base_repository.dart` (7 baris)

### Base Repository

```dart
abstract class BaseRepository {
  final Dio _dio;
  BaseRepository(this._dio);
}
```

### Repository Examples

```dart
// Customer Auth Repository
class CustomerAuthRepository extends BaseRepository {
  CustomerAuthRepository(Dio dio) : super(dio);

  Future<LoginResult> login(String phone, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'phoneNumber': phone,
      'password': password,
    });
    return LoginResult.fromJson(response.data['data']);
  }

  Future<CustomerUser> getMe() async {
    final response = await _dio.get('/me');
    return CustomerUser.fromJson(response.data['data']);
  }
}

// Order Repository
class OrderRepository extends BaseRepository {
  OrderRepository(Dio dio) : super(dio);

  Future<CustomerOrder> getOrderDetail(String orderId) async {
    final response = await _dio.get('/orders/$orderId');
    return CustomerOrder.fromJson(response.data['data']);
  }

  Future<List<CustomerOrder>> getMyOrders() async {
    final response = await _dio.get('/orders/me');
    return (response.data['data'] as List)
        .map((e) => CustomerOrder.fromJson(e))
        .toList();
  }
}
```

### Error Handling in Repositories

```dart
// Option 1: Let DioException propagate (handled by provider)
Future<T> safeApiCall<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (e) {
    throw mapNetworkError(e);
  }
}

// Option 2: Parse error in repository
Future<ApiResult<T>> safeApiCall<T>(Future<T> Function() call) async {
  try {
    final result = await call();
    return ApiResult.success(result);
  } on DioException catch (e) {
    return ApiResult.failure(mapNetworkError(e));
  }
}
```

---

## 6. Provider System

### Provider Types

```dart
// 1. Provider — Simple dependency injection
final dioProvider = Provider<Dio>((ref) => ...);

// 2. FutureProvider — Async data that can be cached
final storeListProvider = FutureProvider<List<Store>>((ref) async {
  return ref.read(storeRepoProvider).getStores();
});

// 3. StreamProvider — Real-time data
final orderTrackingProvider = StreamProvider.family<List<Event>, String>(
  (ref, orderId) => Stream.periodic(Duration(seconds: 30))
      .asyncMap((_) => ref.read(orderRepoProvider).getTracking(orderId)),
);

// 4. StateProvider — Mutable state
final searchQueryProvider = StateProvider<String>((ref) => '');

// 5. StateNotifierProvider — Complex mutable state
final ordersProvider = StateNotifierProvider<OrdersNotifier, AsyncValue<List<Order>>>(
  (ref) => OrdersNotifier(ref),
);

// 6. AsyncNotifierProvider — Async state with methods
final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  AuthNotifier.new,
);
```

### Provider Hierarchy

```
Infrastructure Providers (dio, storage, config)
  ↓
Repository Providers (API calls + business logic)
  ↓
Application Providers (state + methods)
  ↓
Widget/Screen (UI + user interaction)
```

### Reading Providers in Widgets

```dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for reactive updates
    final summaryAsync = ref.watch(homeSummaryProvider);

    // Read for one-time access
    final auth = ref.read(customerAuthProvider.notifier);

    return summaryAsync.when(
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
      data: (summary) => Text('Active orders: ${summary.activeOrders}'),
    );
  }
}
```

---

## 7. API Response Format

### Standard Success Response

```json
{
  "success": true,
  "data": { ... },
  "timestamp": "2026-06-10T11:00:00.000Z"
}
```

### Unwrapping in Dart

```dart
// For single object
static T unwrap<T>(dynamic data) {
  return data['data'] as T;
}

// For list
static List<T> unwrapList<T>(dynamic data, T Function(dynamic) fromJson) {
  return (data['data'] as List).map((e) => fromJson(e)).toList();
}
```

### Error Response

```json
{
  "success": false,
  "error": {
    "code": "ORDER_NOT_FOUND",
    "message": "Order not found",
    "user_message": "Pesanan tidak ditemukan."
  },
  "timestamp": "2026-06-10T11:00:00.000Z"
}
```

### Pagination Response

```json
{
  "success": true,
  "data": {
    "orders": [...],
    "total": 50,
    "page": 1,
    "limit": 20
  }
}
```
