import 'package:flutter/material.dart';

class StoreInventoryFormScreen extends StatelessWidget {
  const StoreInventoryFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Sparepart')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          Text('Sparepart', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          SizedBox(height: 12),
          Text('Acuan Phase 03: stok tersedia = qty - qtyReserved.'),
          SizedBox(height: 20),
          TextField(decoration: InputDecoration(labelText: 'Nama sparepart', border: OutlineInputBorder())),
          SizedBox(height: 12),
          TextField(decoration: InputDecoration(labelText: 'Harga', border: OutlineInputBorder())),
          SizedBox(height: 12),
          TextField(decoration: InputDecoration(labelText: 'Qty stok fisik', border: OutlineInputBorder())),
          SizedBox(height: 12),
          TextField(decoration: InputDecoration(labelText: 'Low stock threshold', border: OutlineInputBorder())),
          SizedBox(height: 20),
          FilledButton(onPressed: null, child: Text('Simpan dummy belum aktif')),
        ],
      ),
    );
  }
}
