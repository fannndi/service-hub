import 'package:flutter/material.dart';

class CustomerDisputeScreen extends StatelessWidget {
  const CustomerDisputeScreen({super.key, required this.orderNumber});

  final String orderNumber;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Klaim Garansi')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(orderNumber,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          const Text(
              'Acuan Phase 02: backend wajib cek warrantyExpiredAt dan dispute aktif.'),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
                labelText: 'Jenis klaim', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(
                  value: 'warranty_claim', child: Text('Warranty claim')),
              DropdownMenuItem(
                  value: 'service_quality', child: Text('Service quality')),
              DropdownMenuItem(
                  value: 'wrong_diagnosis', child: Text('Wrong diagnosis')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: null,
          ),
          const SizedBox(height: 12),
          const TextField(
              minLines: 4,
              maxLines: 6,
              decoration: InputDecoration(
                  labelText: 'Deskripsi masalah',
                  border: OutlineInputBorder())),
          const SizedBox(height: 12),
          OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.image_outlined),
              label: const Text('Tambah foto bukti')),
          const SizedBox(height: 20),
          const FilledButton(
              onPressed: null, child: Text('Kirim klaim dummy belum aktif')),
        ],
      ),
    );
  }
}
