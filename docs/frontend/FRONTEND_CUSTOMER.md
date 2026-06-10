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
  final int totalCompleted;
  final bool isActive;
  final Map<String, dynamic> operationalHours;
  final List<StoreReview> reviews;
}
```

#### SparePart
```dart
class SparePart {
  final String id;
  final String brand;
  final String deviceModel;
  final String partType;
  final String partName;
  final double price;
  final int qty;
  final int qtyReserved;
  final SparePartStatus status;

  int get availableQty => qty - qtyReserved;
}
```

#### CustomerOrder
```dart
class CustomerOrder {
  final String id;
  final String orderNumber;
  final DeviceType deviceType;
  final String brand;
  final String deviceModel;
  final DeliveryMethod deliveryMethod;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final double totalEstimasi;
  final double discountAmount;
  final double? finalPrice;
  final double? serviceFee;
  final String? diagnosisNote;
  final int? warrantyDays;
  final DateTime? warrantyExpiredAt;
  final DateTime? slaDeadline;
  final bool isWarrantyOrder;
  final List<OrderItem> items;
  final List<TrackingEntry> tracking;
  final List<PaymentRecord> payments;
  final ServiceStore store;
}
```

#### CreateOrderRequest
```dart
class CreateOrderRequest {
  final String storeId;
  final DeviceType deviceType;
  final String brand;
  final String deviceModel;
  final DeliveryMethod deliveryMethod;
  final String? deliveryAddress;
  final List<CreateOrderItemInput> items;
  final String? couponCode;
}
```

---

## 2. Repositories

> File: `lib/features/customer/data/customer_repositories.dart` (305 baris)

### Session Storage

```dart
class CustomerSessionStorage {
  // Keys:
  // - 'access_token', 'refresh_token'
  // - 'cached_profile', 'notification_pref'

  Future<void> saveTokens(String access, String refresh);
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearAll();
  Future<void> saveProfile(CustomerUser user);
  Future<CustomerUser?> getCachedProfile();
}
```

### API Client

```dart
class CustomerApiClient {
  // 2 Dio instances:
  // - _publicDio: tanpa token (login, register)
  // - _authDio: dengan token + auto-refresh

  // Auto-refresh flow:
  // 1. Request gagal 401
  // 2. Coba refresh token
  // 3. Jika berhasil → retry request
  // 4. Jika gagal → clear session, redirect ke login

