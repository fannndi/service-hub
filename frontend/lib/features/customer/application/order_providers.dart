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

final orderTrackingProvider = StreamProvider.autoDispose.family<List<TrackingEntry>, String>((ref, orderId) {
  return Stream.periodic(const Duration(seconds: 30), (_) => _).asyncMap((_) async {
    final sb = SupabaseService.instance;
    final data = await sb.from('service_tracking')
        .select('id,order_id,status,note,created_by_type,created_by_id,created_at')
        .eq('order_id', orderId)
        .order('created_at', ascending: false);
    return (data as List?)?.map((e) => TrackingEntry.fromJson(e)).toList() ?? [];
  });
});