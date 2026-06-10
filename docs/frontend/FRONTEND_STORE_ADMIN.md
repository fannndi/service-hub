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
  final String adminId;        // Bukan 'id'
  final String adminName;      // Bukan 'fullName'
  final String phoneNumber;
  final String storeId;
  final String storeName;
  final bool isFirstLogin;

  // Serializable to/from SecureStorage
  Map<String, String> toStorage();       // Bukan toStorageMap()
  factory StoreAdminSession.fromStorage(Map<String, String> map);  // Bukan fromStorageMap()
}
```

**Notes:**
- Field `adminId` (bukan `id`)
- Field `adminName` (bukan `fullName`)
- Method `toStorage()` (bukan `toStorageMap()`)
- Method `fromStorage()` (bukan `fromStorageMap()`)

#### DashboardSummary
```dart
class DashboardSummary {
  final int todayOrders;        // Bukan totalOrdersToday
  final int activeOrders;
  final int pendingOrders;
  final int pendingPayments;
  final int waitingApproval;
  final int activeDisputes;     // Bukan openDisputes
  final num revenueMonth;       // Bukan double monthlyRevenue
  final num revenueToday;
  final double ratingAvg;
  final double completionRate;
  final String adminName;
  final String storeName;
  final Map<String, int> statusBreakdown;
  final List<StoreOrder> recentOrders;
  final List<MetricPoint> ordersTrend;
  final List<CategoryMetric> sparepartConsumption;
  final List<CustomerProfile> customers;
}
```

**Notes:**
- `todayOrders` (bukan `totalOrdersToday`)
- `revenueMonth` bertipe `num` (bukan `double`)
- `activeDisputes` (bukan `openDisputes`)
- Ada field tambahan: `pendingOrders`, `waitingApproval`, `revenueToday`, `completionRate`, `adminName`, `storeName`, `ordersTrend`, `sparepartConsumption`, `customers`

#### StoreOrder
```dart
class StoreOrder {
  final String id;
  final String orderNumber;
  final String deviceName;      // Bukan deviceType + brand + deviceModel
  final String status;
  final String paymentStatus;
  final num estimatedTotal;     // Bukan double totalEstimasi
  final num? finalPrice;
  final DateTime createdAt;
  final DateTime? slaDeadline;
  final List<String> allowedActions;
  final CredentialPanel? credentialPanel;
  final String customerName;    // Bukan CustomerInfo object
  final String customerPhone;
  final List<OrderItem>? items;
  final List<PaymentRecord>? payments;
  final List<TrackingEvent>? trackingEvents;
  final String? deliveryAddress;
}
```

**Notes:**
- `deviceName` (bukan `deviceType`, `brand`, `deviceModel` terpisah)
- `estimatedTotal` bertipe `num` (bukan `double totalEstimasi`)
- `customerName` dan `customerPhone` sebagai String (bukan `CustomerInfo` object)
- Ada field tambahan: `items`, `payments`, `trackingEvents`, `deliveryAddress`

#### Sparepart
```dart
class Sparepart {
  final String id;
  final String name;           // Bukan partName
  final String description;
  final double price;
  final int qty;
  final int qtyReserved;
  final String status;

  int get availableStock => qty - qtyReserved;
  bool get isLowStock => availableStock <= 2;  // Bukan <= 3
}
```

**Notes:**
- Class name `Sparepart` (bukan `AdminSparepart`)
- Field `name` dan `description` (bukan `brand`, `deviceModel`, `partType`, `partName`)
- Threshold `isLowStock` adalah `<= 2` (bukan `<= 3`)

#### OrderItem
```dart
class OrderItem {
  final String id;
  final String serviceType;
  final String complaint;
  final double itemPrice;
  final double? finalItemPrice;
  final String status;
  final String? technicianNote;
  final String? sparepartName;
}
```

#### PaymentRecord
```dart
class PaymentRecord {
  final String id;
  final double amount;
  final String paymentMethod;
  final String paymentType;
  final String status;
  final String? proofUrl;
  final DateTime createdAt;
}
```

#### DisputeCase
```dart
class DisputeCase {
  final String id;
  final String orderNumber;
  final String disputeType;
  final String description;
  final List<String> evidenceUrls;
  final String status;
  final String? storeResponse;
  final DateTime createdAt;
}
```

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
  final String status;
  final String? note;
  final DateTime createdAt;
  final String orderNumber;
}
```

#### CustomerProfile
```dart
class CustomerProfile {
  final String id;
  final String fullName;
  final String phoneNumber;
  final int totalOrders;
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

  Future<void> saveLogin(StoreAdminSession session);  // Bukan saveSession()
  Future<StoreAdminSession?> restore();               // Bukan getSession()
  Future<void> clear();                               // Bukan clearSession()
}
```

**Notes:**
- Method `saveLogin()` (bukan `saveSession()`)
- Method `restore()` (bukan `getSession()`)
- Method `clear()` (bukan `clearSession()`)

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

**Notes:**
- `dashboard()` → endpoint `/store/dashboard/summary` (bukan `/store/dashboard`)
- `updateOrderStatus()` → `POST /store/orders/:id/actions/:action` (bukan `PATCH /store/orders/:id/status`)
- `confirmPayment()` → endpoint `/store/orders/:orderId/payments/:paymentId/confirm` (bukan `/store/payments/:orderId/:paymentId/confirm`)
- `respondReview()` → endpoint `/store/reviews/:reviewId/response` (bukan `/store/reviews/:reviewId/respond`)

