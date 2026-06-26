import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../application/store_admin_providers.dart';
import '../../domain/store_admin_models.dart';
import '../widgets/store_admin_widgets.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId));
    return Scaffold(
        appBar: AppBar(title: Text(context.l10n.orderDetail), actions: [
          IconButton(
            onPressed: () => context.push('/store/orders/$orderId/tracking'),
            icon: const Icon(Icons.timeline),
            tooltip: context.l10n.tracking)
      ]),
      body: order.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorPanel(
            message: err.toString(),
            onRetry: () => ref.invalidate(orderDetailProvider(orderId))),
        data: (o) => ListView(padding: const EdgeInsets.all(16), children: [
          Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(o.orderNumber,
                    style: Theme.of(context).textTheme.headlineSmall),
                StatusPill(label: o.status.label)
              ]),
          InfoCard(title: context.l10n.customer, rows: {
            context.l10n.name: o.customerName,
            context.l10n.phone: o.customerPhone,
            context.l10n.device: o.deviceName,
            context.l10n.address: o.deliveryAddress ?? '-'
          }),
          if (o.credentialPanel != null)
            CredentialCard(panel: o.credentialPanel!),
          InfoCard(title: context.l10n.payment, rows: {
            context.l10n.estimate: money(o.estimatedTotal),
            context.l10n.finalPrice: money(o.finalPrice),
            context.l10n.payment: o.paymentStatus
          }),
          Text(context.l10n.orderItem, style: Theme.of(context).textTheme.titleMedium),
          AdminDataTable<OrderItem>(
              items: o.items,
              columns: [
                DataColumn(label: Text(context.l10n.service)),
                DataColumn(label: Text(context.l10n.sparepart)),
                DataColumn(label: Text(context.l10n.price)),
                DataColumn(label: Text('Status'))
              ],
              cells: (i) => [
                    DataCell(Text(i.serviceType)),
                    DataCell(Text(i.sparepartName)),
                    DataCell(Text(money(i.price))),
                    DataCell(Text(i.status))
                  ]),
          const SizedBox(height: 16),
          OrderActionPanel(
              order: o,
              onAction: (action) => action == 'submit_diagnosis'
                  ? context.push('/store/orders/$orderId/diagnosis')
                  : ref
                      .read(storeOrdersProvider.notifier)
                      .runAction(orderId, action)),
        ]),
      ),
    );
  }
}
