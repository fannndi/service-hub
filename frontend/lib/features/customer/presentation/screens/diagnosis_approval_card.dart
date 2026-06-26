import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../application/customer_providers.dart';
import '../../data/customer_repositories.dart';
import '../../domain/customer_models.dart';
import '../widgets/customer_widgets.dart';

class DiagnosisApprovalCard extends ConsumerStatefulWidget {
  const DiagnosisApprovalCard({super.key, required this.order});
  final CustomerOrder order;
  @override
  ConsumerState<DiagnosisApprovalCard> createState() =>
      _DiagnosisApprovalCardState();
}

class _DiagnosisApprovalCardState extends ConsumerState<DiagnosisApprovalCard> {
  bool _loading = false;
  Future<void> _approve(bool approve) async {
    setState(() => _loading = true);
    try {
      if (approve) {
        await ref.read(orderRepositoryProvider).approveOrder(widget.order.id);
      } else {
        await ref.read(orderRepositoryProvider).rejectOrder(widget.order.id);
      }
      ref.invalidate(orderDetailProvider(widget.order.id));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.l10n.diagnosisResult,
                style: const TextStyle(fontWeight: FontWeight.w900)),
            if (widget.order.diagnosisNote != null)
              Text(widget.order.diagnosisNote!),
            const SizedBox(height: 8),
            ...widget.order.items.map((item) => Text(
                '${item.serviceType}: ${rupiah(item.finalItemPrice ?? item.itemPrice)}')),
            if (widget.order.serviceFee != null)
              Text(context.l10n.serviceFee.replaceFirst('{price}', rupiah(widget.order.serviceFee!))),
            const Divider(),
            Text(context.l10n.total.replaceFirst('{price}', rupiah(widget.order.finalPrice ?? 0)),
                style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: FilledButton(
                      onPressed: _loading ? null : () => _approve(true),
                      child: Text(context.l10n.approve))),
              const SizedBox(width: 8),
              Expanded(
                  child: OutlinedButton(
                      onPressed: _loading ? null : () => _approve(false),
                      child: Text(context.l10n.reject))),
            ]),
          ]),
        ),
      );
}
