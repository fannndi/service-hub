import 'package:flutter/material.dart';

class CustomerNotificationsScreen extends StatelessWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Order SG-8K2L9A menunggu persetujuan estimasi.', '5 menit lalu'),
      ('Bukti pembayaran SG-Z1N8BV sedang diverifikasi toko.', '1 jam lalu'),
      ('Kupon SGREVIEW10 siap digunakan.', 'Kemarin'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
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
