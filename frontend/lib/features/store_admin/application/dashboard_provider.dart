import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/store_admin_repositories.dart';
import '../domain/store_admin_models.dart';

final storeDashboardRepositoryProvider = Provider<StoreDashboardRepository>((_) => StoreDashboardRepository());

final dashboardSummaryProvider = StreamProvider.autoDispose<DashboardSummary>((ref) async* {
  while (true) {
    final repo = ref.read(storeDashboardRepositoryProvider);
    final data = await repo.getDashboardSummary();
    yield data;
    await Future.delayed(const Duration(seconds: 60));
  }
});
