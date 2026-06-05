import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/store_admin_repositories.dart';
import '../domain/store_admin_models.dart';

final storeAuthControllerProvider = AsyncNotifierProvider<StoreAuthController, StoreAdminSession?>(StoreAuthController.new);
final dashboardSummaryProvider = StreamProvider.autoDispose<DashboardSummary>((ref) async* {
  final repo = ref.watch(storeOperationsRepositoryProvider);
  final session = ref.watch(storeAuthControllerProvider).valueOrNull;
  yield await repo.dashboard(session);
  await for (final _ in Stream.periodic(const Duration(seconds: 60))) {
    yield await repo.dashboard(session);
  }
});
final orderQueryProvider = StateProvider<OrderQuery>((ref) => const OrderQuery());
final storeOrdersProvider = AsyncNotifierProvider<StoreOrdersController, PageResult<StoreOrder>>(StoreOrdersController.new);
final orderDetailProvider = FutureProvider.family.autoDispose<StoreOrder, String>((ref, id) => ref.watch(storeOperationsRepositoryProvider).orderDetail(id));
final inventoryQueryProvider = StateProvider<InventoryQuery>((ref) => const InventoryQuery());
final inventoryProvider = AsyncNotifierProvider<InventoryController, PageResult<Sparepart>>(InventoryController.new);
final paymentsProvider = AsyncNotifierProvider<PaymentsController, PageResult<PaymentRecord>>(PaymentsController.new);
final disputesProvider = AsyncNotifierProvider<DisputesController, PageResult<DisputeCase>>(DisputesController.new);
final reviewsProvider = FutureProvider.autoDispose((ref) => ref.watch(storeOperationsRepositoryProvider).reviews());
final notificationsProvider = FutureProvider.autoDispose((ref) => ref.watch(storeOperationsRepositoryProvider).notifications());
final customersProvider = FutureProvider.autoDispose((ref) => ref.watch(storeOperationsRepositoryProvider).customers());
final analyticsProvider = FutureProvider.autoDispose((ref) => ref.watch(storeOperationsRepositoryProvider).analytics(ref.watch(storeAuthControllerProvider).valueOrNull));
final storeProfileProvider = FutureProvider.autoDispose((ref) => ref.watch(storeOperationsRepositoryProvider).storeProfile());

class StoreAuthController extends AsyncNotifier<StoreAdminSession?> {
  @override
  Future<StoreAdminSession?> build() => ref.watch(storeAuthRepositoryProvider).restoreSession();

  Future<void> login(String phoneNumber, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(storeAuthRepositoryProvider).login(phoneNumber: phoneNumber, password: password));
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final session = state.valueOrNull;
    if (session == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(storeAuthRepositoryProvider).changePassword(currentPassword, newPassword, session));
  }

  Future<void> logout() async {
    await ref.read(storeAuthRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}

class StoreOrdersController extends AsyncNotifier<PageResult<StoreOrder>> {
  @override
  Future<PageResult<StoreOrder>> build() {
    final query = ref.watch(orderQueryProvider);
    return ref.watch(storeOperationsRepositoryProvider).orders(status: query.status, query: query.search, page: query.page, actionGroup: query.actionGroup);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> runAction(String orderId, String action) async {
    await ref.read(storeOperationsRepositoryProvider).updateOrderStatus(orderId, action);
    await refresh();
  }

  Future<void> submitDiagnosis(String orderId, Map<String, Object?> payload) async {
    await ref.read(storeOperationsRepositoryProvider).submitDiagnosis(orderId, payload);
    await refresh();
  }
}

class InventoryController extends AsyncNotifier<PageResult<Sparepart>> {
  @override
  Future<PageResult<Sparepart>> build() {
    final query = ref.watch(inventoryQueryProvider);
    return ref.watch(storeOperationsRepositoryProvider).spareparts(query: query.search, status: query.status, page: query.page);
  }

  Future<void> save(Map<String, Object?> payload, {String? id}) async {
    await ref.read(storeOperationsRepositoryProvider).saveSparepart(payload, id: id);
    ref.invalidateSelf();
  }
}

class PaymentsController extends AsyncNotifier<PageResult<PaymentRecord>> {
  @override
  Future<PageResult<PaymentRecord>> build() => ref.watch(storeOperationsRepositoryProvider).payments();

  Future<void> confirm(String orderId, String paymentId) async {
    await ref.read(storeOperationsRepositoryProvider).confirmPayment(orderId, paymentId);
    ref.invalidateSelf();
  }
}

class DisputesController extends AsyncNotifier<PageResult<DisputeCase>> {
  @override
  Future<PageResult<DisputeCase>> build() => ref.watch(storeOperationsRepositoryProvider).disputes();

  Future<void> resolve(String disputeId, bool accept, String reason) async {
    await ref.read(storeOperationsRepositoryProvider).resolveDispute(disputeId, accept, reason);
    ref.invalidateSelf();
  }
}

class OrderQuery {
  const OrderQuery({this.search, this.status, this.actionGroup, this.page = 1});
  final String? search;
  final String? status;
  final String? actionGroup;
  final int page;
  OrderQuery copyWith({String? search, String? status, String? actionGroup, int? page}) => OrderQuery(search: search ?? this.search, status: status, actionGroup: actionGroup ?? this.actionGroup, page: page ?? this.page);
}

class InventoryQuery {
  const InventoryQuery({this.search, this.status, this.page = 1});
  final String? search;
  final String? status;
  final int page;
  InventoryQuery copyWith({String? search, String? status, int? page}) => InventoryQuery(search: search ?? this.search, status: status, page: page ?? this.page);
}
