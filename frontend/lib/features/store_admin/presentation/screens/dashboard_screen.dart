import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:m3_expressive/m3_expressive.dart';
import '../../application/store_admin_providers.dart';
import '../../application/notification_provider.dart';
import '../../domain/store_admin_models.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../ui/theme/app_spacing.dart';
import '../widgets/store_admin_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final summary = ref.watch(dashboardSummaryProvider);
    final unread = ref.watch(storeUnreadCountProvider).valueOrNull ?? 0;
    return StoreAdminScaffold(
      title: context.l10n.dashboard,
      selectedIndex: 0,
      actions: [
        Badge(isLabelVisible: unread > 0, label: Text(unread.toString()),
          child: IconButton(onPressed: () => context.push('/store/notifications'),
            icon: const Icon(Icons.notifications_outlined))),
        IconButton(
            onPressed: () =>
                ref.read(storeAuthControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            tooltip: context.l10n.logout)
      ],
      body: summary.when(
        loading: () => const Center(child: M3LoadingIndicator()),
        error: (err, _) => ErrorPanel(
            message: err.toString(),
            onRetry: () => ref.invalidate(dashboardSummaryProvider)),
        data: (data) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, ${data.adminName}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(color: scheme.onPrimaryContainer),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          data.storeName,
                          style: TextStyle(
                            color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                    StatusPill(
                      label: context.l10n.rating + ' ${data.ratingAvg.toStringAsFixed(1)}',
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          MetricGrid(cards: [
            MetricCard(
                title: context.l10n.revenue,
                value: money(data.revenueMonth),
                subtitle: context.l10n.thisMonth,
                icon: Icons.payments_outlined),
            MetricCard(
                title: context.l10n.orders,
                value: '${data.todayOrders}',
                subtitle: context.l10n.activeOrdersCount.replaceFirst('{count}', '${data.activeOrders}'),
                icon: Icons.receipt_long_outlined,
                onTap: () => context.go('/store/orders')),
            MetricCard(
                title: context.l10n.customers,
                value: '${data.customers}',
                subtitle: context.l10n.customerProfiles,
                icon: Icons.groups_outlined,
                onTap: () => context.go('/store/customers')),
            MetricCard(
                title: context.l10n.reviews,
                value: data.ratingAvg.toStringAsFixed(1),
                subtitle: context.l10n.averageRating,
                icon: Icons.star_border,
                onTap: () => context.go('/store/reviews')),
            MetricCard(
                title: context.l10n.pendingPayment,
                value: '${data.pendingPayments}',
                subtitle: context.l10n.needsVerification,
                icon: Icons.fact_check_outlined,
                onTap: () => context.go('/store/payments')),
            MetricCard(
                title: context.l10n.activeDisputes,
                value: '${data.activeDisputes}',
                subtitle: context.l10n.openClaims,
                icon: Icons.gavel_outlined,
                onTap: () => context.go('/store/disputes')),
          ]),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final entry in data.statusBreakdown.entries)
              StatusPill(label: '${entry.key}: ${entry.value}')
          ]),
          const SizedBox(height: 16),
          SimpleBarChart(
              title: context.l10n.revenueTrend,
              items: data.revenueTrend
                  .map((e) => CategoryMetric(e.label, e.value))
                  .toList()),
          const SizedBox(height: 12),
          SimpleBarChart(
              title: context.l10n.serviceCategories, items: data.serviceCategories),
          const SizedBox(height: 12),
          SimpleBarChart(
              title: context.l10n.sparepartConsumption, items: data.sparepartConsumption),
          const SizedBox(height: 16),
          Text(context.l10n.recentOrdersTable, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          AdminDataTable<StoreOrder>(
            items: data.recentOrders,
            columns: [
              DataColumn(label: Text(context.l10n.orders)),
              DataColumn(label: Text(context.l10n.customer)),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text(context.l10n.estimate)),
            ],
            cells: (o) => [
              DataCell(Text(o.orderNumber)),
              DataCell(Text(o.customerName)),
              DataCell(StatusPill(label: o.status.label)),
              DataCell(Text(money(o.estimatedTotal)))
            ],
            onTap: (o) => context.go('/store/orders/${o.id}'),
          ),
        ]),
      ),
    );
  }
}
