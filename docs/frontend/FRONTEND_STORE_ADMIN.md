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
  final String id;
  final String fullName;
  final String phoneNumber;
  final String storeId;
  final String storeName;
  final bool isFirstLogin;

  // Serializable to/from SecureStorage
  Map<String, String> toStorageMap();
  factory StoreAdminSession.fromStorageMap(Map<String, String> map);
}
```

#### DashboardSummary
```dart
class DashboardSummary {
  final int totalOrdersToday;
  final int activeOrders;
  final int pendingPayments;
  final int openDisputes;
  final double monthlyRevenue;
  final double ratingAvg;
  final Map<String, int> statusBreakdown;
  final List<StoreOrder> recentOrders;
  final List<MetricPoint> revenueTrend;
  final List<CategoryMetric> serviceCategories;
}
```

#### StoreOrder
```dart
class StoreOrder {
  final String id;
  final String orderNumber;
  final DeviceType deviceType;
  final String brand;
  final String deviceModel;
  final StoreOrderStatus status;
  final PaymentStatus paymentStatus;
  final double totalEstimasi;
  final double? finalPrice;
  final DateTime createdAt;
  final DateTime? slaDeadline;
  final List<String> allowedActions;
  final CredentialPanel? credentialPanel;
  final CustomerInfo customer;
}
```

#### Sparepart (Admin)
```dart
class AdminSparepart {
  final String id;
  final String brand;
  final String deviceModel;
  final String partType;
  final String partName;
  final double price;
  final int qty;
  final int qtyReserved;
  final SparePartStatus status;

  int get availableStock => qty - qtyReserved;
  bool get isLowStock => availableStock <= 3;
}
```

### Helper Models

| Model | Fungsi |
|-------|--------|
| `PageResult<T>` | Pagination wrapper (data, total, page, limit) |
| `MetricPoint` | Data point untuk charts (label, value) |
| `CategoryMetric` | Service category metrics |
| `CredentialPanel` | Credential info untuk customer baru |
| `TrackingEvent` | Tracking timeline event |
| `CustomerInfo` | Customer info ringkas |

---

## 2. Repositories

> File: `lib/features/store_admin/data/store_admin_repositories.dart` (213 baris)

### Session Storage

```dart
class StoreAdminSessionStorage {
  // 8 keys in SecureStorage:
  // - 'store_access_token', 'store_refresh_token'
  // - 'store_admin_id', 'store_admin_name', 'store_admin_phone'
  // - 'store_id', 'store_name', 'store_is_first_login'

