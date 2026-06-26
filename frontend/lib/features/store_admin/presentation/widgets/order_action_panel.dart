import 'package:flutter/material.dart';

import '../../domain/store_admin_models.dart';

class OrderActionPanel extends StatelessWidget {
  const OrderActionPanel({super.key, required this.order, required this.onAction});
  final StoreOrder order;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    if (order.allowedActions.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final action in order.allowedActions)
          FilledButton.icon(
              onPressed: () => onAction(action),
              icon: _actionIcon(action),
              label: Text(_actionLabel(action))),
      ],
    );
  }

  static const _labels = {
    'device_received': 'Terima Perangkat',
    'diagnosing': 'Mulai Diagnosa',
    'waiting_approval': 'Kirim Diagnosa',
    'waiting_sparepart': 'Pesan Sparepart',
    'repairing': 'Mulai Perbaikan',
    'quality_check': 'QC Selesai',
    'waiting_payment': 'Minta Pembayaran',
    'completed': 'Selesai',
    'cancelled': 'Batalkan',
    'disputed': 'Klaim Masuk',
  };

  String _actionLabel(String a) => _labels[a] ?? a.replaceAll('_', ' ');

  Icon _actionIcon(String a) {
    switch (a) {
      case 'device_received': return const Icon(Icons.check_circle_outline);
      case 'diagnosing': return const Icon(Icons.search);
      case 'waiting_approval': return const Icon(Icons.send);
      case 'repairing': return const Icon(Icons.build);
      case 'quality_check': return const Icon(Icons.verified);
      case 'waiting_payment': return const Icon(Icons.payments);
      case 'completed': return const Icon(Icons.done_all);
      case 'cancelled': return const Icon(Icons.cancel);
      default: return const Icon(Icons.play_arrow);
    }
  }
}
