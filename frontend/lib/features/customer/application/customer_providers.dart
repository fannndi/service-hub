import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_config.dart';
import '../data/customer_repositories.dart';
import '../domain/device_model.dart';
import '../domain/customer_models.dart';

final customerSessionProvider = Provider<CustomerSessionStorage>(
    (ref) => const CustomerSessionStorage(FlutterSecureStorage()));
final customerApiClientProvider = Provider<CustomerApiClient>((ref) =>
    CustomerApiClient(
        ref.watch(appConfigProvider), ref.watch(customerSessionProvider)));
final customerAuthRepositoryProvider = Provider<CustomerAuthRepository>((ref) =>
    CustomerAuthRepository(ref.watch(customerApiClientProvider),
        ref.watch(customerSessionProvider)));
final storeDiscoveryRepositoryProvider = Provider<StoreDiscoveryRepository>(
    (ref) => StoreDiscoveryRepository(ref.watch(customerApiClientProvider)));
final orderRepositoryProvider = Provider<OrderRepository>(
    (ref) => OrderRepository(ref.watch(customerApiClientProvider)));
final uploadRepositoryProvider = Provider<UploadRepository>(
    (ref) => UploadRepository(ref.watch(customerApiClientProvider)));
final paymentRepositoryProvider = Provider<PaymentRepository>(
    (ref) => PaymentRepository(ref.watch(customerApiClientProvider)));
final reviewRepositoryProvider = Provider<ReviewRepository>(
    (ref) => ReviewRepository(ref.watch(customerApiClientProvider)));
final disputeRepositoryProvider = Provider<DisputeRepository>(
    (ref) => DisputeRepository(ref.watch(customerApiClientProvider)));
final notificationRepositoryProvider = Provider<NotificationRepository>(
    (ref) => NotificationRepository(ref.watch(customerApiClientProvider)));
final sessionRepositoryProvider = Provider<SessionRepository>(
    (ref) => SessionRepository(ref.watch(customerApiClientProvider)));

class CustomerAuthNotifier extends AsyncNotifier<CustomerUser?> {
  @override
  Future<CustomerUser?> build() async {
    final token = await ref.read(customerSessionProvider).readAccessToken();
    if (token == null) return null;
    try {
      return await ref.read(customerAuthRepositoryProvider).getMe();
    } catch (_) {
      await ref.read(customerSessionProvider).clearAll();
      return null;
    }
  }

  Future<CustomerUser> restoreSession() async {
    state = const AsyncLoading();
    final user = await ref.read(customerAuthRepositoryProvider).getMe();
    state = AsyncData(user);
    return user;
  }

  Future<LoginResult> login(String phone, String password) async {
    state = const AsyncLoading();
    final result =
        await ref.read(customerAuthRepositoryProvider).login(phone, password);
    state = AsyncData(result.user);
    return result;
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await ref
        .read(customerAuthRepositoryProvider)
        .changePassword(oldPassword, newPassword);
    final user = await ref.read(customerAuthRepositoryProvider).getMe();
    state = AsyncData(user.copyWith(isFirstLogin: false));
  }

  Future<void> updateProfile(
      {required String fullName, String? address, String? avatarUrl}) async {
    final user = await ref.read(customerAuthRepositoryProvider).updateProfile(
        fullName: fullName, address: address, avatarUrl: avatarUrl);
    state = AsyncData(user);
  }

  Future<void> logout() async {
    await ref.read(customerAuthRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}

final customerAuthProvider =
    AsyncNotifierProvider<CustomerAuthNotifier, CustomerUser?>(
        CustomerAuthNotifier.new);

final homeSummaryProvider = FutureProvider<HomeSummary>(
    (ref) => ref.watch(customerAuthRepositoryProvider).getSummary());
final featuredStoresProvider = FutureProvider<List<ServiceStore>>(
    (ref) => ref.watch(storeDiscoveryRepositoryProvider).getStores());
final deviceModelsProvider = FutureProvider<List<DeviceModelGroup>>(
    (ref) => ref.watch(storeDiscoveryRepositoryProvider).getDeviceModels());
final storeListProvider =
    FutureProvider.family<List<ServiceStore>, ({String? brand, String? model})>(
        (ref, filter) {
  return ref
      .watch(storeDiscoveryRepositoryProvider)
      .getStores(brand: filter.brand, deviceModel: filter.model);
});
final storeDetailProvider = FutureProvider.family<ServiceStore, String>(
    (ref, id) => ref.watch(storeDiscoveryRepositoryProvider).getStore(id));
final sparepartsProvider = FutureProvider.family<List<SparePart>, String>(
    (ref, storeId) =>
        ref.watch(storeDiscoveryRepositoryProvider).getSpareparts(storeId));

const activeStatusCsv =
    'waiting_device,device_received,diagnosing,waiting_approval,waiting_sparepart,repairing,quality_check,waiting_payment,disputed';

final customerOrdersProvider =
    FutureProvider.family<List<CustomerOrder>, String>((ref, group) {
  final status = switch (group) {
    'completed' => 'completed',
    'cancelled' => 'cancelled',
    'recent' => null,
    _ => activeStatusCsv,
  };
  return ref
      .watch(orderRepositoryProvider)
      .getMyOrders(status: status, limit: group == 'recent' ? 3 : 20);
});

final orderDetailProvider = FutureProvider.family<CustomerOrder, String>(
    (ref, orderId) =>
        ref.watch(orderRepositoryProvider).getOrderDetail(orderId));

final orderTrackingProvider =
    StreamProvider.family<CustomerOrder, String>((ref, orderId) async* {
  final repo = ref.watch(orderRepositoryProvider);
  yield await repo.getOrderProgress(orderId);
  await for (final _ in Stream<void>.periodic(const Duration(seconds: 30))) {
    yield await repo.getOrderProgress(orderId);
  }
});

final couponsProvider = FutureProvider<List<CouponReward>>(
    (ref) => ref.watch(reviewRepositoryProvider).getCoupons());
final notificationsProvider = FutureProvider<List<NotificationItem>>(
    (ref) => ref.watch(notificationRepositoryProvider).getNotifications());
final notificationPreferenceProvider = FutureProvider<bool>(
    (ref) => ref.watch(customerSessionProvider).readNotificationPreference());
