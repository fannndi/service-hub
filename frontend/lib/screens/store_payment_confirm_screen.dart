import 'package:flutter/material.dart';

class StorePaymentConfirmScreen extends StatelessWidget {
  const StorePaymentConfirmScreen({super.key, required this.orderNumber});

  final String orderNumber;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Pembayaran')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(orderNumber, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          const Text('Acuan Phase 03: confirm payment akan set warrantyDays dari config toko.'),
          const SizedBox(height: 20),
          Container(
            height: 160,
            alignment: Alignment.center,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
            child: const Text('Preview bukti bayar'),
          ),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(labelText: 'Catatan admin', border: OutlineInputBorder())),
          const SizedBox(height: 20),
          const FilledButton(onPressed: null, child: Text('Konfirmasi dummy belum aktif')),
        ],
      ),
    );
  }
}
