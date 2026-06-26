import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../ui/theme/app_spacing.dart';
import '../../../../ui/widgets/modern_card.dart';
import '../../application/customer_providers.dart';
import '../../domain/customer_models.dart';
import '../widgets/customer_widgets.dart';
import 'diagnosis_approval_card.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderValue = ref.watch(orderDetailProvider(orderId));
    return CustomerScaffold(
      title: context.l10n.orderDetail,
      child: AsyncPage(
        value: orderValue,
        builder: (order) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(orderDetailProvider(orderId)),
          child: ListView(padding: EdgeInsets.all(AppSpacing.md), children: [
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
            _InfoCard(title: context.l10n.device, rows: {
              context.l10n.brand: order.brand,
              context.l10n.model: order.deviceModel,
              context.l10n.type: order.deviceType,
              context.l10n.delivery: order.deliveryMethod,
              if (order.deliveryAddress != null)
                context.l10n.address: order.deliveryAddress!
            }),
            _InfoCard(title: context.l10n.store, rows: {
              context.l10n.name: order.storeName ?? '-',
              context.l10n.address: order.storeAddress ?? '-',
              context.l10n.phone: order.storePhone ?? '-'
            }),
            _InfoCard(title: context.l10n.price, rows: {
              context.l10n.estimate: rupiah(order.totalEstimasi),
              if (order.discountAmount > 0)
                context.l10n.discount: '-${rupiah(order.discountAmount)}',
              if (order.finalPrice != null) context.l10n.finalPrice: rupiah(order.finalPrice!)
            }),
            SectionTitle(context.l10n.orderItem),
            ...order.items.map((item) => ListTile(
                title: Text(item.serviceType),
                subtitle: Text(item.complaint),
                trailing: Text(rupiah(item.finalItemPrice ?? item.itemPrice)))),
            if (order.slaDeadline != null)
              ModernCard(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Text(context.l10n.deadline.replaceFirst('{date}',
                      DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(order.slaDeadline!)))),
            if (order.status == OrderStatus.waitingApproval)
              DiagnosisApprovalCard(order: order),
            SectionTitle(context.l10n.tracking, action: null),
            OrderStatusTimeline(entries: order.tracking.take(3).toList()),
            TextButton(
                onPressed: () => context.push('/orders/$orderId/tracking'),
                child: Text(context.l10n.viewAllTracking)),
            SectionTitle(context.l10n.payment),
            if (order.payments.isEmpty)
              Text(context.l10n.noPayment)
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
              label: Text(context.l10n.uploadPaymentProof)),
        if (order.status == OrderStatus.completed && !order.reviewed)
          FilledButton.icon(
              onPressed: () => context.push('/orders/${order.id}/review'),
              icon: const Icon(Icons.star),
              label: Text(context.l10n.giveReview)),
        if (order.status == OrderStatus.completed &&
            order.warrantyExpiredAt != null &&
            DateTime.now().isBefore(order.warrantyExpiredAt!))
          OutlinedButton.icon(
              onPressed: () =>
                  context.push('/orders/${order.id}/warranty-claim'),
              icon: const Icon(Icons.shield),
              label: Text(context.l10n.claimWarranty)),
      ]);
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows});
  final String title;
  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ModernCard(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          SizedBox(height: AppSpacing.xs),
          ...rows.entries.map((row) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 94, child: Text(row.key)),
                Expanded(child: Text(row.value, style: const TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