  Future<void> saveSession(StoreAdminSession session);
  Future<StoreAdminSession?> getSession();
  Future<void> clearSession();
}
```

### Dio Provider

```dart
final storeAdminDioProvider = Provider<Dio>((ref) {
  // Similar to customer but uses store JWT
  // Base URL: AppConfig.apiBaseUrl
  // Token: store_access_token
  // Auto-refresh on 401
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
| `dashboard(storeId)` | `GET /store/dashboard` | Dashboard metrics |
| `orders(storeId, query)` | `GET /store/orders` | Paginated orders |
| `orderDetail(storeId, orderId)` | `GET /store/orders/:id` | Order detail + allowedActions |
| `updateOrderStatus(storeId, orderId, status)` | `PATCH /store/orders/:id/status` | Status update |
| `submitDiagnosis(storeId, orderId, dto)` | `POST /store/orders/:id/diagnosis` | Submit diagnosis |
| `tracking(storeId, orderId)` | `GET /store/orders/:id/tracking` | Tracking timeline |
| `addTracking(storeId, orderId, dto)` | `POST /store/orders/:id/tracking` | Add tracking event |
| `spareparts(storeId, query)` | `GET /store/spareparts` | Paginated spareparts |
| `saveSparepart(storeId, dto)` | `POST/PATCH /store/spareparts` | Create/update sparepart |
| `customers(storeId)` | `GET /store/customers` | Customer list |
| `payments(storeId)` | `GET /store/payments` | Payment records |
| `confirmPayment(storeId, orderId, paymentId)` | `POST /store/payments/:orderId/:paymentId/confirm` | Confirm payment |
| `reviews(storeId)` | `GET /store/reviews` | Reviews list |
| `respondReview(storeId, reviewId, response)` | `POST /store/reviews/:reviewId/respond` | Respond to review |
| `disputes(storeId)` | `GET /store/disputes` | Disputes list |
| `resolveDispute(storeId, disputeId, dto)` | `POST /store/disputes/:id/respond` | Accept/reject dispute |
| `notifications(storeId)` | `GET /store/notifications` | Notifications |
| `storeProfile(storeId)` | `GET /store/profile` | Store profile |
| `updateStoreProfile(storeId, dto)` | `PATCH /store/profile` | Update profile |
| `analytics(storeId)` | `GET /store/analytics` | Analytics data |

---

## 3. Providers

> File: `lib/features/store_admin/application/store_admin_providers.dart` (121 baris)

### Auth Provider

```dart
final storeAuthProvider = AsyncNotifierProvider<StoreAuthController, StoreAdminSession?>(
  StoreAuthController.new,
);

class StoreAuthController extends AsyncNotifier<StoreAdminSession?> {
  // Methods:
  // - login(phone, password) → StoreAdminSession?
  // - restore() → StoreAdminSession? (dari cache)
  // - changePassword(old, new)
  // - logout()
}
```

### Data Providers

```dart
final orderQueryProvider = StateProvider<OrderQuery>((ref) => OrderQuery());
final inventoryQueryProvider = StateProvider<InventoryQuery>((ref) => InventoryQuery());

final dashboardSummaryProvider = StreamProvider<DashboardSummary>((ref) {
  return Stream.periodic(Duration(seconds: 60))
      .asyncMap((_) => ref.read(storeOperationsRepositoryProvider).dashboard(storeId));
});

final storeOrdersProvider = FutureProvider<PageResult<StoreOrder>>((ref) async {
  final query = ref.watch(orderQueryProvider);
  return ref.read(storeOperationsRepositoryProvider).orders(storeId, query);
});

final reviewsProvider = FutureProvider<List<ReviewItem>>((ref) async { ... });
final notificationsProvider = FutureProvider<List<NotificationItem>>((ref) async { ... });
final customersProvider = FutureProvider<List<CustomerProfile>>((ref) async { ... });
final analyticsProvider = FutureProvider<AnalyticsData>((ref) async { ... });
final storeProfileProvider = FutureProvider<StoreProfile>((ref) async { ... });
```

### Controller Providers

```dart
final storeOrdersController = StateNotifierProvider<StoreOrdersController, AsyncValue<PageResult<StoreOrder>>>(
  (ref) => StoreOrdersController(ref),
);

class StoreOrdersController extends StateNotifier<AsyncValue<PageResult<StoreOrder>>> {
  // Methods:
  // - refresh()
  // - loadMore()
  // - updateStatus(orderId, status)
  // - submitDiagnosis(orderId, dto)
}
```

---

## 4. Screens

> File: `lib/features/store_admin/presentation/screens/store_admin_screens.dart` (460 baris)

### Screen List

| Screen | Route | Fungsi |
|--------|-------|--------|
| `StoreLoginScreen` | `/` | Phone + password login |
| `StoreChangePasswordScreen` | `/change-password` | Old + new password |
| `DashboardScreen` | `/dashboard` | Metrics, charts, recent orders |
| `OrderListScreen` | `/orders` | Searchable/filterable order table |
| `OrderDetailScreen` | `/orders/:id` | Full order + credential panel + actions |
| `DiagnosisScreen` | `/orders/:id/diagnosis` | 6-field diagnosis form |
| `TrackingScreen` | `/orders/:id/tracking` | Timeline + add event |
| `InventoryScreen` | `/inventory` | Sparepart table + low stock alerts |
| `SparepartFormScreen` | `/inventory/new` | Create/edit sparepart |
| `PaymentsScreen` | `/payments` | Payment records table |
| `ReviewsScreen` | `/reviews` | Review list + respond |
| `DisputesScreen` | `/disputes` | Dispute queue |
| `DisputeDetailScreen` | `/disputes/:id` | Accept/reject dispute |
| `CustomersScreen` | `/customers` | Customer table |
| `NotificationsScreen` | `/notifications` | Notification list |
| `StoreSettingsScreen` | `/settings` | Store profile key-value |
| `AnalyticsScreen` | `/analytics` | Charts and metrics |

### DashboardScreen Sections

1. **Metrics Grid** — 6 cards: totalOrders, activeOrders, revenue, rating, pendingPayments, disputes
2. **Status Breakdown Chart** — Horizontal bar chart per status
3. **Revenue Trend** — Line/bar chart 7 hari terakhir
4. **Service Categories** — Pie chart service types
5. **Recent Orders Table** — 5 order terbaru dengan quick actions

### OrderDetailScreen Sections

1. **Order Info Card** — orderNumber, device, dates
2. **Credential Panel** — Tampil jika customer baru (name, phone, auto-generated password)
3. **Items Table** — serviceType, complaint, price, status
4. **Action Panel** — Buttons berdasarkan `allowedActions`
   - `receive_device` → "Terima Device"
   - `start_diagnosis` → "Mulai Diagnosis"
   - `start_repair` → "Mulai Perbaikan"
   - `mark_complete` → "Tandai Selesai"

### DiagnosisScreen Form

```
Fields:
1. diagnosisNote (Text) — Catatan teknisi
2. estimatedDays (Number) — Estimasi hari perbaikan
3. items[] — List item dengan:
   - serviceType (Text)
   - itemPrice (Number) — Harga estimasi
   - status (Dropdown) — confirmed/replaced/cancelled
   - technicianNote (Text) — Catatan per item
```

### InventoryScreen Features

- **Search** — Cari berdasarkan nama, brand, model
- **Filter** — By brand, status
- **Low Stock Alert** — Badge merah jika `availableStock <= 3`
- **Quick Edit** — Tap untuk edit harga/stok

---

## 5. Widgets

> File: `lib/features/store_admin/presentation/widgets/store_admin_widgets.dart` (237 baris)

| Widget | Fungsi |
|--------|--------|
| `StoreAdminScaffold` | Responsive layout (NavigationRail/Drawer/NavigationBar) |
| `AsyncPage<T>` | AsyncSnapshot wrapper |
| `ErrorPanel` | Error display |
| `EmptyPanel` | Empty data display |
| `MetricCard` | Dashboard metric card with icon |
| `StatusPill` | Admin-specific status pill |
| `AdminDataTable<T>` | Generic DataTable with row selection |
| `QueryToolbar` | Search + filter chips + export button |
| `SimpleBarChart` | Horizontal bar chart using LinearProgressIndicator |
| `OrderActionPanel` | Renders `allowedActions` as Indonesian buttons |

### Responsive Layout

```dart
StoreAdminScaffold(
  // Wide screen (>1200px): NavigationRail on left
  // Medium screen (600-1200px): Drawer
  // Narrow screen (<600px): Bottom NavigationBar
  destinations: [
    NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
    NavigationDestination(icon: Icon(Icons.receipt), label: 'Pesanan'),
    NavigationDestination(icon: Icon(Icons.inventory), label: 'Inventory'),
    NavigationDestination(icon: Icon(Icons.payment), label: 'Pembayaran'),
    NavigationDestination(icon: Icon(Icons.more), label: 'Lainnya'),
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
    initialLocation: '/',
    redirect: (context, state) {
      final isAuth = ref.watch(storeAuthProvider).valueOrNull != null;
      final isFirstLogin = ref.watch(storeAuthProvider).valueOrNull?.isFirstLogin == true;

      if (!isAuth && state.matchedLocation != '/') return '/';
      if (isAuth && isFirstLogin && state.matchedLocation != '/change-password') {
        return '/change-password';
      }
      if (isAuth && !isFirstLogin && state.matchedLocation == '/') return '/dashboard';
      return null;
    },
    routes: [ ... ], // 18 routes
  );
});
```