---

## 3. Providers

> File: `lib/features/store_admin/application/store_admin_providers.dart` (121 baris)

### Auth Provider

```dart
final storeAuthControllerProvider = AsyncNotifierProvider<StoreAuthController, StoreAdminSession?>(
  StoreAuthController.new,
);
```

**Note:** Provider name adalah `storeAuthControllerProvider` (bukan `storeAuthProvider`).

### Data Providers

```dart
final orderQueryProvider = StateProvider<OrderQuery>((ref) => OrderQuery());
final inventoryQueryProvider = StateProvider<InventoryQuery>((ref) => InventoryQuery());

final dashboardSummaryProvider = StreamProvider<DashboardSummary>((ref) {
  return Stream.periodic(Duration(seconds: 60))
      .asyncMap((_) => ref.read(storeOperationsRepositoryProvider).dashboard(storeId));
});

final storeOrdersProvider = AsyncNotifierProvider<StoreOrdersController, PageResult<StoreOrder>>(
  StoreOrdersController.new,
);
```

**Note:** `storeOrdersProvider` adalah `AsyncNotifierProvider` (bukan `FutureProvider`).

### Controller Providers

```dart
final storeOrdersProvider = AsyncNotifierProvider<StoreOrdersController, PageResult<StoreOrder>>(
  StoreOrdersController.new,
);

class StoreOrdersController extends AsyncNotifier<PageResult<StoreOrder>> {
  // Methods:
  // - refresh()
  // - loadMore()
  // - updateStatus(orderId, action)
  // - submitDiagnosis(orderId, dto)
}
```

### Other Providers

```dart
final inventoryProvider = AsyncNotifierProvider<InventoryController, PageResult<Sparepart>>(
  InventoryController.new,
);

final paymentsProvider = FutureProvider<List<PaymentRecord>>((ref) async { ... });
final disputesProvider = FutureProvider<List<DisputeCase>>((ref) async { ... });
final reviewsProvider = FutureProvider<List<ReviewItem>>((ref) async { ... });
final notificationsProvider = FutureProvider<List<NotificationItem>>((ref) async { ... });
final customersProvider = FutureProvider<List<CustomerProfile>>((ref) async { ... });
final analyticsProvider = FutureProvider<AnalyticsData>((ref) async { ... });
final storeProfileProvider = FutureProvider<StoreProfile>((ref) async { ... });
```

---

## 4. Screens

> File: `lib/features/store_admin/presentation/screens/store_admin_screens.dart` (460 baris)

### Screen List

| Screen | Route | Fungsi |
|--------|-------|--------|
| `StoreLoginScreen` | `/store-login` | Phone + password |
| `StoreChangePasswordScreen` | `/store/change-password` | Old + new password |
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

**Notes:**
- Route `/` → `/store-login` (bukan `/`)
- Route `/inventory/:id` untuk edit sparepart

### DashboardScreen Sections

1. **Metrics Grid** — Cards: todayOrders, activeOrders, revenueMonth, ratingAvg, pendingPayments, activeDisputes
2. **Status Breakdown Chart** — Horizontal bar chart per status
3. **Orders Trend** — Line/bar chart 7 hari terakhir
4. **Sparepart Consumption** — Chart penggunaan sparepart
5. **Recent Orders Table** — 5 order terbaru dengan quick actions

### OrderDetailScreen Sections

1. **Order Info Card** — orderNumber, deviceName, dates
2. **Credential Panel** — Tampil jika customer baru (name, phone, auto-generated password)
3. **Items Table** — serviceType, complaint, price, status
4. **Action Panel** — Buttons berdasarkan `allowedActions`
   - `receive_device` → "Terima Device"
   - `start_diagnosis` → "Mulai Diagnosis"
   - `sparepart_arrived` → "Sparepart Sampai"
   - `start_qc` → "Mulai QC"
   - `mark_complete` → "Tandai Selesai"

### DiagnosisScreen Form

```
Fields:
1. condition (Text) — Kondisi device
2. damage (Text) — Kerusakan
3. repair (Text) — Perbaikan yang dilakukan
4. technician (Text) — Nama teknisi
5. estimatedCost (Number) — Estimasi biaya
6. estimatedDuration (Text) — Estimasi durasi
```

**Note:** 6 fields (bukan 4 fields seperti yang sebelumnya didokumentasikan).

### InventoryScreen Features

- **Search** — Cari berdasarkan nama
- **Filter** — By status
- **Low Stock Alert** — Badge merah jika `availableStock <= 2`
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
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isAuth = ref.watch(storeAuthControllerProvider).valueOrNull != null;
      final isFirstLogin = ref.watch(storeAuthControllerProvider).valueOrNull?.isFirstLogin == true;

      if (!isAuth && state.matchedLocation != '/store-login') return '/store-login';
      if (isAuth && isFirstLogin && state.matchedLocation != '/store/change-password') {
        return '/store/change-password';
      }
      if (isAuth && !isFirstLogin && state.matchedLocation == '/store-login') return '/dashboard';
      return null;
    },
    routes: [ ... ], // 17 routes
  );
});
```

**Notes:**
- `initialLocation` adalah `'/dashboard'` (bukan `'/'`)
- Auth check menggunakan `storeAuthControllerProvider` (bukan `storeAuthProvider`)
- Login route adalah `'/store-login'` (bukan `'/'`)
