import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/store_admin_repositories.dart';
import '../domain/store_admin_models.dart';
import '../../../core/supabase_service.dart';

final storeAuthRepositoryProvider = Provider<StoreAuthRepository>((_) => StoreAuthRepository());
final storeOperationsRepositoryProvider = Provider<StoreOperationsRepository>((_) => StoreOperationsRepository());

final storeAuthControllerProvider = AsyncNotifierProvider<StoreAuthController, StoreAdminSession?>(StoreAuthController.new);

class StoreAuthController extends AsyncNotifier<StoreAdminSession?> {
  @override
  Future<StoreAdminSession?> build() async {
    final repo = ref.read(storeAuthRepositoryProvider);
    return repo.restoreSession();
  }

  Future<void> login(String phone, String password) async {
    final repo = ref.read(storeAuthRepositoryProvider);
    final user = await repo.login(phone, password);
    state = AsyncData(user);
  }

  Future<void> changePassword(String oldPw, String newPw) async {
    final repo = ref.read(storeAuthRepositoryProvider);
    await repo.changePassword(oldPw, newPw);
    final session = state.valueOrNull;
    if (session != null) {
      state = AsyncData(session.copyWith(isFirstLogin: false));
    }
  }

  Future<void> logout() async {
    await SupabaseService.instance.signOut();
    state = const AsyncData(null);
  }
}

final dashboardSummaryProvider = StreamProvider.autoDispose<DashboardSummary>((ref) async* {
  while (true) {
    final repo = ref.read(storeOperationsRepositoryProvider);
    final data = await repo.getDashboardSummary();
    yield data;
    await Future.delayed(const Duration(seconds: 60));
  }
});

class OrderQuery {
  final String? search;
  final String? status;
  final int page;
  OrderQuery({this.search, this.status, this.page = 1});
  OrderQuery copyWith({String? search, String? status, int? page}) => OrderQuery(
    search: search ?? this.search, status: status ?? this.status, page: page ?? this.page,
  );
}

final orderQueryProvider = StateProvider<OrderQuery>((_) => OrderQuery());

final storeOrdersProvider = AsyncNotifierProvider<StoreOrdersController, PageResult<StoreOrder>>(StoreOrdersController.new);

class StoreOrdersController extends AsyncNotifier<PageResult<StoreOrder>> {
  @override
  Future<PageResult<StoreOrder>> build() => _fetch();

  Future<PageResult<StoreOrder>> _fetch() async {
    final repo = ref.read(storeOperationsRepositoryProvider);
    final query = ref.read(orderQueryProvider);
    final result = await repo.getOrders(status: query.status, q: query.search, page: query.page);
    return PageResult(items: (result['items'] as List).map((j) => StoreOrder.fromJson(j)).toList(), total: result['total'] as int, page: query.page);
  }

  Future<void> runAction(String orderId, String action) async {
    final repo = ref.read(storeOperationsRepositoryProvider);
    await repo.runAction(orderId, action);
    ref.invalidateSelf();
  }

  Future<void> submitDiagnosis(String orderId, Map<String, dynamic> payload) async {
    final repo = ref.read(storeOperationsRepositoryProvider);
    await repo.submitDiagnosis(orderId, payload);
    ref.invalidateSelf();
  }
}

final orderDetailProvider = FutureProvider.autoDispose.family<StoreOrder, String>((ref, id) async {
  final repo = ref.read(storeOperationsRepositoryProvider);
  return repo.getOrderDetail(id);
});

class InventoryQuery {
  final String? search;
  final String? brand;
  final String? deviceModel;
  final String? partType;
  final int page;
  InventoryQuery({this.search, this.brand, this.deviceModel, this.partType, this.page = 1});
  InventoryQuery copyWith({String? search, String? brand, String? deviceModel, String? partType, int? page}) => InventoryQuery(
    search: search ?? this.search, brand: brand ?? this.brand, deviceModel: deviceModel ?? this.deviceModel,
    partType: partType ?? this.partType, page: page ?? this.page,
  );
}

