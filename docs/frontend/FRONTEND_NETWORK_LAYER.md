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
    connectTimeout: Duration(seconds: 15),
    receiveTimeout: Duration(seconds: 15),
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await tokenStorage.readAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      handler.reject(mapNetworkError(error));
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
  final String apiBaseUrl;

  AppConfig({this.apiBaseUrl = 'http://10.0.2.2:3000/v1'});
}

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig());
```

---

## 3. Error Handling

> File: `lib/network/network_error_mapper.dart` (10 baris)

### Error Mapping

```dart
ApiException mapNetworkError(DioException e) {
  // Extract error message from response
  final data = e.response?.data;
  if (data is Map<String, dynamic> && data['message'] != null) {
    return ApiException(data['message']);
  }
  return ApiException('Terjadi kesalahan. Coba lagi nanti.');
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
  Future<String?> readAccessToken();
  Future<void> clear();
}
```

### Implementation

```dart
class SecureTokenStorage implements TokenStorage {
  final FlutterSecureStorage _storage;

  SecureTokenStorage(this._storage);

  @override
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: 'access_token', value: token);

  @override
  Future<String?> readAccessToken() =>
      _storage.read(key: 'access_token');

  @override
  Future<void> clear() async {
    await _storage.delete(key: 'access_token');
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return SecureTokenStorage(FlutterSecureStorage());
});
```

### Storage Keys Summary

| Feature | Keys |
|---------|------|
| Customer | `access_token`, `customer_cached_profile`, `customer_notifications_enabled` |
| Store Admin | `store_access_token`, `store_refresh_token`, `store_admin_id`, `store_admin_name`, `store_admin_phone`, `store_id`, `store_name`, `store_is_first_login` |
| Platform Admin | `admin_access_token` |

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
final orderTrackingProvider = StreamProvider.family<CustomerOrder, String>(
  (ref, orderId) => Stream.periodic(Duration(seconds: 30))
      .asyncMap((_) => ref.read(orderRepoProvider).getOrderDetail(orderId)),
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
  }
}
```
