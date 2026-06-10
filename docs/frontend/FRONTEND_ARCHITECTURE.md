# Frontend Architecture

> Flutter mobile app untuk ServisGadget — 3 role apps (Customer, Store Admin, Platform Admin) dalam 1 codebase.

---

## Table of Contents

1. [Tech Stack](#1-tech-stack)
2. [Project Structure](#2-project-structure)
3. [Clean Architecture Layers](#3-clean-architecture-layers)
4. [State Management (Riverpod)](#4-state-management-riverpod)
5. [Routing (GoRouter)](#5-routing-gorouter)
6. [Network Layer](#6-network-layer)
7. [Shared Widgets](#7-shared-widgets)
8. [Entry Point & Splash Logic](#8-entry-point--splash-logic)

---

## 1. Tech Stack

| Component | Technology | Version |
|-----------|------------|---------|
| Framework | Flutter | >=3.4.0 <4.0.0 |
| State Management | flutter_riverpod | ^2.5.1 |
| Routing | go_router | ^14.2.0 |
| HTTP Client | dio | ^5.4.3+1 |
| Secure Storage | flutter_secure_storage | ^9.2.2 |
| Code Generation | freezed + json_serializable | ^2.5.2 / ^6.8.0 |
| Image Picker | image_picker | ^1.1.2 |
| Cached Images | cached_network_image | ^3.3.1 |
| Date Formatting | intl | ^0.19.0 |

---

## 2. Project Structure

```
frontend/lib/
├── main.dart                          # Entry point + role-based splash router
│
├── core/                              # Core utilities
│   ├── app_config.dart                # API base URL config (--dart-define)
│   └── api_exception.dart             # Custom ApiException class
│
├── models/                            # Shared data models
│   └── api_response.dart              # Generic ApiResponse<T> wrapper
│
├── network/                           # Network layer
│   ├── dio_client.dart                # Dio HTTP client with token interceptor
│   └── network_error_mapper.dart      # DioException → user-friendly messages
│
├── repositories/                      # Shared repositories
│   └── base_repository.dart           # Abstract BaseRepository with Dio
│
├── shared_widgets/                    # Reusable UI components
│   ├── app_info_card.dart
│   ├── empty_state.dart
│   ├── error_state.dart
│   ├── key_value_row.dart
│   ├── loading_state.dart
│   ├── search_filter_bar.dart
│   ├── section_header.dart
│   ├── sla_countdown_badge.dart
│   └── status_badge.dart
│
├── storage/                           # Token/credential storage
│   └── token_storage.dart             # Flutter Secure Storage wrapper
│
└── features/                          # Feature modules (Clean Architecture)
    ├── customer/                      # Customer-facing features
    │   ├── application/
    │   │   └── customer_providers.dart
    │   ├── data/
    │   │   └── customer_repositories.dart
    │   ├── domain/
    │   │   └── customer_models.dart
    │   └── presentation/
    │       ├── routing/
    │       │   └── customer_router.dart
    │       ├── screens/
    │       │   └── customer_screens.dart
    │       └── widgets/
    │           └── customer_widgets.dart
    │
    ├── store_admin/                   # Store admin features
    │   ├── application/
    │   │   └── store_admin_providers.dart
    │   ├── data/
    │   │   └── store_admin_repositories.dart
    │   ├── domain/
    │   │   └── store_admin_models.dart
    │   └── presentation/
    │       ├── routing/
    │       │   └── store_admin_router.dart
    │       ├── screens/
    │       │   └── store_admin_screens.dart
    │       └── widgets/
    │           └── store_admin_widgets.dart
    │
    └── platform_admin/                # Platform admin features
        ├── application/
        │   └── platform_admin_providers.dart
        ├── data/
        │   └── platform_admin_repositories.dart
        ├── domain/
        │   └── platform_admin_models.dart
        └── presentation/
            ├── routing/
            │   └── platform_admin_router.dart
            └── screens/
                └── platform_admin_screens.dart
```

---

## 3. Clean Architecture Layers

### Domain Layer (`domain/`)
- Dart models dengan annotations (menggunakan `@immutable` dari flutter/foundation.dart)
- Enums, data classes, factory constructors
- JSON serialization (manual)
- Contoh: `OrderStatus`, `CustomerUser`, `CustomerOrder`

### Data Layer (`data/`)
- Repositories (API calls + local storage)
- Dio client configuration
- Error mapping
- Token management
- Contoh: `CustomerAuthRepository`, `OrderRepository`

### Application Layer (`application/`)
- Riverpod providers & notifiers
- Business logic orchestration
- State management
- Contoh: `customerAuthProvider`, `customerOrdersProvider`

### Presentation Layer (`presentation/`)
- **Screens**: Full page widgets
- **Widgets**: Reusable UI components
- **Routing**: GoRouter configuration

---

## 4. State Management (Riverpod)

### Provider Types Used

```dart
// 1. Simple Provider (readonly)
final featuredStoresProvider = FutureProvider<List<ServiceStore>>((ref) async {
  final repo = ref.watch(storeDiscoveryRepositoryProvider);
  return repo.getStores();
});

// 2. StateProvider (mutable state)
final orderQueryProvider = StateProvider<OrderQuery>((ref) => OrderQuery());

// 3. AsyncNotifierProvider (complex state + methods)
final customerAuthProvider = AsyncNotifierProvider<CustomerAuthNotifier, CustomerUser?>(
  CustomerAuthNotifier.new,
);

// 4. StreamProvider (real-time updates)
final orderTrackingProvider = StreamProvider.family<CustomerOrder, String>(
  (ref, orderId) => Stream.periodic(Duration(seconds: 30))
      .asyncMap((_) => repo.getOrderProgress(orderId)),
);
```

### Provider Hierarchy

```
Repository Providers (data layer)
  ↓
Application Providers (business logic)
  ↓
Screen/Widget (presentation)
```

---

## 5. Routing (GoRouter)

### Main Router (main.dart)

```dart
GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    // 1. Check store admin auth → /dashboard
    // 2. Check customer auth → /home
    // 3. Check admin auth → /admin/dashboard
    // 4. No auth → /welcome
  },
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => SplashScreen()),
    ...customerRoutes,
    ...storeAdminRoutes,
    ...adminRoutes,
  ],
)
```

### Customer Routes

```dart
final customerRoutes = [
  GoRoute(path: '/welcome', builder: (_, __) => WelcomeScreen()),
  GoRoute(path: '/login', builder: (_, __) => LoginScreen()),
  GoRoute(path: '/change-password', builder: (_, __) => ChangePasswordScreen()),
  GoRoute(path: '/home', builder: (_, __) => HomeScreen()),
  GoRoute(path: '/stores', builder: (_, __) => StoreListScreen()),
  GoRoute(path: '/stores/:id', builder: (_, state) => StoreDetailScreen(storeId: state.pathParameters['id']!)),
  GoRoute(path: '/service', builder: (_, __) => ServiceFlowScreen()),
  GoRoute(path: '/booking/:storeId', builder: (_, state) => BookingFormScreen(storeId: state.pathParameters['storeId']!)),
  GoRoute(path: '/booking-success/:orderNumber', builder: (_, state) => BookingSuccessScreen(orderNumber: state.pathParameters['orderNumber']!)),
  GoRoute(path: '/orders', builder: (_, __) => OrderListScreen()),
  GoRoute(path: '/orders/:id', builder: (_, state) => OrderDetailScreen(orderId: state.pathParameters['id']!)),
  GoRoute(path: '/orders/:id/tracking', builder: (_, state) => TrackingScreen(orderId: state.pathParameters['id']!)),
  GoRoute(path: '/orders/:id/payment', builder: (_, state) => PaymentUploadScreen(orderId: state.pathParameters['id']!)),
  GoRoute(path: '/orders/:id/review', builder: (_, state) => ReviewFormScreen(orderId: state.pathParameters['id']!)),
  GoRoute(path: '/review-success', builder: (_, __) => ReviewSuccessScreen()),
  GoRoute(path: '/orders/:id/warranty-claim', builder: (_, state) => WarrantyClaimScreen(orderId: state.pathParameters['id']!)),
  GoRoute(path: '/coupons', builder: (_, __) => CouponsScreen()),
  GoRoute(path: '/notifications', builder: (_, __) => NotificationsScreen()),
  GoRoute(path: '/notifications/:id', builder: (_, state) => NotificationDetailScreen(id: state.pathParameters['id']!)),
  GoRoute(path: '/notification-preferences', builder: (_, __) => NotificationPreferencesScreen()),
  GoRoute(path: '/profile', builder: (_, __) => ProfileScreen()),
  GoRoute(path: '/sessions', builder: (_, __) => SessionsScreen()),
  GoRoute(path: '/security', builder: (_, __) => SecurityScreen()),
];
```

### Store Admin Routes

```dart
final storeAdminRoutes = [
  GoRoute(path: '/store-login', builder: (_, __) => StoreLoginScreen()),
  GoRoute(path: '/store/change-password', builder: (_, __) => StoreChangePasswordScreen()),
  GoRoute(path: '/dashboard', builder: (_, __) => DashboardScreen()),
  GoRoute(path: '/orders', builder: (_, __) => OrderListScreen()),
  GoRoute(path: '/orders/:id', builder: (_, state) => OrderDetailScreen(orderId: state.pathParameters['id']!)),
  GoRoute(path: '/orders/:id/diagnosis', builder: (_, state) => DiagnosisScreen(orderId: state.pathParameters['id']!)),
  GoRoute(path: '/orders/:id/tracking', builder: (_, state) => TrackingScreen(orderId: state.pathParameters['id']!)),
  GoRoute(path: '/inventory', builder: (_, __) => InventoryScreen()),
  GoRoute(path: '/inventory/new', builder: (_, __) => SparepartFormScreen()),
  GoRoute(path: '/inventory/:id', builder: (_, state) => SparepartFormScreen(sparepartId: state.pathParameters['id']!)),
  GoRoute(path: '/payments', builder: (_, __) => PaymentsScreen()),
  GoRoute(path: '/reviews', builder: (_, __) => ReviewsScreen()),
  GoRoute(path: '/disputes', builder: (_, __) => DisputesScreen()),
  GoRoute(path: '/disputes/:id', builder: (_, state) => DisputeDetailScreen(disputeId: state.pathParameters['id']!)),
  GoRoute(path: '/customers', builder: (_, __) => CustomersScreen()),
  GoRoute(path: '/notifications', builder: (_, __) => NotificationsScreen()),
  GoRoute(path: '/settings', builder: (_, __) => StoreSettingsScreen()),
  GoRoute(path: '/analytics', builder: (_, __) => AnalyticsScreen()),
];
```

### Platform Admin Routes

```dart
final adminRoutes = [
  GoRoute(path: '/admin/login', builder: (_, __) => AdminLoginScreen()),
  GoRoute(path: '/admin/dashboard', builder: (_, __) => AdminDashboardScreen()),
];
```

---

## 6. Network Layer

### Dio Client

```dart
final dioClientProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: Duration(seconds: 15),
    receiveTimeout: Duration(seconds: 15),
  ));

  // Token interceptor
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

---

## 7. Shared Widgets

> Widget reusable ada di dalam masing-masing feature module, bukan di folder `shared_widgets/` terpisah.

### Customer Widgets (`customer_widgets.dart`)

| Widget | Fungsi |
|--------|--------|
| `CustomerScaffold` | Reusable scaffold dengan AppBar |
| `AsyncPage<T>` | Handle AsyncValue loading/error/data |
| `StatusPill` | Colored badge per OrderStatus |
| `StoreCard` | Card: storeName, address, rating, verified |
| `OrderCard` | Card: orderNumber, status, device, SLA warning |
| `SectionTitle` | Title + optional action button |
| `EmptyMessage` | "Tidak ada data" |
| `OrderStatusTimeline` | Vertical timeline tracking |
| `CouponRewardBanner` | "Selamat! Kamu dapat kupon Rp 10.000" |
| `SkeletonList` | Loading placeholder cards |

### Store Admin Widgets (`store_admin_widgets.dart`)

| Widget | Fungsi |
|--------|--------|
| `StoreAdminScaffold` | Responsive layout |
| `AsyncPage<T>` | AsyncSnapshot wrapper |
| `ErrorPanel` | Error display |
| `EmptyPanel` | Empty data display |
| `MetricCard` | Dashboard metric card |
| `StatusPill` | Admin-specific status pill |
| `AdminDataTable<T>` | Generic DataTable |
| `QueryToolbar` | Search + filter chips |
| `SimpleBarChart` | Horizontal bar chart |
| `OrderActionPanel` | Action buttons |

### Shared Widgets (`shared_widgets/`)

| Widget | File | Fungsi |
|--------|------|--------|
| `StatusBadge` | `status_badge.dart` | Pill badge dengan warna |
| `SectionHeader` | `section_header.dart` | Title + subtitle |
| `SearchFilterBar` | `search_filter_bar.dart` | TextField + FilterChip |
| `LoadingState` | `loading_state.dart` | Centered spinner |
| `ErrorState` | `error_state.dart` | Error + retry |
| `EmptyState` | `empty_state.dart` | Empty data display |

---

## 8. Entry Point & Splash Logic

### main.dart Flow

```
main()
  ↓
 runApp(ProviderScope(child: ServisGadgetApp()))
  ↓
 MaterialApp.router
  ├── Router: GoRouter with redirect logic
  │     ↓
  │   Check TokenStorage:
  │     ├── Store admin token → /dashboard
  │     ├── Customer token → /home
  │     ├── Admin token → /admin/dashboard
  │     └── No token → /welcome
  │
  └── Theme: Teal Material3
```

### Welcome Screen

4 entry points:
1. **"Service Sekarang"** → Customer flow (bisa langsung tanpa login)
2. **"Masuk sebagai Pelanggan"** → Customer login
3. **"Masuk sebagai Toko"** → Store admin login
4. **"Masuk sebagai Admin"** → Platform admin login

### API Base URL Configuration

```dart
// Default: http://10.0.2.2:3000/v1 (Android emulator)
// Override via --dart-define:
flutter run --dart-define=API_BASE_URL=https://api.example.com/v1
```