final inventoryQueryProvider = StateProvider<InventoryQuery>((_) => InventoryQuery());

final inventoryProvider = AsyncNotifierProvider<InventoryController, PageResult<Sparepart>>(InventoryController.new);

class InventoryController extends AsyncNotifier<PageResult<Sparepart>> {
  @override
  Future<PageResult<Sparepart>> build() => _fetch();

  Future<PageResult<Sparepart>> _fetch() async {
    final repo = ref.read(storeOperationsRepositoryProvider);
    final query = ref.read(inventoryQueryProvider);
    final result = await repo.getSpareparts(search: query.search, brand: query.brand, deviceModel: query.deviceModel, partType: query.partType, page: query.page);
    return PageResult(items: (result['items'] as List).map((j) => Sparepart.fromJson(j)).toList(), total: result['total'] as int, page: query.page);
  }

  Future<void> save(Map<String, dynamic> data, {String? id}) async {
    final repo = ref.read(storeOperationsRepositoryProvider);
    await repo.saveSparepart(data, id: id);
    ref.invalidateSelf();
  }

  Future<void> adjustStock(String id, int delta) async {
    final repo = ref.read(storeOperationsRepositoryProvider);
    await repo.adjustStock(id, delta);
    ref.invalidateSelf();
  }
}

final brandsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final repo = ref.read(storeOperationsRepositoryProvider);
  return repo.getBrands();
});

final deviceModelsProvider = FutureProvider.autoDispose.family<List<String>, String?>((ref, brand) async {
  final repo = ref.read(storeOperationsRepositoryProvider);
  return repo.getDeviceModels(brand);
});

final paymentsProvider = AsyncNotifierProvider<PaymentsController, PageResult<PaymentRecord>>(PaymentsController.new);

class PaymentsController extends AsyncNotifier<PageResult<PaymentRecord>> {
  @override
  Future<PageResult<PaymentRecord>> build() async {
    final repo = ref.read(storeOperationsRepositoryProvider);
    final result = await repo.getPayments();
    return PageResult(items: (result['items'] as List).map((j) => PaymentRecord.fromJson(j)).toList(), total: result['total'] as int, page: 1);
  }

  Future<void> confirm(String orderId, String paymentId) async {
    final repo = ref.read(storeOperationsRepositoryProvider);
    await repo.confirmPayment(orderId, paymentId);
    ref.invalidateSelf();
  }
}

final disputesProvider = AsyncNotifierProvider<DisputesController, PageResult<DisputeCase>>(DisputesController.new);

class DisputesController extends AsyncNotifier<PageResult<DisputeCase>> {
  @override
  Future<PageResult<DisputeCase>> build() async {
    final repo = ref.read(storeOperationsRepositoryProvider);
    final result = await repo.getDisputes();
    return PageResult(items: (result['items'] as List).map((j) => DisputeCase.fromJson(j)).toList(), total: result['total'] as int, page: 1);
  }

  Future<void> resolve(String disputeId, bool accept, String reason) async {
    final repo = ref.read(storeOperationsRepositoryProvider);
    await repo.resolveDispute(disputeId, accept, reason);
    ref.invalidateSelf();
  }
}

final reviewsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.read(storeOperationsRepositoryProvider);
  final result = await repo.getReviews();
  return result['items'] as List<dynamic>;
});

final notificationsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.read(storeOperationsRepositoryProvider);
  return repo.getNotifications();
});

final customersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.read(storeOperationsRepositoryProvider);
  final result = await repo.getCustomers();
  return result['items'] as List<dynamic>;
});

final analyticsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.read(storeOperationsRepositoryProvider);
  return repo.getAnalytics();
});

final storeProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.read(storeOperationsRepositoryProvider);
  return repo.getProfile();
});
