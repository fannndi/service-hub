import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/store_admin_providers.dart';
import '../../domain/store_admin_models.dart';
import '../widgets/store_admin_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    return StoreAdminScaffold(
      title: 'Dashboard',
      selectedIndex: 0,
      actions: [IconButton(onPressed: () => ref.read(storeAuthControllerProvider.notifier).logout(), icon: const Icon(Icons.logout), tooltip: 'Logout')],
      body: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorPanel(message: err.toString(), onRetry: () => ref.invalidate(dashboardSummaryProvider)),
        data: (data) => ListView(padding: const EdgeInsets.all(16), children: [
          Text('Halo, ${data.adminName}!', style: Theme.of(context).textTheme.headlineSmall),
          Text('${data.storeName} | Rating ${data.ratingAvg.toStringAsFixed(1)}'),
          const SizedBox(height: 16),
          MetricGrid(cards: [
            MetricCard(title: 'Revenue', value: money(data.revenueMonth), subtitle: 'Bulan ini', icon: Icons.payments_outlined),
            MetricCard(title: 'Orders', value: '${data.todayOrders}', subtitle: '${data.activeOrders} aktif', icon: Icons.receipt_long_outlined, onTap: () => context.go('/store/orders')),
            MetricCard(title: 'Customers', value: '${data.customers}', subtitle: 'Profil pelanggan', icon: Icons.groups_outlined, onTap: () => context.go('/store/customers')),
            MetricCard(title: 'Reviews', value: data.ratingAvg.toStringAsFixed(1), subtitle: 'Rata-rata rating', icon: Icons.star_border, onTap: () => context.go('/store/reviews')),
            MetricCard(title: 'Pending Payment', value: '${data.pendingPayments}', subtitle: 'Butuh verifikasi', icon: Icons.fact_check_outlined, onTap: () => context.go('/store/payments')),
            MetricCard(title: 'Active Disputes', value: '${data.activeDisputes}', subtitle: 'Klaim terbuka', icon: Icons.gavel_outlined, onTap: () => context.go('/store/disputes')),
          ]),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final entry in data.statusBreakdown.entries) StatusPill(label: '${entry.key}: ${entry.value}')]),
          const SizedBox(height: 16),
          SimpleBarChart(title: 'Revenue Trend', items: data.revenueTrend.map((e) => CategoryMetric(e.label, e.value)).toList()),
          SimpleBarChart(title: 'Service Categories', items: data.serviceCategories),
          SimpleBarChart(title: 'Sparepart Consumption', items: data.sparepartConsumption),
          Text('Recent Orders', style: Theme.of(context).textTheme.titleMedium),
          AdminDataTable<StoreOrder>(
            items: data.recentOrders,
            columns: const [DataColumn(label: Text('Order')), DataColumn(label: Text('Pelanggan')), DataColumn(label: Text('Status')), DataColumn(label: Text('Estimasi'))],
            cells: (o) => [DataCell(Text(o.orderNumber)), DataCell(Text(o.customerName)), DataCell(StatusPill(label: o.status.label)), DataCell(Text(money(o.estimatedTotal)))],
            onTap: (o) => context.go('/store/orders/${o.id}'),
          ),
        ]),
      ),
    );
  }
}
