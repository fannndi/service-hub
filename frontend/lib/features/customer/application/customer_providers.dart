import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/customer_repositories.dart';
import '../domain/customer_models.dart';
import '../../../core/supabase_service.dart';

final customerAuthRepositoryProvider = Provider<CustomerAuthRepository>((_) => CustomerAuthRepository());
final storeDiscoveryRepositoryProvider = Provider<StoreDiscoveryRepository>((_) => StoreDiscoveryRepository());
final orderRepositoryProvider = Provider<OrderRepository>((_) => OrderRepository());
final paymentRepositoryProvider = Provider<PaymentRepository>((_) => PaymentRepository());
final reviewRepositoryProvider = Provider<ReviewRepository>((_) => ReviewRepository());
final disputeRepositoryProvider = Provider<DisputeRepository>((_) => DisputeRepository());
final notificationRepositoryProvider = Provider<NotificationRepository>((_) => NotificationRepository());
final sessionRepositoryProvider = Provider<SessionRepository>((_) => SessionRepository());
final uploadRepositoryProvider = Provider<UploadRepository>((_) => UploadRepository());

final customerAuthProvider = AsyncNotifierProvider<CustomerAuthNotifier, CustomerUser?>(CustomerAuthNotifier.new);

class CustomerAuthNotifier extends AsyncNotifier<CustomerUser?> {
  @override
  Future<CustomerUser?> build() async {
    final repo = ref.read(customerAuthRepositoryProvider);
    return repo.restoreSession();
  }

  Future<CustomerUser> login(String phone, String password) async {
    final repo = ref.read(customerAuthRepositoryProvider);
    final user = await repo.login(phone, password);
    state = AsyncData(user);
    return user;
  }

  Future<void> logout() async {
    await SupabaseService.instance.signOut();
    state = const AsyncData(null);
  }

  Future<void> changePassword(String oldPw, String newPw) async {
    final repo = ref.read(customerAuthRepositoryProvider);
    await repo.changePassword(oldPw, newPw);
  }

  Future<void> updateProfile({String? fullName, String? address}) async {
    final repo = ref.read(customerAuthRepositoryProvider);
    await repo.updateProfile(fullName: fullName, address: address);
    state = AsyncData(state.valueOrNull);
  }
}

final homeSummaryProvider = FutureProvider.autoDispose<HomeSummary>((ref) async {
  final sb = SupabaseService.instance;
  final userId = sb.user!.id;
  final orders = await sb.from('service_orders').select('status').eq('user_id', userId);
  final coupons = await sb.from('coupons').select('count').eq('user_id', userId).eq('is_used', false);
  final activeOrders = (orders as List).where((o) => !['completed', 'cancelled'].contains(o['status'])).length;
  return HomeSummary(activeOrders: activeOrders, activeCoupons: 0, activeWarranties: 0);
});

final deviceModelsProvider = FutureProvider.autoDispose<List<DeviceModelGroup>>((ref) async {
  final repo = ref.read(storeDiscoveryRepositoryProvider);
  return repo.getDeviceModels();
});

final storeListProvider = FutureProvider.autoDispose.family<List<ServiceStore>, ({String? brand, String? model})>((ref, params) async {
  final repo = ref.read(storeDiscoveryRepositoryProvider);
  return repo.getStores(brand: params.brand, model: params.model);
});

final storeDetailProvider = FutureProvider.autoDispose.family<ServiceStore, String>((ref, id) async {
  final repo = ref.read(storeDiscoveryRepositoryProvider);
  return repo.getDetail(id);
});

final sparepartsProvider = FutureProvider.autoDispose.family<List<SparePart>, String>((ref, storeId) async {
  final repo = ref.read(storeDiscoveryRepositoryProvider);
  return repo.getSpareparts(storeId);
});

final customerOrdersProvider = FutureProvider.autoDispose.family<List<CustomerOrder>, String>((ref, status) async {
  final repo = ref.read(orderRepositoryProvider);
  return repo.getOrders(status: status);
});

final orderDetailProvider = FutureProvider.autoDispose.family<CustomerOrder, String>((ref, id) async {
  final repo = ref.read(orderRepositoryProvider);
  return repo.getDetail(id);
});

final orderTrackingProvider = StreamProvider.autoDispose.family<List<dynamic>, String>((ref, orderId) async* {
  while (true) {
    final data = await SupabaseService.instance.from('service_tracking').select('*').eq('order_id', orderId).order('created_at', ascending: false);
    yield data;
    await Future.delayed(const Duration(seconds: 30));
  }
});

final couponsProvider = FutureProvider.autoDispose<List<CouponReward>>((ref) async {
  final repo = ref.read(reviewRepositoryProvider);
  return repo.getCoupons();
});

final notificationsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.read(notificationRepositoryProvider);
  return repo.getNotifications();
});

final notificationPreferenceProvider = StateProvider<bool>((_) => true);

final featuredStoresProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.read(storeDiscoveryRepositoryProvider);
  return repo.getStores();
});

class AddressRepository {
  Future<void> init() async {}
  Future<List<dynamic>> getProvinces() async => [];
  Future<List<dynamic>> getCities(String provinceId) async => [];
  Future<List<dynamic>> getDistricts(String cityId) async => [];
  Future<List<dynamic>> getVillages(String districtId) async => [];
}
