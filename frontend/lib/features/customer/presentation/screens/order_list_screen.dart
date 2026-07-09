import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../ui/theme/app_spacing.dart';
import '../../application/customer_providers.dart';
import '../widgets/customer_widgets.dart';
import 'package:m3_expressive/m3_expressive.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});
  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  String _group = 'active';

  @override
  Widget build(BuildContext context) => CustomerScaffold(
    title: context.l10n.myOrders,
    child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
        child: SizedBox(
          height: 48,
          child: SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'active', label: Text(context.l10n.active)),
              ButtonSegment(value: 'completed', label: Text(context.l10n.completed)),
              ButtonSegment(value: 'cancelled', label: Text(context.l10n.cancelled)),
            ],
            selected: {_group},
            onSelectionChanged: (v) => setState(() => _group = v.first),
            showSelectedIcon: false,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Expanded(child: _OrderTab(_group)),
    ]),
  );
}

class _OrderTab extends ConsumerWidget {
  const _OrderTab(this.group);
  final String group;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(customerOrdersProvider(group));
    return M3RefreshIndicator(
      onRefresh: () async => ref.invalidate(customerOrdersProvider(group)),
      child: AsyncPage(
        value: orders,
        builder: (items) => items.isEmpty
          ? EmptyMessage(context.l10n.noOrders)
          : ListView(
              children: items
                .map((order) => OrderCard(
                    order: order,
                    onTap: () => context.push('/orders/${order.id}')))
                .toList()),
      ),
    );
  }
}
