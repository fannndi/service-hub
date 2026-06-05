import 'package:flutter/material.dart';

class StoreDisputeDetailScreen extends StatelessWidget {
  const StoreDisputeDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Dispute')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          Text('SG-Z1N8BV', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          SizedBox(height: 8),
          Text('Tidak bisa charge lagi setelah service.'),
          SizedBox(height: 20),
          Text('Acuan: terima dispute membuat warranty order baru. Tolak wajib alasan min 10 karakter.'),
          SizedBox(height: 20),
          TextField(minLines: 3, maxLines: 5, decoration: InputDecoration(labelText: 'Alasan / catatan toko', border: OutlineInputBorder())),
          SizedBox(height: 12),
          FilledButton(onPressed: null, child: Text('Terima dummy belum aktif')),
          SizedBox(height: 8),
          OutlinedButton(onPressed: null, child: Text('Tolak dummy belum aktif')),
        ],
      ),
    );
  }
}
