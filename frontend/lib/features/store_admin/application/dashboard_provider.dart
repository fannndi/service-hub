import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/store_admin_repositories.dart';
import '../domain/store_admin_models.dart';

final storeDashboardRepositoryProvider = Provider<StoreDashboardRepository>((_) => StoreDashboardRepository());

final dashboardSummaryProvider = StreamProvider.autoDispose<DashboardSummary>((ref) {
  final repo = ref.read(storeDashboardRepositoryProvider);
  return Stream.periodic(const Duration(seconds: 60), (_) => _).asyncMap((_) async {
    final data = await repo.getDashboardSummary();
    return data;
  }).handleError((e) { debugPrint('dashboardSummaryProvider error: $e'); throw e; });
});
