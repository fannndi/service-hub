import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/customer_models.dart';
import '../../../core/supabase_service.dart';

final homeSummaryProvider = FutureProvider.autoDispose<HomeSummary>((ref) async {
  final sb = SupabaseService.instance;
  final userId = sb.user!.id;
  final orders = await sb.from('service_orders').select('*').eq('user_id', userId);
  final activeOrders = (orders as List).where((o) => !['completed', 'cancelled'].contains(o['status'])).length;
  return HomeSummary(activeOrders: activeOrders, activeCoupons: 0, activeWarranties: 0);
});
