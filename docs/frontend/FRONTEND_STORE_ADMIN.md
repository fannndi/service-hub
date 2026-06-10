# Frontend - Store Admin Feature

> Dokumentasi lengkap fitur Store Admin di aplikasi ServisGadget Flutter.

---

## Table of Contents

1. [Data Models](#1-data-models)
2. [Repositories](#2-repositories)
3. [Providers](#3-providers)
4. [Screens](#4-screens)
5. [Widgets](#5-widgets)
6. [Router](#6-router)

---

## 1. Data Models

> File: `lib/features/store_admin/domain/store_admin_models.dart` (483 baris)

### Enums

```dart
enum StoreOrderStatus {
  waitingDevice, deviceReceived, diagnosing, waitingApproval,
  waitingSparepart, repairing, qualityCheck, waitingPayment,
  completed, cancelled, disputed,
}

enum PaymentRecordStatus { pending, confirmed, failed, refunded }
enum DisputeStatus { open, storeAccepted, storeRejected, escalated, resolved, closed }
```

### Core Models

#### StoreAdminSession
```dart
class StoreAdminSession {
  final String adminId;
  final String adminName;
  final String phoneNumber;
  final String storeId;
  final String storeName;
  final bool isFirstLogin;

  Map<String, String?> toStorage();                              // Nullable values
  factory StoreAdminSession.fromStorage(Map<String, String?> map);  // Nullable values
}
```

**Note:** Parameter `Map<String, String?>` (nullable values, bukan `Map<String, String>`).

#### DashboardSummary
```dart
class DashboardSummary {
  final int todayOrders;
  final int activeOrders;
  final int pendingPayments;
  final int pendingOrders;
  final int waitingApproval;
  final int openDisputes;
  final num revenueToday;
  final num revenueMonth;
  final double ratingAvg;
  final double completionRate;
  final String adminName;
  final String storeName;
  final Map<String, int> statusBreakdown;
  final List<StoreOrder> recentOrders;
  final List<MetricPoint> revenueTrend;
  final List<CategoryMetric> serviceCategories;
  final List<CustomerProfile> customers;
}
```

**Note:** Model ini memiliki banyak field. `statusBreakdown` (bukan `byStatus`). Response dari backend termasuk field `todayOrders`, `revenueMonth`, `completionRate`.

#### StoreOrder
```dart
class StoreOrder {
  final String id;
  final String orderNumber;
  final String deviceName;      // Gabungan brand + model
  final String status;
  final String paymentStatus;
  final num estimatedTotal;     // num, bukan double
  final num finalPrice;         // non-nullable
  final DateTime createdAt;
  final DateTime? slaDeadline;
  final List<String> allowedActions;
  final CredentialPanel? credentialPanel;
  final String customerName;
  final String customerPhone;
  final List<OrderItem>? items;
  final List<PaymentRecord>? payments;
  final List<TrackingEvent>? trackingEvents;
  final String? deliveryAddress;
}
```

**Notes:**
- `finalPrice` non-nullable (bukan `num?`)
- `estimatedTotal` bertipe `num` (bukan `double`)

#### OrderItem
```dart
class OrderItem {
  final String id;
  final String serviceType;
  final String complaint;
  final num price;              // num, bukan double; field name 'price' bukan 'itemPrice'
  final String status;
}
```

**Note:** Hanya 5 fields (bukan 8). Tidak ada `itemPrice`, `finalItemPrice`, `technicianNote`.

#### Sparepart
```dart
class Sparepart {
  final String id;
  final String name;
  final String description;
  final num price;              // num, bukan double
  final int qty;
  final int qtyReserved;
  final String? imageUrl;       // Ada field imageUrl
  final String status;

  int get availableStock => qty - qtyReserved;
  bool get isLowStock => availableStock <= 2;
}
```

**Note:** `price` bertipe `num` (bukan `double`). Ada field `imageUrl`.

#### PaymentRecord
```dart
class PaymentRecord {
  final String id;
  final num amount;             // num, bukan double
  final String method;          // 'method', bukan 'paymentMethod'
  final String status;
  final String? proofUrl;
  final DateTime createdAt;
}
```

**Note:** Field name adalah `method` (bukan `paymentMethod`). Tidak ada field `paymentType`.

#### DisputeCase
```dart
class DisputeCase {
  final String id;
  final String orderId;
  final String customerName;
  final String type;            // DisputeType enum value as String
  final String description;
  final List<String> evidenceUrls;
  final DisputeStatus status;   // Enum, bukan String
  final String? storeResponse;
  final DateTime createdAt;
}
```

**Note:** Model ini完全 berbeda dari yang sebelumnya didokumentasikan. Ada field `orderId`, `customerName`, `type` (bukan `disputeType`). `status` bertipe `DisputeStatus` enum.

#### ReviewItem
```dart
class ReviewItem {
  final String id;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String customerName;
}
```

#### NotificationItem
```dart
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
}
```

#### CustomerProfile
```dart
class CustomerProfile {
  final String id;
  final String name;           // 'name', bukan 'fullName'
  final String phone;           // 'phone', bukan 'phoneNumber'
  final int totalOrders;
  final num totalSpent;         // Ada field totalSpent
}
```

**Note:** Field `name` (bukan `fullName`), `phone` (bukan `phoneNumber`). Ada field `totalSpent`.

### Helper Models

| Model | Fungsi |
|-------|--------|
| `PageResult<T>` | Pagination wrapper (data, total, page, limit) |
| `MetricPoint` | Data point untuk charts (label, value) |
| `CategoryMetric` | Service category metrics |
| `CredentialPanel` | Credential info untuk customer baru |
| `TrackingEvent` | Tracking timeline event |

---

## 2. Repositories

> File: `lib/features/store_admin/data/store_admin_repositories.dart` (213 baris)

### Session Storage

```dart
class StoreAdminSessionStorage {
  Future<void> saveLogin(StoreAdminSession session);
  Future<StoreAdminSession?> restore();
  Future<void> clear();
}
```

### Dio Provider

```dart
final storeAdminDioProvider = Provider<Dio>((ref) {
  // Base URL: AppConfig.apiBaseUrl
  // Token: store_access_token
});
```

### Repositories

| Repository | Methods |
|------------|---------|
| `StoreAuthRepository` | `restoreSession()`, `login(phone, password)`, `changePassword(old, new)`, `logout()` |
| `StoreOperationsRepository` | See table below |

#### StoreOperationsRepository Methods

| Method | Endpoint | Description |
|--------|----------|-------------|
| `dashboard(storeId)` | `GET /store/dashboard/summary` | Dashboard metrics |
| `orders(storeId, query)` | `GET /store/orders` | Paginated orders |
| `orderDetail(storeId, orderId)` | `GET /store/orders/:id` | Order detail + allowedActions |
| `updateOrderStatus(storeId, orderId, action)` | `POST /store/orders/:id/actions/:action` | Execute action |
| `submitDiagnosis(storeId, orderId, dto)` | `POST /store/orders/:id/diagnosis` | Submit diagnosis |
| `tracking(storeId, orderId)` | `GET /store/orders/:id/tracking` | Tracking timeline |
| `addTracking(storeId, orderId, dto)` | `POST /store/orders/:id/tracking` | Add tracking event |
| `spareparts(storeId, query)` | `GET /store/spareparts` | Paginated spareparts |
| `saveSparepart(storeId, dto)` | `POST/PATCH /store/spareparts` | Create/update sparepart |
| `customers(storeId)` | `GET /store/customers` | Customer list |
| `payments(storeId)` | `GET /store/payments` | Payment records |
| `confirmPayment(storeId, orderId, paymentId)` | `POST /store/orders/:orderId/payments/:paymentId/confirm` | Confirm payment |
| `reviews(storeId)` | `GET /store/reviews` | Reviews list |
| `respondReview(storeId, reviewId, response)` | `POST /store/reviews/:reviewId/response` | Respond to review |
| `disputes(storeId)` | `GET /store/disputes` | Disputes list |
| `resolveDispute(storeId, disputeId, dto)` | `POST /store/disputes/:id/respond` | Accept/reject dispute |
| `notifications(storeId)` | `GET /store/notifications` | Notifications |
| `storeProfile(storeId)` | `GET /store/profile` | Store profile |
| `updateStoreProfile(storeId, dto)` | `PATCH /store/profile` | Update profile |
| `analytics(storeId)` | `GET /store/analytics` | Analytics data |
| `presignUpload(storeId, filename, contentType)` | `POST /uploads/presign` | Upload file |

---

## 3. Providers

> File: `lib/features/store_admin/application/store_admin_providers.dart` (121 baris)

### Auth Provider

```dart
final storeAuthControllerProvider = AsyncNotifierProvider<StoreAuthController, StoreAdminSession?>(
  StoreAuthController.new,
);
```

### Data Providers

```dart
final orderQueryProvider = StateProvider<OrderQuery>((ref) => OrderQuery());
final inventoryQueryProvider = StateProvider<InventoryQuery>((ref) => InventoryQuery());

final dashboardSummaryProvider = StreamProvider.autoDispose<DashboardSummary>((ref) {
  final storeId = ref.watch(storeAuthControllerProvider).valueOrNull?.storeId;
  if (storeId == null) return Stream.empty();
  return Stream.periodic(Duration(seconds: 60))
      .asyncMap((_) => ref.read(storeOperationsRepositoryProvider).dashboard(storeId));
});

final storeOrdersProvider = AsyncNotifierProvider<StoreOrdersController, PageResult<StoreOrder>>(
  StoreOrdersController.new,
);

final inventoryProvider = AsyncNotifierProvider<InventoryController, PageResult<Sparepart>>(
  InventoryController.new,
);

final paymentsProvider = AsyncNotifierProvider<PaymentsController, PageResult<PaymentRecord>>(
  PaymentsController.new,
);

final disputesProvider = AsyncNotifierProvider<DisputesController, PageResult<DisputeCase>>(
  DisputesController.new,
);
```

**Notes:**
- `paymentsProvider` dan `disputesProvider` adalah `AsyncNotifierProvider` (bukan `FutureProvider`)
- `dashboardSummaryProvider` menggunakan `StreamProvider.autoDispose` dengan session param

### Other Providers

```dart
final reviewsProvider = FutureProvider<List<ReviewItem>>((ref) async { ... });
final notificationsProvider = FutureProvider<List<NotificationItem>>((ref) async { ... });
final customersProvider = FutureProvider.autoDispose<List<CustomerProfile>>((ref) async { ... });
final analyticsProvider = FutureProvider.autoDispose<DashboardSummary>((ref) async { ... });
final storeProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async { ... });
```

---

## 4. Screens

> File: `lib/features/store_admin/presentation/screens/store_admin_screens.dart` (460 baris)

### Screen List

| Screen | Route | Fungsi |
|--------|-------|--------|
| `StoreLoginScreen` | `/store-login` | Phone + password |
| `StoreChangePasswordScreen` | `/change-password` | Old + new password |
| `DashboardScreen` | `/dashboard` | Metrics, charts, recent orders |
| `OrderListScreen` | `/orders` | Searchable/filterable order table |
| `OrderDetailScreen` | `/orders/:id` | Full order + credential panel + actions |
| `DiagnosisScreen` | `/orders/:id/diagnosis` | 6-field diagnosis form |
| `TrackingScreen` | `/orders/:id/tracking` | Timeline + add event |
| `InventoryScreen` | `/inventory` | Sparepart table + low stock alerts |
| `SparepartFormScreen` | `/inventory/new` atau `/inventory/:id` | Create/edit sparepart |
| `PaymentsScreen` | `/payments` | Payment records table |
| `ReviewsScreen` | `/reviews` | Review list + respond |
| `DisputesScreen` | `/disputes` | Dispute queue |
| `DisputeDetailScreen` | `/disputes/:id` | Accept/reject dispute |
| `CustomersScreen` | `/customers` | Customer table |
| `NotificationsScreen` | `/notifications` | Notification list |
| `StoreSettingsScreen` | `/settings` | Store profile key-value |
| `AnalyticsScreen` | `/analytics` | Charts and metrics |

### OrderDetailScreen Sections

1. **Order Info Card** — orderNumber, deviceName, dates
2. **Credential Panel** — Tampil jika customer baru
3. **Items Table** — serviceType, complaint, price, status
4. **Action Panel** — Buttons berdasarkan `allowedActions`

---

## 5. Widgets

> File: `lib/features/store_admin/presentation/widgets/store_admin_widgets.dart` (237 baris)

| Widget | Fungsi |
|--------|--------|
| `StoreAdminScaffold` | Responsive layout |
| `AsyncPage<T>` | AsyncSnapshot wrapper |
| `ErrorPanel` | Error display |
| `EmptyPanel` | Empty data display |
| `MetricCard` | Dashboard metric card with icon |
| `StatusPill` | Admin-specific status pill |
| `AdminDataTable<T>` | Generic DataTable with row selection |
| `QueryToolbar` | Search + filter chips + export button |
| `SimpleBarChart` | Horizontal bar chart |
| `OrderActionPanel` | Renders `allowedActions` as buttons |

### Responsive Layout

```dart
StoreAdminScaffold(
  // >=1200: NavigationRail (extended)
  // >=900: NavigationRail
  // <900: NavigationBar
  destinations: [
    NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
    NavigationDestination(icon: Icon(Icons.receipt), label: 'Pesanan'),
    NavigationDestination(icon: Icon(Icons.inventory), label: 'Inventory'),
    NavigationDestination(icon: Icon(Icons.payment), label: 'Pembayaran'),
    NavigationDestination(icon: Icon(Icons.analytics), label: 'Analitik'),  // Bukan 'Lainnya'
  ],
)
```

---

## 6. Router

> File: `lib/features/store_admin/presentation/routing/store_admin_router.dart` (51 baris)

### Router Configuration

```dart
final storeAdminRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      final isAuth = ref.watch(storeAuthControllerProvider).valueOrNull != null;
      final isFirstLogin = ref.watch(storeAuthControllerProvider).valueOrNull?.isFirstLogin == true;

      if (!isAuth && state.matchedLocation != '/store-login') return '/store-login';
      if (isAuth && isFirstLogin && state.matchedLocation != '/change-password') {
        return '/change-password';
      }
      if (isAuth && !isFirstLogin && state.matchedLocation == '/store-login') return '/dashboard';
      return null;
    },
    routes: [ ... ], // 17 routes
  );
});
```

**Notes:**
- Ada `refreshListenable: _RouterRefresh(ref)` (bukan tanpa refresh)
- Route `/change-password` (bukan `/store/change-password`)
