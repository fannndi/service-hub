import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../application/customer_providers.dart';
import '../../data/customer_repositories.dart';
import '../../domain/customer_models.dart';
import '../widgets/customer_widgets.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderValue = ref.watch(orderDetailProvider(orderId));
    return CustomerScaffold(
      title: 'Detail Pesanan',
      child: AsyncPage(
        value: orderValue,
        builder: (order) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(orderDetailProvider(orderId)),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              Expanded(
                  child: SelectableText(order.orderNumber,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800))),
              StatusPill(order.status)
            ]),
            const SizedBox(height: 16),
            _InfoCard(title: 'Perangkat', rows: {
              'Brand': order.brand,
              'Model': order.deviceModel,
              'Jenis': order.deviceType,
              'Pengiriman': order.deliveryMethod,
              if (order.deliveryAddress != null)
                'Alamat': order.deliveryAddress!
            }),
            _InfoCard(title: 'Toko', rows: {
              'Nama': order.storeName ?? '-',
              'Alamat': order.storeAddress ?? '-',
              'Telepon': order.storePhone ?? '-'
            }),
            _InfoCard(title: 'Harga', rows: {
              'Estimasi': rupiah(order.totalEstimasi),
              if (order.discountAmount > 0)
                'Diskon': '-${rupiah(order.discountAmount)}',
              if (order.finalPrice != null) 'Final': rupiah(order.finalPrice!)
            }),
            const SectionTitle('Item Order'),
            ...order.items.map((item) => ListTile(
                title: Text(item.serviceType),
                subtitle: Text(item.complaint),
                trailing: Text(rupiah(item.finalItemPrice ?? item.itemPrice)))),
            if (order.slaDeadline != null)
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                          'Batas waktu: ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(order.slaDeadline!)}'))),
            if (order.status == OrderStatus.waitingApproval)
              DiagnosisApprovalCard(order: order),
            const SectionTitle('Tracking', action: null),
            OrderStatusTimeline(entries: order.tracking.take(3).toList()),
            TextButton(
                onPressed: () => context.push('/orders/$orderId/tracking'),
                child: const Text('Lihat Semua Tracking')),
            const SectionTitle('Pembayaran'),
            if (order.payments.isEmpty)
              const Text('Belum ada pembayaran.')
            else
              ...order.payments.map((p) => ListTile(
                  title: Text(rupiah(p.amount)),
                  subtitle: Text('${p.paymentMethod} - ${p.status}'))),
            _OrderActions(order: order),
          ]),
        ),
      ),
    );
  }
}

class _OrderActions extends StatelessWidget {
  const _OrderActions({required this.order});
  final CustomerOrder order;
  @override
  Widget build(BuildContext context) => Column(children: [
        if (order.status == OrderStatus.waitingPayment)
          FilledButton.icon(
              onPressed: () => context.push('/orders/${order.id}/payment'),
              icon: const Icon(Icons.payment),
              label: const Text('Upload Bukti Bayar')),
        if (order.status == OrderStatus.completed && !order.reviewed)
          FilledButton.icon(
              onPressed: () => context.push('/orders/${order.id}/review'),
              icon: const Icon(Icons.star),
              label: const Text('Beri Ulasan')),
        if (order.status == OrderStatus.completed &&
            order.warrantyExpiredAt != null &&
            DateTime.now().isBefore(order.warrantyExpiredAt!))
          OutlinedButton.icon(
              onPressed: () =>
                  context.push('/orders/${order.id}/warranty-claim'),
              icon: const Icon(Icons.shield),
              label: const Text('Klaim Garansi')),
      ]);
}

