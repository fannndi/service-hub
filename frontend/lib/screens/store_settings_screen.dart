import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/demo_auth_controller.dart';

class StoreSettingsScreen extends ConsumerWidget {
  const StoreSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(demoAuthProvider).account!;
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Toko')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(account.storeName ?? 'Toko', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Store ID: ${account.storeId}'),
          const SizedBox(height: 24),
          const TextField(decoration: InputDecoration(labelText: 'Warranty days', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(labelText: 'Threshold stok rendah', border: OutlineInputBorder())),
          const SizedBox(height: 20),
          const FilledButton(onPressed: null, child: Text('Simpan dummy belum aktif')),
        ],
      ),
    );
  }
}
