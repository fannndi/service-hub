import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/customer_providers.dart';
import '../../data/customer_repositories.dart';
import '../../domain/customer_models.dart';
import '../../domain/user_session.dart';
import '../../../../shared_widgets/error_state.dart';
import '../../../../shared_widgets/status_badge.dart';
import '../../../../shared_widgets/empty_state.dart';
import '../../../../shared_widgets/formatters.dart';
import '../widgets/customer_widgets.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});
  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}
class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  @override
  Widget build(BuildContext context) => const CustomerScaffold(
        title: 'Pesanan Saya',
        child: DefaultTabController(
          length: 3,
          child: Column(children: [
            TabBar(tabs: [
              Tab(text: 'Aktif'),
              Tab(text: 'Selesai'),
              Tab(text: 'Dibatalkan')
            ]),
            Expanded(
                child: TabBarView(children: [
              _OrderTab('active'),
              _OrderTab('completed'),
              _OrderTab('cancelled')
            ])),
          ]),
        ),
      );
}
class _OrderTab extends ConsumerWidget {
  const _OrderTab(this.group);
  final String group;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(customerOrdersProvider(group));
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(customerOrdersProvider(group)),
      child: AsyncPage(
          value: orders,
          builder: (items) => items.isEmpty
              ? const EmptyMessage('Tidak ada pesanan.')
              : ListView(
                  children: items
                      .map((order) => OrderCard(
                          order: order,
                          onTap: () => context.push('/orders/${order.id}')))
                      .toList())),
    );
  }
}
