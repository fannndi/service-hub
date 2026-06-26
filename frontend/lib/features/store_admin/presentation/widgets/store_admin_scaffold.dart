import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../ui/theme/app_decorations.dart';
import '../../../../ui/theme/app_spacing.dart';
import '../../../../ui/widgets/modern_card.dart';
import '../../application/store_admin_providers.dart';

class StoreAdminScaffold extends ConsumerWidget {
  const StoreAdminScaffold(
      {super.key,
      required this.title,
      required this.selectedIndex,
      required this.body,
      this.actions,
      this.showBackButton = false});
  final String title;
  final int selectedIndex;
  final Widget body;
  final List<Widget>? actions;
  final bool showBackButton;

  static const destinations = [
    ('Dashboard', Icons.dashboard_outlined, '/store/dashboard'),
    ('Order', Icons.receipt_long_outlined, '/store/orders'),
    ('Stok', Icons.inventory_2_outlined, '/store/inventory'),
    ('Bayar', Icons.payments_outlined, '/store/payments'),
    ('Analitik', Icons.query_stats_outlined, '/store/analytics'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final scheme = Theme.of(context).colorScheme;
    final unread = ref.watch(storeUnreadCountProvider).valueOrNull ?? 0;

    final notifIcon = Badge(
      isLabelVisible: unread > 0,
      label: Text(unread.toString()),
      child: const Icon(Icons.notifications_outlined),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ...?actions,
          IconButton(
            icon: notifIcon,
            onPressed: () => context.push('/store/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        leadingWidth: showBackButton ? 56 : null,
      ),
      drawer: wide
          ? null
          : Drawer(
              child: SafeArea(child: _NavList(selectedIndex: selectedIndex)),
            ),
      body: GradientBackground(
        child: Row(
          children: [
            if (wide)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  boxShadow: AppShadows.card(context),
                ),
                child: NavigationRail(
                  extended: MediaQuery.sizeOf(context).width >= 1200,
                  selectedIndex: selectedIndex,
                  destinations: [
                    for (final item in destinations)
                      NavigationRailDestination(
                        icon: Icon(item.$2),
                        label: Text(item.$1),
                      )
                  ],
                  onDestinationSelected: (index) =>
                      context.go(destinations[index].$3),
                ),
              ),
            Expanded(child: body),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex,
              destinations: [
                for (final item in destinations)
                  NavigationDestination(icon: Icon(item.$2), label: item.$1)
              ],
              onDestinationSelected: (index) =>
                  context.go(destinations[index].$3),
            ),
    );
  }
}

class _NavList extends StatelessWidget {
  const _NavList({required this.selectedIndex});
  final int selectedIndex;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              'ServisGadget Admin',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Text(
              'Operasional toko',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          for (var i = 0; i < StoreAdminScaffold.destinations.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              child: ListTile(
                selected: i == selectedIndex,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                selectedTileColor: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.5),
                leading: Icon(StoreAdminScaffold.destinations[i].$2),
                title: Text(StoreAdminScaffold.destinations[i].$1),
                onTap: () =>
                    context.go(StoreAdminScaffold.destinations[i].$3),
              ),
            ),
        ],
      );
}
