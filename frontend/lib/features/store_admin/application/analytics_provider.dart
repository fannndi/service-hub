import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/store_admin_repositories.dart';
import 'dashboard_provider.dart';

final analyticsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.read(storeDashboardRepositoryProvider);
  return repo.getAnalytics();
});
