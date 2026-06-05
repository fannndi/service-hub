import 'package:flutter/material.dart';

class StoreNotificationsScreen extends StatelessWidget {
  const StoreNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Order baru SG-8K2L9A perlu diterima.', 'SLA 11 jam'),
      ('Dispute SG-Z1N8BV harus direspon.', 'SLA 5 jam'),
      ('Stok LCD Samsung A52 rendah.', 'Tersedia 3'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi Toko')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: Text(item.$1),
              subtitle: Text(item.$2),
            ),
          );
        },
      ),
    );
  }
}
