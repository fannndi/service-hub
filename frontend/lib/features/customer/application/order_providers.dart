import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/customer_repositories.dart';
import '../domain/customer_models.dart';
import '../../../core/supabase_service.dart';

final orderRepositoryProvider = Provider<OrderRepository>((_) => OrderRepository());

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
