import 'package:flutter/material.dart';

class CustomerPaymentScreen extends StatelessWidget {
  const CustomerPaymentScreen({super.key, required this.orderNumber});

  final String orderNumber;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(orderNumber, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          const Text('Transfer ke rekening toko / QRIS. Upload bukti nanti disambungkan ke API upload.'),
          const SizedBox(height: 20),
          const TextField(decoration: InputDecoration(labelText: 'Metode pembayaran', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: null, icon: const Icon(Icons.image_outlined), label: const Text('Pilih bukti pembayaran')),
          const SizedBox(height: 20),
          const FilledButton(onPressed: null, child: Text('Kirim bukti dummy belum aktif')),
        ],
      ),
    );
  }
}
