import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/customer_models.dart';
import '../../../core/supabase_service.dart';

final homeSummaryProvider = FutureProvider.autoDispose<HomeSummary>((ref) async {
  final sb = SupabaseService.instance;
  final userId = sb.user?.id;
  if (userId == null) return const HomeSummary(activeOrders: 0, activeCoupons: 0, activeWarranties: 0);

  final activeOrders = await sb.rpc('get_home_summary', params: {'p_user_id': userId});

  if (activeOrders is Map<String, dynamic>) {
    return HomeSummary(
      activeOrders: activeOrders['active_orders'] as int? ?? 0,
      activeCoupons: activeOrders['active_coupons'] as int? ?? 0,
      activeWarranties: activeOrders['active_warranties'] as int? ?? 0,
    );
  }

  final orders = await sb.from('service_orders').select('id,status').eq('user_id', userId).limit(50);
  final activeCount = (orders as List).where((o) => !['completed', 'cancelled'].contains(o['status'])).length;

  final coupons = await sb.from('coupons').select('id').eq('user_id', userId).eq('is_used', false).limit(1);
  final warrantyOrders = await sb.from('service_orders').select('id').eq('user_id', userId)
      .gt('warranty_expired_at', DateTime.now().toUtc().toIso8601String()).limit(1);

  return HomeSummary(
    activeOrders: activeCount,
    activeCoupons: (coupons as List).length,
    activeWarranties: (warrantyOrders as List).length,
  );
});
