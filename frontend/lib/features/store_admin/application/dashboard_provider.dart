import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/store_admin_repositories.dart';
import '../domain/store_admin_models.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/cache/cache_config.dart';

final storeDashboardRepositoryProvider = Provider<StoreDashboardRepository>((_) => StoreDashboardRepository());

final dashboardSummaryProvider = StreamProvider.autoDispose<DashboardSummary>((ref) {
  final repo = ref.read(storeDashboardRepositoryProvider);
  return Stream.periodic(const Duration(seconds: 60), (_) => _).asyncMap((_) async {
    final cache = CacheManager.instance;
    final cached = await cache.getAsync<Map<String, dynamic>>('dashboard', ttl: CacheConfig.dashboard);

    try {
      final data = await repo.getDashboardSummary();
      return data;
    } catch (e) {
      debugPrint('Dashboard refresh error: $e');
      if (cached != null) return DashboardSummary.fromJson(cached);
      rethrow;
    }
  }).handleError((e) {
    debugPrint('Dashboard refresh error: $e');
  });
});
