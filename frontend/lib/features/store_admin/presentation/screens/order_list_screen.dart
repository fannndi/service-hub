import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../ui/theme/app_spacing.dart';
import '../../application/store_admin_providers.dart';
import '../../domain/store_admin_models.dart';
import '../widgets/store_admin_widgets.dart';
import 'package:m3_expressive/m3_expressive.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});
  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(storeOrdersProvider);
    final query = ref.watch(orderQueryProvider);
    final scheme = Theme.of(context).colorScheme;

    return StoreAdminScaffold(
      title: context.l10n.orderManagement,
      selectedIndex: 1,
      body: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
          decoration: BoxDecoration(color: scheme.surface),
          child: Column(children: [
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: context.l10n.searchOrdersHint,
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
              onSubmitted: (q) => ref.read(orderQueryProvider.notifier).state =
                query.copyWith(search: q.isEmpty ? null : q, page: 1),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                children: [
                  SegmentedButton<String>(
                    segments: [
                      const ButtonSegment(value: '', label: Text('Semua')),
                      ...StoreOrderStatus.values.map((s) =>
                        ButtonSegment(value: s.value, label: Text(s.label, style: const TextStyle(fontSize: 11)))
                      ),
                    ],
                    selected: {query.status ?? ''},
                    onSelectionChanged: (v) => ref.read(orderQueryProvider.notifier).state =
                      query.copyWith(status: v.first.isEmpty ? null : v.first, page: 1),
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
        Expanded(
          child: data.when(
            loading: () => const Center(child: M3LoadingIndicator()),
            error: (err, _) => ErrorPanel(
                message: err.toString(),
                onRetry: () => ref.invalidate(storeOrdersProvider)),
            data: (page) => AdminDataTable<StoreOrder>(
              items: page.items,
              columns: [
                DataColumn(label: Text(context.l10n.orders)),
                DataColumn(label: Text(context.l10n.customer)),
                DataColumn(label: Text(context.l10n.device)),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text(context.l10n.sla))
              ],
              cells: (o) => [
                DataCell(Text(o.orderNumber)),
                DataCell(Text(o.customerName)),
                DataCell(Text(o.deviceName)),
                DataCell(StatusPill(label: o.status.label)),
                DataCell(Text(
                    o.slaDeadline == null ? '-' : dateText(o.slaDeadline!)))
              ],
              onTap: (o) => context.push('/store/orders/${o.id}'),
            ),
          ),
        ),
      ]),
    );
  }
}
