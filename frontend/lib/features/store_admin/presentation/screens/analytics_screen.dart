import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/store_admin_providers.dart';
import '../../domain/store_admin_models.dart';
import '../widgets/store_admin_widgets.dart';
import '../../../../../core/l10n/app_localizations.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(analyticsProvider);
    return StoreAdminScaffold(
      title: context.l10n.analytics,
      selectedIndex: 4,
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorPanel(message: e.toString()),
        data: (data) {
          final revenueMonth = (data['revenueMonth'] as num?)?.toDouble() ?? 0;
          final activeOrders = data['activeOrders'] as int? ?? 0;
          final pendingOrders = data['pendingOrders'] as int? ?? 0;
          final completionRate = (data['completionRate'] as num?)?.toDouble() ?? 0;
          final ratingAvg = (data['ratingAvg'] as num?)?.toDouble() ?? 0;
          final ordersTrend = ((data['ordersTrend'] as List?) ?? [])
              .whereType<Map<String, dynamic>>()
              .map(CategoryMetric.fromJson)
              .toList();
          final serviceCategories = ((data['serviceCategories'] as List?) ?? [])
              .whereType<Map<String, dynamic>>()
              .map(CategoryMetric.fromJson)
              .toList();
          final sparepartConsumption =
              ((data['sparepartConsumption'] as List?) ?? [])
                  .whereType<Map<String, dynamic>>()
                  .map(CategoryMetric.fromJson)
                  .toList();
          return ListView(padding: const EdgeInsets.all(16), children: [
            MetricGrid(cards: [
              MetricCard(
                  title: context.l10n.revenue,
                  value: money(revenueMonth),
                  icon: Icons.payments_outlined),
              MetricCard(
                  title: context.l10n.orders,
                  value: '${activeOrders + pendingOrders}',
                  icon: Icons.receipt_long_outlined),
              MetricCard(
                  title: context.l10n.completion,
                  value: '${completionRate.toStringAsFixed(1)}%',
                  icon: Icons.task_alt_outlined),
              MetricCard(
                  title: context.l10n.rating,
                  value: ratingAvg.toStringAsFixed(1),
                  icon: Icons.star_outline),
            ]),
            SimpleBarChart(
                title: context.l10n.orderTrends, items: ordersTrend),
            SimpleBarChart(
                title: context.l10n.popularServices, items: serviceCategories),
            SimpleBarChart(
                title: context.l10n.sparepartUsage, items: sparepartConsumption),
          ]);
        },
      ),
    );
  }
}
