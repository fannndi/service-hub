import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../ui/theme/app_spacing.dart';
import '../../../../ui/widgets/modern_card.dart';
import '../../application/store_admin_providers.dart';
import '../../domain/store_admin_models.dart';
import '../widgets/store_admin_widgets.dart';
import 'package:m3_expressive/m3_expressive.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId));
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.orderDetail), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/store/orders')), actions: [
        IconButton(
          onPressed: () => context.push('/store/orders/$orderId/tracking'),
          icon: const Icon(Icons.timeline),
          tooltip: context.l10n.tracking)
      ]),
      body: order.when(
        loading: () => const Center(child: M3LoadingIndicator()),
        error: (err, _) => ErrorPanel(
            message: err.toString(),
            onRetry: () => ref.invalidate(orderDetailProvider(orderId))),
        data: (o) => ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(children: [
              Expanded(child: Text(o.orderNumber, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: scheme.onPrimaryContainer))),
              StatusPill(label: o.status.label),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),
          ModernCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.l10n.customer, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            _row(context, context.l10n.name, o.customerName),
            _row(context, context.l10n.phone, o.customerPhone),
            _row(context, context.l10n.device, o.deviceName),
            _row(context, context.l10n.address, o.deliveryAddress ?? '-'),
          ])),
          if (o.credentialPanel != null) ...[
            const SizedBox(height: AppSpacing.md),
            CredentialCard(panel: o.credentialPanel!),
          ],
          const SizedBox(height: AppSpacing.md),
          ModernCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.l10n.payment, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            _row(context, context.l10n.estimate, money(o.estimatedTotal)),
            _row(context, context.l10n.finalPrice, money(o.finalPrice)),
            _row(context, context.l10n.payment, o.paymentStatus),
          ])),
          const SizedBox(height: AppSpacing.md),
          Text(context.l10n.orderItem, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
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
          const SizedBox(height: AppSpacing.md),
          OrderActionPanel(
            order: o,
            onAction: (action) => action == 'submit_diagnosis'
              ? context.push('/store/orders/$orderId/diagnosis')
              : ref.read(storeOrdersProvider.notifier).runAction(orderId, action)),
        ]),
      ),
    );
  }

  Widget _row(BuildContext ctx, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(children: [
      SizedBox(width: 100, child: Text(label, style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500))),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
    ]),
  );
}
