import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/customer_providers.dart';
import '../../data/customer_repositories.dart';
import '../../domain/customer_models.dart';
import '../widgets/customer_widgets.dart';

class PaymentUploadScreen extends ConsumerStatefulWidget {
  const PaymentUploadScreen({super.key, required this.orderId});
  final String orderId;
  @override
  ConsumerState<PaymentUploadScreen> createState() =>
      _PaymentUploadScreenState();
}

class _PaymentUploadScreenState extends ConsumerState<PaymentUploadScreen> {
  final _amount = TextEditingController();
  String _method = 'transfer_bank';
  String _type = 'final_payment';
  XFile? _file;
  double _progress = 0;
  bool _loading = false;

  Future<void> _submit(CustomerOrder order) async {
    final amount =
        double.tryParse(_amount.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
    if (amount <= 0) return;
    if (_method == 'transfer_bank' && _file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bukti transfer wajib diunggah.')));
      return;
    }
    setState(() => _loading = true);
    try {
      final proofUrl = _file == null
          ? null
          : await ref.read(uploadRepositoryProvider).uploadFile(
              _file!, 'payments', (p) => setState(() => _progress = p));
      await ref.read(paymentRepositoryProvider).createPayment(
          order.id,
          amount: amount.toInt(),
          paymentMethod: _method,
          paymentType: _type,
          proofUrl: proofUrl);
      ref.invalidate(orderDetailProvider(order.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Pembayaran dikirim, menunggu konfirmasi toko.')));
        context.pop();
      }
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
  Widget build(BuildContext context) {
    final orderValue = ref.watch(orderDetailProvider(widget.orderId));
    return CustomerScaffold(
      title: 'Pembayaran',
      child: AsyncPage(
        value: orderValue,
        builder: (order) {
          final confirmed = order.payments
              .where((p) => p.status == 'confirmed')
              .fold<double>(0, (sum, p) => sum + p.amount);
          final due = (order.finalPrice ?? order.totalEstimasi) - confirmed;
          if (_amount.text.isEmpty) {
            _amount.text = due.clamp(0, double.infinity).toStringAsFixed(0);
          }
          return ListView(padding: const EdgeInsets.all(16), children: [
            _InfoCard(title: 'Tagihan', rows: {
              'Order': order.orderNumber,
              'Final': rupiah(order.finalPrice ?? order.totalEstimasi),
              'Sudah Bayar': rupiah(confirmed),
              'Sisa': rupiah(due)
            }),
            DropdownButtonFormField(
                initialValue: _method,
                decoration:
                    const InputDecoration(labelText: 'Metode Pembayaran'),
                items: const [
                  DropdownMenuItem(
                      value: 'transfer_bank', child: Text('Transfer Bank')),
                  DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                  DropdownMenuItem(value: 'cash', child: Text('Tunai')),
                  DropdownMenuItem(value: 'ewallet', child: Text('E-Wallet')),
                ],
                onChanged: (v) => setState(() => _method = v!)),
            DropdownButtonFormField(
                initialValue: _type,
                decoration:
                    const InputDecoration(labelText: 'Jenis Pembayaran'),
                items: const [
                  DropdownMenuItem(value: 'deposit', child: Text('Uang Muka')),
                  DropdownMenuItem(
                      value: 'final_payment', child: Text('Pelunasan Final')),
                ],
                onChanged: (v) => setState(() => _type = v!)),
            TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Nominal')),
            const SizedBox(height: 12),
            OutlinedButton.icon(
                onPressed: () async => setState(() => _file = null),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus Foto')),
            OutlinedButton.icon(
                onPressed: () async {
                  final picked = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 72,
                      maxWidth: 1600);
                  if (picked != null) setState(() => _file = picked);
                },
                icon: const Icon(Icons.image),
                label: Text(_file?.name ?? 'Ambil dari Galeri')),
            if (_file != null) Text('Dipilih: ${_file!.name}'),
            if (_progress > 0 && _progress < 1)
              LinearProgressIndicator(value: _progress),
            const SizedBox(height: 20),
            FilledButton(
                onPressed: _loading ? null : () => _submit(order),
                child: Text(_loading ? 'Mengirim...' : 'Kirim Pembayaran')),
          ]);
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows});
  final String title;
  final Map<String, String> rows;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            ...rows.entries.map((row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 94, child: Text(row.key)),
                      Expanded(
                          child: Text(row.value,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)))
                    ]))),
          ]),
        ),
      );
}
