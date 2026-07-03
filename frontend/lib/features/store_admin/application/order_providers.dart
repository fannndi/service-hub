import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/store_admin_repositories.dart';
import '../domain/store_admin_models.dart';

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

final storeOrderRepositoryProvider = Provider<StoreOrderRepository>((_) => StoreOrderRepository());

class StoreOrdersController extends AsyncNotifier<PageResult<StoreOrder>> {
  @override
  Future<PageResult<StoreOrder>> build() => _fetch();

  Future<PageResult<StoreOrder>> _fetch() async {
    final repo = ref.read(storeOrderRepositoryProvider);
    final query = ref.read(orderQueryProvider);
    final result = await repo.getOrders(status: query.status, q: query.search, page: query.page);
    return PageResult(items: (result['items'] as List).map((j) => StoreOrder.fromJson(j as Map<String, dynamic>)).toList(), total: result['total'] as int, page: query.page, limit: 20);
  }

  Future<void> runAction(String orderId, String action) async {
    final repo = ref.read(storeOrderRepositoryProvider);
    await repo.runAction(orderId, action);
    ref.invalidateSelf();
  }

  Future<void> submitDiagnosis(String orderId, Map<String, dynamic> payload) async {
    final repo = ref.read(storeOrderRepositoryProvider);
    await repo.submitDiagnosis(orderId, payload);
    ref.invalidateSelf();
  }
}

final orderDetailProvider = FutureProvider.autoDispose.family<StoreOrder, String>((ref, id) async {
  final repo = ref.read(storeOrderRepositoryProvider);
  return repo.getOrderDetail(id);
});
