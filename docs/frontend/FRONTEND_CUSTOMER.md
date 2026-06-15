# Frontend - Customer Feature

> Dokumentasi lengkap fitur Customer di aplikasi ServisGadget Flutter.

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

> File: `lib/features/customer/domain/customer_models.dart` (524 baris)

### Enums

```dart
enum OrderStatus {
  waitingDevice,      // Menunggu device
  deviceReceived,     // Device diterima
  diagnosing,         // Sedang diagnosis
  waitingApproval,    // Menunggu approval
  waitingSparepart,   // Menunggu sparepart
  repairing,          // Sedang repair
  qualityCheck,       // QC
  waitingPayment,     // Menunggu bayar
  completed,          // Selesai
  cancelled,          // Dibatalkan
  disputed,           // Ada klaim
}
```

### Core Models

#### CustomerUser
```dart
class CustomerUser {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? avatarUrl;
  final String? address;
  final bool isFirstLogin;
}
```

#### LoginResult
```dart
class LoginResult {
  final String accessToken;
  final String refreshToken;
  final bool isFirstLogin;
  final CustomerUser user;
}
```

#### HomeSummary
```dart
class HomeSummary {
  final int activeOrders;
  final int activeCoupons;
  final int activeWarranties;
}
```

#### ServiceStore
```dart
class ServiceStore {
  final String id;
  final String storeName;
  final String address;
  final String phoneNumber;
  final double ratingAvg;
  final int reviewCount;
  final DateTime? verifiedAt;
  final Map<String, dynamic> operationalHours;
  final List<ReviewItem> reviews;
}
```

#### SparePart
```dart
class SparePart {
  final String id;
  final String storeId;
  final String brand;
  final String deviceModel;
  final String partType;
  final String partName;
  final double price;
  final int qty;
  final int qtyReserved;

  int get availableQty => qty - qtyReserved;
}
```

**Note:** Tidak ada field `status` di model ini.

#### DeviceModelGroup
> File: `lib/features/customer/domain/device_model.dart`

```dart
class DeviceModelGroup {
  final String brand;
  final List<String> models;
}
```

**Usage:** Source of truth untuk dropdown brand dan model perangkat di Service Now Step 1 dan brand chips di Store List. Data diambil dari public endpoint `GET /stores/device-models`.

#### StoreMatchResult
```dart
class StoreMatchResult {
  final String storeId;
  final String storeName;
  final String address;
  final String phoneNumber;
  final double ratingAvg;
  final int totalCompleted;
  final List<MatchSparePart> spareparts;  // Bukan matchingParts
  final double estimatedCost;             // Bukan totalEstimate
}

class MatchSparePart {
  final String id;
  final String partName;
  final String partType;
  final double price;
  final int availableQty;  // Bukan qty
  final String status;
}
```

#### CustomerOrder
```dart
class CustomerOrder {
  final String id;
  final String orderNumber;
  final OrderStatus status;          // Enum, bukan String
  final String deviceType;
  final String brand;
  final String deviceModel;
  final String deliveryMethod;
  final String paymentStatus;
  final double totalEstimasi;
  final double discountAmount;
  final double? finalPrice;
  final double? serviceFee;
  final String? diagnosisNote;
  final DateTime? warrantyExpiredAt;
  final DateTime? slaDeadline;
  final String? couponId;
  final DateTime createdAt;
  final bool reviewed;
  // Store info sebagai separate fields:
  final String storeName;
  final String storeAddress;
  final String storePhone;
  final List<OrderItem> items;
  final List<TrackingEntry> tracking;
  final List<PaymentRecord> payments;
}
```

**Notes:**
- `status` bertipe `OrderStatus` (enum, bukan `String`)
- Store info berupa separate fields, bukan object `ServiceStore`
- Ada field `createdAt` dan `reviewed`

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

