import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/store_admin_providers.dart';
import '../../domain/store_admin_models.dart';
import '../widgets/store_admin_widgets.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(analyticsProvider);
    return StoreAdminScaffold(
      title: 'Analytics',
      selectedIndex: 4,
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorPanel(message: e.toString()),
        data: (data) => ListView(padding: const EdgeInsets.all(16), children: [
          MetricGrid(cards: [
            MetricCard(
                title: 'Revenue',
                value: money(data.revenueMonth),
                icon: Icons.payments_outlined),
            MetricCard(
                title: 'Orders',
                value: '${data.activeOrders + data.pendingOrders}',
                icon: Icons.receipt_long_outlined),
            MetricCard(
                title: 'Completion',
                value: '${data.completionRate.toStringAsFixed(1)}%',
                icon: Icons.task_alt_outlined),
            MetricCard(
                title: 'Rating',
                value: data.ratingAvg.toStringAsFixed(1),
                icon: Icons.star_outline),
          ]),
          SimpleBarChart(
              title: 'Order Trends',
              items: data.ordersTrend
                  .map((e) => CategoryMetric(e.label, e.value))
                  .toList()),
          SimpleBarChart(
              title: 'Popular Services', items: data.serviceCategories),
          SimpleBarChart(
              title: 'Sparepart Usage', items: data.sparepartConsumption),
        ]),
      ),
    );
  }
}
