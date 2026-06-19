import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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
          const SnackBar(content: Text('Deskripsi minimal 20 karakter.')));
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
          orderId: widget.orderId,
          disputeType: _type,
          description: _description.text,
          evidenceUrls: urls);
      ref.invalidate(orderDetailProvider(widget.orderId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Klaim diterima. Admin toko akan merespons dalam 24 jam.')));
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
      title: 'Klaim Garansi',
      child: AsyncPage(
          value: order,
          builder: (data) {
            if (data.warrantyExpiredAt == null ||
                DateTime.now().isAfter(data.warrantyExpiredAt!)) {
              return EmptyMessage(
                  'Garansi sudah berakhir pada ${shortDate(data.warrantyExpiredAt)}.');
            }
            return ListView(padding: const EdgeInsets.all(16), children: [
              Text('Garansi aktif s/d ${shortDate(data.warrantyExpiredAt)}'),
              DropdownButtonFormField(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Jenis Masalah'),
                  items: const [
                    DropdownMenuItem(
                        value: 'warranty_claim', child: Text('Klaim Garansi')),
                    DropdownMenuItem(
                        value: 'service_quality',
                        child: Text('Kualitas Servis')),
                    DropdownMenuItem(
                        value: 'wrong_diagnosis',
                        child: Text('Diagnosa Salah')),
                    DropdownMenuItem(value: 'other', child: Text('Lainnya')),
                  ],
                  onChanged: (v) => setState(() => _type = v!)),
              TextField(
                  controller: _description,
                  minLines: 4,
                  maxLines: 7,
                  decoration: const InputDecoration(
                      labelText: 'Deskripsi Masalah',
                      border: OutlineInputBorder())),
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
                  label: const Text('Tambah Foto')),
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
                  child: Text(_loading ? 'Mengirim...' : 'Kirim Klaim')),
            ]);
          }),
    );
  }
}