#### TrackingEntry
```dart
class TrackingEntry {
  final String id;
  final OrderStatus status;  // Enum, bukan String
  final String? note;
  final String createdByType;
  final DateTime createdAt;
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

#### CreateOrderRequest
```dart
class CreateOrderRequest {
  final String storeId;
  final String deviceType;
  final String brand;
  final String deviceModel;
  final String deliveryMethod;
  final String? deliveryAddress;
  final String fullName;           // Bukan customerName
  final String phoneNumber;
  final String? couponCode;
  final List<CreateOrderItemInput> items;
}
```

**Note:** `fullName` (bukan `customerName`) dan `phoneNumber` wajib untuk auto-create account.

#### CreateOrderItemInput
```dart
class CreateOrderItemInput {
  final String serviceType;
  final String complaint;
  final String? sparepartId;
}
```

#### CreateOrderResult
```dart
class CreateOrderResult {
  final String id;
  final String orderNumber;
  final String status;
  final double totalEstimasi;
  final bool isNewCustomer;
  final String message;
}
```

#### ReviewItem
```dart
class ReviewItem {
  final String id;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String? customerName;  // Nullable
}
```

#### CouponReward
```dart
class CouponReward {
  final String code;       // Hanya code, amount, expiredAt
  final double amount;
  final DateTime expiredAt;
}
```

**Note:** Tidak ada field `id`, `isUsed`, atau `createdAt`.

#### ReviewResult
```dart
class ReviewResult {
  final String reviewId;
  final String couponCode;
}
```

#### NotificationItem
```dart
class NotificationItem {
  final String id;
  final String title;       // Bukan status
  final String message;     // Bukan note
  final DateTime createdAt;
  final bool isRead;        // Bukan orderNumber
}
```

**Note:** Model ini完全 berbeda dari yang sebelumnya didokumentasikan.

---

## 2. Repositories

> File: `lib/features/customer/data/customer_repositories.dart` (305 baris)

### Session Storage

```dart
class CustomerSessionStorage {
  // Keys:
  // - 'access_token'
  // - 'customer_cached_profile'
  // - 'customer_notifications_enabled'

  Future<void> saveTokens(String accessToken, String refreshToken);
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> clearAll();
  Future<void> cacheProfile(CustomerUser user);
  Future<String?> readCachedProfile();  // Return String?, bukan CustomerUser?
  Future<void> saveNotificationPreference(bool enabled);
  Future<bool> readNotificationPreference();
}
```

**Note:** `readCachedProfile()` mengembalikan `String?` (raw JSON), bukan `CustomerUser?`.

### API Client

```dart
class CustomerApiClient {
  // 2 Dio instances:
  // - _publicDio: tanpa token (login, register)
  // - _authDio: dengan token

  // Auto-refresh on 401:
  // 1. Request gagal 401
  // 2. Coba refresh token
  // 3. Jika berhasil → retry request
  // 4. Jika gagal → clear session, throw error