  static T unwrap<T>(dynamic data);
  static List<T> unwrapList<T>(dynamic data, T Function(dynamic) fromJson);
}
```

### Repositories

| Repository | Methods | Endpoint |
|------------|---------|----------|
| `CustomerAuthRepository` | `login()`, `getMe()`, `getSummary()`, `changePassword()`, `updateProfile()`, `logout()` | `/auth/*`, `/me/*` |
| `StoreDiscoveryRepository` | `getStores()`, `getStore()`, `getSpareparts()`, `matchStores()` | `/stores/*` |
| `OrderRepository` | `createOrder()`, `getMyOrders()`, `getOrderDetail()`, `getOrderProgress()`, `approveOrder()`, `rejectOrder()` | `/orders/*` |
| `PaymentRepository` | `createPayment(orderId, dto)` | `/payments/:orderId` |
| `ReviewRepository` | `createReview()`, `getCoupons()` | `/reviews/*`, `/me/coupons` |
| `DisputeRepository` | `createDispute(orderId, dto)` | `/disputes/:orderId` |
| `UploadRepository` | `presignUpload(filename, contentType)` | `/uploads/presign` |
| `NotificationRepository` | `getNotifications()` | `/me/notifications` |

### Error Handling

```dart
String parseApiError(DioException e) {
  final data = e.response?.data;
  if (data?['error']?['user_message'] != null) {
    return data['error']['user_message'];
  }
  // Fallback berdasarkan type
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
      return 'Koneksi timeout.';
    case DioExceptionType.connectionError:
      return 'Tidak ada koneksi internet.';
    default:
      return 'Terjadi kesalahan.';
  }
}
```

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
  // - login(phone, password) → User?
  // - restore() → User? (dari cache)
  // - changePassword(old, new)
  // - updateProfile({fullName, address, avatarUrl})
  // - logout()
}
```

### Data Providers

```dart
final homeSummaryProvider = FutureProvider<HomeSummary>((ref) async {
  final repo = ref.watch(customerAuthRepositoryProvider);
  return repo.getSummary();
});

final featuredStoresProvider = FutureProvider<List<ServiceStore>>((ref) async {
  final repo = ref.watch(storeDiscoveryRepositoryProvider);
  return repo.getStores(limit: 5);
});

final storeListProvider = FutureProvider.family<List<ServiceStore>, StoreFilter>(
  (ref, filter) async {
    final repo = ref.watch(storeDiscoveryRepositoryProvider);
    return repo.getStores(brand: filter.brand, partType: filter.partType);
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
final customerOrdersProvider = FutureProvider<CustomerOrderList>((ref) async {
  final repo = ref.watch(orderRepositoryProvider);
  final orders = await repo.getMyOrders();
  return CustomerOrderList(
    active: orders.where((o) => !o.isCompleted && !o.isCancelled).toList(),
    completed: orders.where((o) => o.isCompleted).toList(),
    cancelled: orders.where((o) => o.isCancelled).toList(),
  );
});

final orderDetailProvider = FutureProvider.family<CustomerOrder, String>(
  (ref, orderId) async {
    final repo = ref.watch(orderRepositoryProvider);
    return repo.getOrderDetail(orderId);
  },
);

final orderTrackingProvider = StreamProvider.family<List<TrackingEntry>, String>(
  (ref, orderId) {
    return Stream.periodic(Duration(seconds: 30))
        .asyncMap((_) => ref.read(orderRepositoryProvider).getOrderProgress(orderId));
  },
);
```

### Other Providers

```dart
final couponsProvider = FutureProvider<List<CouponReward>>((ref) async { ... });
final notificationsProvider = FutureProvider<List<NotificationItem>>((ref) async { ... });
final notificationPreferenceProvider = StateProvider<bool>((ref) => true);
```

---

## 4. Screens

> File: `lib/features/customer/presentation/screens/customer_screens.dart` (2162 baris)

### Screen List

| Screen | Route | Fungsi |
|--------|-------|--------|
| `SplashScreen` | `/` | Token check + session restore |
| `WelcomeScreen` | `/welcome` | 3 entry points |
| `LoginScreen` | `/login` | Phone + password |
| `ChangePasswordScreen` | `/change-password` | Old + new password |
| `HomeScreen` | `/home` | Summary, quick actions, recent orders |
| `StoreListScreen` | `/stores` | Brand filter + search + store list |
| `StoreDetailScreen` | `/stores/:id` | Store info + spareparts + reviews |
| `ServiceFlowScreen` | `/service` | 5-step booking wizard |
| `BookingFormScreen` | `/booking` | Single-store order form |
| `BookingSuccessScreen` | - | Success confirmation |
| `OrderListScreen` | `/orders` | 3 tabs (active/completed/cancelled) |
| `OrderDetailScreen` | `/orders/:id` | Full order view |
| `DiagnosisApprovalCard` | - | Approve/reject diagnosis |
| `TrackingScreen` | `/orders/:id/tracking` | Live tracking (30s polling) |
| `PaymentUploadScreen` | `/orders/:id/payment` | Payment + proof upload |
| `ReviewFormScreen` | `/orders/:id/review` | 5-star rating + comment |
| `ReviewSuccessScreen` | - | Coupon reward banner |
| `WarrantyClaimScreen` | `/orders/:id/dispute` | Dispute form + photo evidence |
| `ProfileScreen` | `/profile` | Edit profile + logout |
| `CouponsScreen` | `/coupons` | List kupon |
| `NotificationsScreen` | `/notifications` | List notifikasi |
| `NotificationDetailScreen` | - | Detail notifikasi |
| `NotificationPreferencesScreen` | - | Setelan notifikasi |
| `SessionsScreen` | - | Active sessions |
| `SecurityScreen` | - | Security settings |

### ServiceFlowScreen (5-Step Wizard)

```
Step 1: Device Info
  - Pilih brand (Samsung, Apple, Xiaomi, dll)
  - Input device model
  - Pilih device type (Android/iOS)

Step 2: Damage Description
  - Input keluhan
  - Pilih service type

Step 3: Store Matching
  - Tampilkan stores yang cocok
  - Urutkan by rating + harga
  - Pilih store

Step 4: Data Diri
  - Auto-fill dari profile
  - Konfirmasi alamat (jika courier)

Step 5: Confirm
  - Review semua data
  - Input coupon (opsional)
  - Submit order
```

### OrderDetailScreen Sections

1. **Order Info Card** — orderNumber, status, device, dates
2. **SLA Badge** — countdown waktu tersisa
3. **Items List** — serviceType, complaint, price, technicianNote
4. **Tracking Timeline** — status history dengan timestamp
5. **Payment Info** — payment status, method, amount
6. **Action Buttons** — approve/reject (jika waiting_approval), bayar, review, dispute
7. **Credential Panel** — tampil jika customer baru (password)

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

### Formatting Helpers

```dart
String rupiah(double amount) => 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(...)}';
String shortDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);
```

---

## 6. Router

> File: `lib/features/customer/presentation/routing/customer_router.dart` (63 baris)

### Router Configuration

```dart
final customerRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(customerAuthProvider);

  return GoRouter(
    initialLocation: '/',
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
    routes: [ ... ], // 24 routes
  );
});
```

### _RouterRefresh

```dart
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen<AsyncValue<CustomerUser?>>(
      customerAuthProvider, (_, __) => notifyListeners(),
    );
  }
}
```
