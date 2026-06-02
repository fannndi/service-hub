import 'package:flutter/material.dart';

class StoreDiagnosisScreen extends StatelessWidget {
  const StoreDiagnosisScreen({super.key, required this.orderNumber});

  final String orderNumber;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input Diagnosis')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(orderNumber, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          const Text('Acuan Phase 03: status replaced wajib pilih sparepart pengganti.'),
          const SizedBox(height: 20),
          const TextField(decoration: InputDecoration(labelText: 'Catatan diagnosis', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(labelText: 'Service fee', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Status item', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'confirmed', child: Text('confirmed')),
              DropdownMenuItem(value: 'replaced', child: Text('replaced')),
              DropdownMenuItem(value: 'cancelled', child: Text('cancelled')),
            ],
            onChanged: null,
          ),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(labelText: 'Replaced sparepart ID', border: OutlineInputBorder())),
          const SizedBox(height: 20),
          const FilledButton(onPressed: null, child: Text('Kirim diagnosis dummy belum aktif')),
        ],
      ),
    );
  }
}
