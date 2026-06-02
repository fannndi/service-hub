import 'package:flutter/material.dart';

class CustomerCreateOrderScreen extends StatelessWidget {
  const CustomerCreateOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Service')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          Text('Form Service Dummy', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          SizedBox(height: 16),
          TextField(decoration: InputDecoration(labelText: 'Nama', border: OutlineInputBorder())),
          SizedBox(height: 12),
          TextField(decoration: InputDecoration(labelText: 'Nomor HP', border: OutlineInputBorder())),
          SizedBox(height: 12),
          TextField(decoration: InputDecoration(labelText: 'Brand / Model Gadget', border: OutlineInputBorder())),
          SizedBox(height: 12),
          TextField(minLines: 3, maxLines: 5, decoration: InputDecoration(labelText: 'Keluhan', border: OutlineInputBorder())),
          SizedBox(height: 20),
          FilledButton(onPressed: null, child: Text('Submit dummy belum aktif')),
        ],
      ),
    );
  }
}
