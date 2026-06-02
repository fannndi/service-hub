import 'package:flutter/material.dart';

import 'store_dispute_detail_screen.dart';

class StoreDisputesScreen extends StatelessWidget {
  const StoreDisputesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dispute Garansi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.gavel_outlined),
              title: const Text('SG-Z1N8BV • Tidak bisa charge lagi'),
              subtitle: const Text('Status: open • Sisa respon: 5 jam'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StoreDisputeDetailScreen())),
            ),
          ),
        ],
      ),
    );
  }
}
