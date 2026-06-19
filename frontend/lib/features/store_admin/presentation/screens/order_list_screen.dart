import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/store_admin_providers.dart';
import '../../domain/store_admin_models.dart';
import '../widgets/store_admin_widgets.dart';

class OrderListScreen extends ConsumerWidget {
  const OrderListScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(storeOrdersProvider);
    return StoreAdminScaffold(
      title: 'Order Management',
      selectedIndex: 1,
      body: Column(children: [
        QueryToolbar(
          hint: 'Cari order, pelanggan, device',
          onSearch: (q) => ref.read(orderQueryProvider.notifier).state = ref.read(orderQueryProvider).copyWith(search: q, page: 1),
          filters: [for (final s in [null, ...StoreOrderStatus.values]) FilterChip(label: Text(s?.label ?? 'Semua'), selected: ref.watch(orderQueryProvider).status == s?.value, onSelected: (_) => ref.read(orderQueryProvider.notifier).state = ref.read(orderQueryProvider).copyWith(status: s?.value, page: 1))],
        ),
        Expanded(
          child: data.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => ErrorPanel(message: err.toString(), onRetry: () => ref.invalidate(storeOrdersProvider)),
            data: (page) => AdminDataTable<StoreOrder>(
              items: page.items,
              columns: const [DataColumn(label: Text('Order')), DataColumn(label: Text('Pelanggan')), DataColumn(label: Text('Device')), DataColumn(label: Text('Status')), DataColumn(label: Text('SLA'))],
              cells: (o) => [DataCell(Text(o.orderNumber)), DataCell(Text(o.customerName)), DataCell(Text(o.deviceName)), DataCell(StatusPill(label: o.status.label)), DataCell(Text(o.slaDeadline == null ? '-' : dateText(o.slaDeadline!)))],
              onTap: (o) => context.go('/store/orders/${o.id}'),
            ),
          ),
        ),
      ]),
    );
  }
}
