import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../application/store_admin_providers.dart';
import '../../domain/store_admin_models.dart';
import '../widgets/store_admin_widgets.dart';

class OrderListScreen extends ConsumerWidget {
  const OrderListScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(storeOrdersProvider);
    return StoreAdminScaffold(
      title: context.l10n.orderManagement,
      selectedIndex: 1,
      body: Column(children: [
        QueryToolbar(
          hint: context.l10n.searchOrdersHint,
          onSearch: (q) => ref.read(orderQueryProvider.notifier).state =
              ref.read(orderQueryProvider).copyWith(search: q, page: 1),
          filters: [
            for (final s in [null, ...StoreOrderStatus.values])
              FilterChip(
                  label: Text(s?.label ?? context.l10n.all),
                  selected: ref.watch(orderQueryProvider).status == s?.value,
                  onSelected: (_) =>
                      ref.read(orderQueryProvider.notifier).state = ref
                          .read(orderQueryProvider)
                          .copyWith(status: s?.value, page: 1))
          ],
        ),
        Expanded(
          child: data.when(
            loading: () => const Center(child: CircularProgressIndicator()),
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
