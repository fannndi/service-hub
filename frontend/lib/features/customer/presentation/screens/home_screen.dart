import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m3_expressive/m3_expressive.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../ui/theme/app_spacing.dart';
import '../../../../ui/widgets/modern_card.dart';
import '../../application/customer_providers.dart';
import '../widgets/customer_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(customerAuthProvider).valueOrNull;
    final summary = ref.watch(homeSummaryProvider);
    final recent = ref.watch(customerOrdersProvider('recent'));
    final unread = ref.watch(unreadCountProvider).valueOrNull ?? 0;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return CustomerScaffold(
      title: context.l10n.appName,
      actions: [
        Badge(
          isLabelVisible: unread > 0,
          label: Text(unread.toString()),
          child: IconButton(
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_outlined),
          ),
        ),
        IconButton(
          onPressed: () => context.push('/profile'),
          icon: const Icon(Icons.person_outline_rounded),
        ),
      ],
      child: M3RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(homeSummaryProvider);
          ref.invalidate(customerOrdersProvider('recent'));
          ref.invalidate(featuredStoresProvider);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.greeting.replaceFirst('{name}', user?.fullName ?? context.l10n.customer),
                              style: theme.textTheme.headlineSmall?.copyWith(color: scheme.onPrimaryContainer),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Ada yang bisa kami bantu?',
                              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer.withValues(alpha: 0.85)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(Icons.phone_iphone_rounded, color: scheme.onPrimaryContainer),
                      ),
                    ]),
                    const SizedBox(height: AppSpacing.lg),
                    Row(children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: () => context.push('/stores'),
                            icon: const Icon(Icons.add_task_rounded, size: 18),
                            label: const Text('Ajukan Servis', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/orders'),
                            icon: const Icon(Icons.receipt_long_outlined, size: 18),
                            label: const Text('Pesanan Saya', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            summary.when(
              data: (data) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    _SummaryTile(
                      label: context.l10n.active,
                      value: data.activeOrders.toString(),
                      icon: Icons.pending_actions_rounded,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _SummaryTile(
                      label: context.l10n.coupons,
                      value: data.activeCoupons.toString(),
                      icon: Icons.local_offer_rounded,
                      color: scheme.secondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _SummaryTile(
                      label: context.l10n.warranty,
                      value: data.activeWarranties.toString(),
                      icon: Icons.verified_rounded,
                      color: scheme.tertiary,
                    ),
                  ],
                ),
              ),
              loading: () => const SizedBox(height: 100, child: Center(child: M3LoadingIndicator())),
              error: (_, __) => Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text(context.l10n.summaryNotAvailable),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: SectionTitle(
                context.l10n.recentOrders,
                action: TextButton(
                  onPressed: () => context.push('/orders'),
                  child: Text(context.l10n.viewAll),
                ),
              ),
            ),
            recent.when(
              data: (orders) => orders.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: EmptyMessage(context.l10n.noOrders),
                    )
                  : Column(
                      children: orders
                          .map((order) => OrderCard(
                                order: order,
                                onTap: () => context.push('/orders/${order.id}'),
                              ))
                          .toList(),
                    ),
              loading: () => const SizedBox(height: 220, child: SkeletonList(count: 3)),
              error: (_, __) => Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: EmptyMessage(context.l10n.ordersLoadError),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ModernCard(
                color: scheme.tertiaryContainer,
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: scheme.tertiary.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(Icons.bolt_rounded, color: scheme.onTertiaryContainer),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        context.l10n.promoBanner,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onTertiaryContainer,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: ModernCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
