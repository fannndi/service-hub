import 'package:flutter/material.dart';

import '../../domain/store_admin_models.dart';

class OrderActionPanel extends StatelessWidget {
  const OrderActionPanel(
      {super.key, required this.order, required this.onAction});
  final StoreOrder order;
  final ValueChanged<String> onAction;
  @override
  Widget build(BuildContext context) {
    if (order.allowedActions.isEmpty) {
      return const Text('Tidak ada aksi valid dari state machine backend.');
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final action in order.allowedActions)
          FilledButton.icon(
              onPressed: () => onAction(action),
              icon: const Icon(Icons.play_arrow),
              label: Text(_actionLabel(action))),
      ],
    );
  }

  String _actionLabel(String value) => switch (value) {
        'receive_device' => 'Terima Device',
        'start_diagnosis' => 'Mulai Diagnosa',
        'submit_diagnosis' => 'Submit Diagnosa',
        'start_repair' => 'Mulai Repair',
        'quality_check' => 'QC Selesai',
        'request_payment' => 'Tagih Bayar',
        _ => value.replaceAll('_', ' '),
      };
}
