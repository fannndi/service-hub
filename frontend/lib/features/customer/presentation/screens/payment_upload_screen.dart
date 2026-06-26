import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/supabase_service.dart';
import '../../../../ui/theme/app_spacing.dart';
import '../../../../ui/widgets/modern_card.dart';
import '../../application/customer_providers.dart';
import '../../data/customer_repositories.dart';
import '../../domain/customer_models.dart';
import '../widgets/customer_widgets.dart';
import 'package:m3_expressive/m3_expressive.dart';

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
          SnackBar(content: Text(context.l10n.transferProofRequired)));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.l10n.paymentSubmitted)));
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

  Future<void> _payWithMidtrans(CustomerOrder order) async {
    setState(() => _loading = true);
    try {
      final userId = SupabaseService.instance.user?.id ?? '';
      final result = await SupabaseService.instance.invoke('midtrans', body: {
        'orderId': order.id,
        'userId': userId,
      });
      if (result is Map && result['redirect_url'] != null) {
        final uri = Uri.parse(result['redirect_url'] as String);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        throw Exception('Gagal mendapatkan tautan pembayaran');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l10n.completeInBrowser),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Midtrans: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderValue = ref.watch(orderDetailProvider(widget.orderId));
    return CustomerScaffold(
      title: context.l10n.payment,
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
          return ListView(padding: EdgeInsets.all(AppSpacing.md), children: [
            _InfoCard(title: context.l10n.invoice, rows: {
              'Order': order.orderNumber,
              'Final': rupiah(order.finalPrice ?? order.totalEstimasi),
              context.l10n.paid: rupiah(confirmed),
              context.l10n.remaining: rupiah(due)
            }),
            DropdownButtonFormField(
                initialValue: _method,
                decoration:
                    InputDecoration(labelText: context.l10n.paymentMethod),
                items: [
                  DropdownMenuItem(
                      value: 'transfer_bank', child: Text(context.l10n.bankTransfer)),
                  DropdownMenuItem(value: 'qris', child: Text(context.l10n.qris)),
                  DropdownMenuItem(value: 'cash', child: Text(context.l10n.cash)),
                  DropdownMenuItem(value: 'ewallet', child: Text(context.l10n.ewallet)),
                  DropdownMenuItem(
                      value: 'midtrans',
                      child: Text(context.l10n.midtransCard)),
                ],
                onChanged: (v) => setState(() => _method = v!)),
            if (_method != 'midtrans') ...[
              DropdownButtonFormField(
                  initialValue: _type,
                  decoration:
                      InputDecoration(labelText: context.l10n.paymentType),
                  items: [
                    DropdownMenuItem(
                        value: 'deposit', child: Text(context.l10n.deposit)),
                    DropdownMenuItem(
                        value: 'final_payment',
                        child: Text(context.l10n.finalPayment)),
                  ],
                  onChanged: (v) => setState(() => _type = v!)),
              TextField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(labelText: context.l10n.amount)),
              SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                  onPressed: () async => setState(() => _file = null),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(context.l10n.removePhoto)),
              OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 72,
                        maxWidth: 1600);
                    if (picked != null) setState(() => _file = picked);
                  },
                  icon: const Icon(Icons.image),
                  label: Text(_file?.name ?? context.l10n.pickFromGallery)),
              if (_file != null) Text(context.l10n.selectedFile.replaceFirst('{file}', _file!.name)),
              if (_progress > 0 && _progress < 1)
                LinearProgressIndicator(value: _progress),
              SizedBox(height: 20),
              FilledButton(
                  onPressed: _loading ? null : () => _submit(order),
                  child: Text(_loading ? context.l10n.sending : context.l10n.submitPayment)),
            ] else ...[
              const SizedBox(height: 20),
              ModernCard(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Column(children: [
                  const Icon(Icons.payment, size: 48),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    context.l10n.payWithMidtrans,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.midtransMethods,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _loading ? null : () => _payWithMidtrans(order),
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: M3LoadingIndicator(size: 20))
                        : const Icon(Icons.open_in_browser),
                    label: Text(_loading ? context.l10n.processing : context.l10n.payViaMidtrans),
                  ),
                ]),
              ),
            ],
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
