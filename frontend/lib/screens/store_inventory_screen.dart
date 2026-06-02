import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import 'store_inventory_form_screen.dart';

class StoreInventoryScreen extends StatelessWidget {
  const StoreInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory Sparepart')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: demoSpareparts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = demoSpareparts[index];
          return Card(
            child: ListTile(
              title: Text(item.name),
              subtitle: Text('Stok ${item.stock} • Reserved ${item.reserved} • Tersedia ${item.available}'),
              trailing: Text(rupiah(item.price)),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StoreInventoryFormScreen())), icon: const Icon(Icons.add), label: const Text('Tambah')),
    );
  }
}