  static T unwrap<T>(dynamic data);
  static List<T> unwrapList<T>(dynamic data, T Function(dynamic) fromJson);
}
```

### Repositories

| Repository | Methods | Endpoint |
|------------|---------|----------|
| `CustomerAuthRepository` | `login()`, `getMe()`, `getSummary()`, `changePassword()`, `updateProfile()`, `logout()` | `/auth/*`, `/me/*` |
| `StoreDiscoveryRepository` | `getStores()`, `getDeviceModels()`, `getStore()`, `getSpareparts()`, `matchStores()` | `/stores/*` |
| `OrderRepository` | `createOrder()`, `getMyOrders()`, `getOrderDetail()`, `getOrderProgress()`, `approveOrder()`, `rejectOrder()` | `/me/orders/*`, `/orders/*` |
| `PaymentRepository` | `createPayment(orderId, dto)` | `/orders/$orderId/payments` |
| `ReviewRepository` | `createReview()`, `getCoupons()` | `/reviews/*`, `/me/coupons` |
| `DisputeRepository` | `createDispute(orderId, dto)` | `/disputes/:orderId` |
| `UploadRepository` | `uploadFile(file, folder, onProgress)` | `/uploads/presign` |
| `NotificationRepository` | `getNotifications()` | `/me/notifications` |

**Note:** `OrderRepository.getMyOrders()` menggunakan endpoint `/me/orders` (bukan `/orders/me`).

---

## 3. Providers

> File: `lib/features/customer/application/customer_providers.dart` (98 baris)

### Auth Provider

```dart
final customerAuthProvider = AsyncNotifierProvider<CustomerAuthNotifier, CustomerUser?>(
  CustomerAuthNotifier.new,
);

class CustomerAuthNotifier extends AsyncNotifier<CustomerUser?> {
  // Methods:
  // - login(phone, password) → LoginResult  // Bukan User?
  // - restoreSession() → CustomerUser? (dari cache)
  // - changePassword(old, new)
  // - updateProfile({fullName, address, avatarUrl})
  // - logout()
}
```

**Note:** `login()` mengembalikan `LoginResult` (bukan `User?`).

### Data Providers

```dart
final homeSummaryProvider = FutureProvider<HomeSummary>((ref) async {
  final repo = ref.watch(customerAuthRepositoryProvider);
  return repo.getSummary();
});

final featuredStoresProvider = FutureProvider<List<ServiceStore>>((ref) async {
  final repo = ref.watch(storeDiscoveryRepositoryProvider);
  return repo.getStores();  // Tanpa limit
});

final deviceModelsProvider = FutureProvider<List<DeviceModelGroup>>((ref) async {
  final repo = ref.watch(storeDiscoveryRepositoryProvider);
  return repo.getDeviceModels(); // Public endpoint, no JWT
});

final storeListProvider = FutureProvider.family<List<ServiceStore>, ({String? brand, String? model})>(
  (ref, filter) async {
    final repo = ref.watch(storeDiscoveryRepositoryProvider);
    return repo.getStores(brand: filter.brand, model: filter.model);
  },
);

final storeDetailProvider = FutureProvider.family<ServiceStore, String>(
  (ref, storeId) async {
    final repo = ref.watch(storeDiscoveryRepositoryProvider);
    return repo.getStore(storeId);
  },
);

final sparepartsProvider = FutureProvider.family<List<SparePart>, String>(
  (ref, storeId) async {
    final repo = ref.watch(storeDiscoveryRepositoryProvider);
    return repo.getSpareparts(storeId);
  },
);
```

### Order Providers

```dart
final customerOrdersProvider = FutureProvider.family<List<CustomerOrder>, String>(
  (ref, statusFilter) async {
    final repo = ref.watch(orderRepositoryProvider);
    final orders = await repo.getMyOrders();
    if (statusFilter.isEmpty) return orders;
    return orders.where((o) => o.status.name == statusFilter).toList();
  },
);

final orderDetailProvider = FutureProvider.family<CustomerOrder, String>(
  (ref, orderId) async {
    final repo = ref.watch(orderRepositoryProvider);
    return repo.getOrderDetail(orderId);
  },
);

final orderTrackingProvider = StreamProvider.family<CustomerOrder, String>(
  (ref, orderId) async* {
    yield await ref.read(orderRepositoryProvider).getOrderDetail(orderId);
    await for (final _ in Stream.periodic(Duration(seconds: 30))) {
      yield await ref.read(orderRepositoryProvider).getOrderDetail(orderId);
    }
  },
);
```

**Note:** `orderTrackingProvider` menggunakan `async* yield` generator (bukan `Stream.periodic().asyncMap()`).

### Other Providers

```dart
final couponsProvider = FutureProvider<List<CouponReward>>((ref) async { ... });
final notificationsProvider = FutureProvider<List<NotificationItem>>((ref) async { ... });
final notificationPreferenceProvider = FutureProvider<bool>((ref) async { ... });
```

---

## 4. Screens

> File: `lib/features/customer/presentation/screens/customer_screens.dart` (2162 baris)

### Screen List

| Screen | Route | Fungsi |
|--------|-------|--------|
| `SplashScreen` | `/splash` | Token check + session restore |
| `WelcomeScreen` | `/welcome` | 4 entry points: "Service Now", "Pelanggan", "Toko", "Admin" |
| `LoginScreen` | `/login` | Phone + password |
| `ChangePasswordScreen` | `/change-password` | Old + new password |
| `HomeScreen` | `/home` | Summary, quick actions, recent orders |
| `StoreListScreen` | `/stores` | Brand filter + search + store list |
| `StoreDetailScreen` | `/stores/:id` | Store info + spareparts + reviews |
| `ServiceFlowScreen` | `/service` | 5-step booking wizard |
| `BookingFormScreen` | `/booking/:storeId` | Single-store order form |
| `BookingSuccessScreen` | `/booking-success/:orderNumber` | Success confirmation |
| `OrderListScreen` | `/orders` | 3 tabs (active/completed/cancelled) |
| `OrderDetailScreen` | `/orders/:id` | Full order view |
| `DiagnosisApprovalCard` | - | Approve/reject diagnosis |
| `TrackingScreen` | `/orders/:id/tracking` | Live tracking (30s polling) |
| `PaymentUploadScreen` | `/orders/:id/payment` | Payment + proof upload |
| `ReviewFormScreen` | `/orders/:id/review` | 5-star rating + comment |
| `ReviewSuccessScreen` | `/review-success` | Coupon reward banner |
| `WarrantyClaimScreen` | `/orders/:id/warranty-claim` | Dispute form + photo evidence |
| `ProfileScreen` | `/profile` | Edit profile + logout |
| `CouponsScreen` | `/coupons` | List kupon |
| `NotificationsScreen` | `/notifications` | List notifikasi |
| `NotificationDetailScreen` | `/notifications/:id` | Detail notifikasi (via `state.extra`) |
| `NotificationPreferencesScreen` | `/notification-preferences` | Setelan notifikasi |
| `SessionsScreen` | `/sessions` | List sesi login aktif, revoke per session, logout all (konfirmasi dialog) |
| `SecurityScreen` | `/security` | Ganti password, jumlah perangkat aktif, info nomor HP |

**Notes:**
- `NotificationDetailScreen` menerima parameter via `state.extra as NotificationItem?` (bukan path parameter)
- `ReviewSuccessScreen` menerima parameter via `state.extra as ReviewResult`
- `ServiceFlowScreen` Step 1 memakai dropdown brand dan model dari `deviceModelsProvider`, bukan hardcoded text field. User wajib memilih brand dan model; pilihan tidak di-auto-select walaupun hanya ada satu opsi.
- `StoreListScreen` brand chips memakai daftar brand dari `deviceModelsProvider` dengan tambahan chip `All`.
- `SessionsScreen` menampilkan: nama perangkat, IP, last active, status aktif. Tombol revoke per session (kecuali session saat ini). Tombol "Logout Semua" di AppBar.
- `SecurityScreen` menampilkan: jumlah perangkat aktif (link ke sessions), ganti password (link ke change-password), info bahwa nomor HP hanya bisa diubah via support.

---

## 5. Widgets

> File: `lib/features/customer/presentation/widgets/customer_widgets.dart` (261 baris)

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

**Note:** Widget ini ada di `customer_widgets.dart` (bukan di `shared_widgets/`).

### Formatting Helpers

```dart
String rupiah(num value) => 'Rp ${value.toStringAsFixed(0).replaceAllMapped(...)}';
String shortDate(DateTime? value) => value != null ? DateFormat('dd MMM yyyy').format(value) : '-';
```

---

## 6. Router

> File: `lib/features/customer/presentation/routing/customer_router.dart` (63 baris)

### Router Configuration

```dart
final customerRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(customerAuthProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      final isAuth = authState.valueOrNull != null;
      final isFirstLogin = authState.valueOrNull?.isFirstLogin == true;

      if (!isAuth && !state.matchedLocation.startsWith('/welcome')) {
        return '/welcome';
      }
      if (isAuth && isFirstLogin && state.matchedLocation != '/change-password') {
        return '/change-password';
      }
      if (isAuth && !isFirstLogin && state.matchedLocation == '/login') {
        return '/home';
      }
      return null;
    },
    routes: [ ... ], // 25 routes
  );
});
```
