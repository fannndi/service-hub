import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      appBar: AppBar(title: const Text('Detail Order'), actions: [
        IconButton(
            onPressed: () => context.go('/store/orders/$orderId/tracking'),
            icon: const Icon(Icons.timeline),
            tooltip: 'Tracking')
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
          InfoCard(title: 'Pelanggan', rows: {
            'Nama': o.customerName,
            'HP': o.customerPhone,
            'Device': o.deviceName,
            'Alamat': o.deliveryAddress ?? '-'
          }),
          if (o.credentialPanel != null)
            CredentialCard(panel: o.credentialPanel!),
          InfoCard(title: 'Harga', rows: {
            'Estimasi': money(o.estimatedTotal),
            'Final': money(o.finalPrice),
            'Payment': o.paymentStatus
          }),
          Text('Item Order', style: Theme.of(context).textTheme.titleMedium),
          AdminDataTable<OrderItem>(
              items: o.items,
              columns: const [
                DataColumn(label: Text('Service')),
                DataColumn(label: Text('Sparepart')),
                DataColumn(label: Text('Harga')),
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
                  ? context.go('/store/orders/$orderId/diagnosis')
                  : ref
                      .read(storeOrdersProvider.notifier)
                      .runAction(orderId, action)),
        ]),
      ),
    );
  }
}
