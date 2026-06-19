import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/store_admin_providers.dart';
import '../../domain/store_admin_models.dart';
import '../widgets/store_admin_widgets.dart';

class DisputesScreen extends ConsumerWidget {
  const DisputesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      PagedTableScreen<DisputeCase>(
        title: 'Dispute Queue',
        selectedIndex: 1,
        value: ref.watch(disputesProvider),
        columns: const [
          DataColumn(label: Text('Order')),
          DataColumn(label: Text('Pelanggan')),
          DataColumn(label: Text('Tipe')),
          DataColumn(label: Text('Status'))
        ],
        cells: (d) => [
          DataCell(Text(d.orderNumber)),
          DataCell(Text(d.customerName)),
          DataCell(Text(d.type)),
          DataCell(Text(d.status.label))
        ],
        onTap: (d) => context.go('/store/disputes/${d.id}', extra: d),
      );
}

class DisputeDetailScreen extends ConsumerStatefulWidget {
  const DisputeDetailScreen({super.key, required this.dispute});
  final DisputeCase dispute;
  @override
  ConsumerState<DisputeDetailScreen> createState() =>
      _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends ConsumerState<DisputeDetailScreen> {
  final reason = TextEditingController();
  bool _loading = false;

  Future<void> _resolve(bool accept) async {
    if (reason.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catatan resolusi wajib diisi.')));
      return;
    }
    setState(() => _loading = true);
    try {
      await ref
          .read(disputesProvider.notifier)
          .resolve(widget.dispute.id, accept, reason.text);
      if (mounted) context.go('/store/disputes');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.dispute.orderNumber)),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Text(widget.dispute.description),
          const SizedBox(height: 12),
          TextField(
              controller: reason,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                  labelText: 'Catatan resolusi', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          Wrap(spacing: 8, children: [
            FilledButton.icon(
                onPressed: _loading ? null : () => _resolve(true),
                icon: const Icon(Icons.check),
                label: const Text('Terima Klaim')),
            OutlinedButton.icon(
                onPressed: _loading ? null : () => _resolve(false),
                icon: const Icon(Icons.close),
                label: const Text('Tolak Klaim')),
          ]),
        ]),
      );
}
