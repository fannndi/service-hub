import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../application/customer_providers.dart';
import '../widgets/customer_widgets.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});
  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  @override
  Widget build(BuildContext context) => CustomerScaffold(
        title: context.l10n.myOrders,
        child: DefaultTabController(
          length: 3,
          child: Column(children: [
            TabBar(tabs: [
              Tab(text: context.l10n.active),
              Tab(text: context.l10n.completed),
              Tab(text: context.l10n.cancelled)
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
              ? EmptyMessage(context.l10n.noOrders)
              : ListView(
                  children: items
                      .map((order) => OrderCard(
                          order: order,
                          onTap: () => context.push('/orders/${order.id}')))
                      .toList())),
    );
  }
}
