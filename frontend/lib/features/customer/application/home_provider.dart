import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/customer_models.dart';
import '../../../core/supabase_service.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/cache/cache_config.dart';

final homeSummaryProvider = FutureProvider.autoDispose<HomeSummary>((ref) async {
  final sb = SupabaseService.instance;
  final userId = sb.user?.id;
  if (userId == null) return const HomeSummary(activeOrders: 0, activeCoupons: 0, activeWarranties: 0);

  final cache = CacheManager.instance;
  final cached = await cache.getAsync<Map<String, dynamic>>('home_$userId', ttl: CacheConfig.homeSummary);
  if (cached != null) {
    return HomeSummary(
      activeOrders: cached['activeOrders'] as int? ?? 0,
      activeCoupons: cached['activeCoupons'] as int? ?? 0,
      activeWarranties: cached['activeWarranties'] as int? ?? 0,
    );
  }

  final result = await sb.rpc('get_home_summary', params: {'p_user_id': userId});

  if (result is Map<String, dynamic>) {
    final summary = HomeSummary(
      activeOrders: result['active_orders'] as int? ?? 0,
      activeCoupons: result['active_coupons'] as int? ?? 0,
      activeWarranties: result['active_warranties'] as int? ?? 0,
    );
    await cache.set('home_$userId', {
      'activeOrders': summary.activeOrders,
      'activeCoupons': summary.activeCoupons,
      'activeWarranties': summary.activeWarranties,
    }, ttl: CacheConfig.homeSummary);
    return summary;
  }

  final orders = await sb.from('service_orders').select('id,status').eq('user_id', userId).limit(50);
  final ordersList = orders is List ? orders as List : <dynamic>[];
  final activeCount = ordersList.where((o) => !['completed', 'cancelled'].contains(o['status'])).length;

  final coupons = await sb.from('coupons').select('id').eq('user_id', userId).eq('is_used', false).limit(1);
  final warrantyOrders = await sb.from('service_orders').select('id').eq('user_id', userId)
      .gt('warranty_expired_at', DateTime.now().toUtc().toIso8601String()).limit(1);

  final summary = HomeSummary(
    activeOrders: activeCount,
    activeCoupons: (coupons is List ? (coupons as List).length : 0),
    activeWarranties: (warrantyOrders is List ? (warrantyOrders as List).length : 0),
  );
  await cache.set('home_$userId', {
    'activeOrders': summary.activeOrders,
    'activeCoupons': summary.activeCoupons,
    'activeWarranties': summary.activeWarranties,
  }, ttl: CacheConfig.homeSummary);
  return summary;
});
