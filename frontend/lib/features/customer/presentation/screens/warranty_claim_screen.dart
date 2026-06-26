import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../ui/theme/app_spacing.dart';
import '../../application/customer_providers.dart';
import '../../data/customer_repositories.dart';
import '../widgets/customer_widgets.dart';

class WarrantyClaimScreen extends ConsumerStatefulWidget {
  const WarrantyClaimScreen({super.key, required this.orderId});
  final String orderId;
  @override
  ConsumerState<WarrantyClaimScreen> createState() =>
      _WarrantyClaimScreenState();
}

class _WarrantyClaimScreenState extends ConsumerState<WarrantyClaimScreen> {
  final _description = TextEditingController();
  String _type = 'warranty_claim';
  final _files = <XFile>[];
  bool _loading = false;

  Future<void> _submit() async {
    if (_description.text.length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.descriptionMinLength)));
      return;
    }
    setState(() => _loading = true);
    try {
      final urls = <String>[];
      for (final file in _files) {
        urls.add(await ref
            .read(uploadRepositoryProvider)
            .uploadFile(file, 'evidence', null));
      }
      await ref.read(disputeRepositoryProvider).createDispute(
          widget.orderId,
          disputeType: _type,
          description: _description.text,
          evidenceUrls: urls);
      ref.invalidate(orderDetailProvider(widget.orderId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.l10n.claimAccepted)));
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
    final order = ref.watch(orderDetailProvider(widget.orderId));
    return CustomerScaffold(
      title: context.l10n.claimWarrantyTitle,
      child: AsyncPage(
          value: order,
          builder: (data) {
            if (data.warrantyExpiredAt == null ||
                DateTime.now().isAfter(data.warrantyExpiredAt!)) {
              return EmptyMessage(
                  context.l10n.warrantyExpired.replaceFirst('{date}', shortDate(data.warrantyExpiredAt)));
            }
            return ListView(padding: const EdgeInsets.all(16), children: [
              Text(context.l10n.warrantyActiveUntil.replaceFirst('{date}', shortDate(data.warrantyExpiredAt))),
              DropdownButtonFormField(
                  initialValue: _type,
                  decoration: InputDecoration(labelText: context.l10n.issueType),
                  items: [
                    DropdownMenuItem(
                        value: 'warranty_claim', child: Text(context.l10n.warrantyClaim)),
                    DropdownMenuItem(
                        value: 'service_quality',
                        child: Text(context.l10n.serviceQuality)),
                    DropdownMenuItem(
                        value: 'wrong_diagnosis',
                        child: Text(context.l10n.wrongDiagnosis)),
                    DropdownMenuItem(value: 'other', child: Text(context.l10n.other)),
                  ],
                  onChanged: (v) => setState(() => _type = v!)),
              TextField(
                  controller: _description,
                  minLines: 4,
                  maxLines: 7,
                  decoration: InputDecoration(
                      labelText: context.l10n.issueDescription)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                  onPressed: _files.length >= 5
                      ? null
                      : () async {
                          final picked = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 72,
                              maxWidth: 1600);
                          if (picked != null) {
                            setState(() => _files.add(picked));
                          }
                        },
                  icon: const Icon(Icons.add_a_photo),
                  label: Text(context.l10n.addPhoto)),
              Wrap(
                  spacing: 8,
                  children: _files
                      .map((file) => InputChip(
                          label: Text(file.name),
                          onDeleted: () => setState(() => _files.remove(file))))
                      .toList()),
              const SizedBox(height: 20),
              FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: Text(_loading ? context.l10n.sending : context.l10n.submitClaim)),
            ]);
          }),
    );
  }
}
