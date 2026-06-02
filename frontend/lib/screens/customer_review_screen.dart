import 'package:flutter/material.dart';

class CustomerReviewScreen extends StatelessWidget {
  const CustomerReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review & Kupon')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          Text('Beri Review', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          SizedBox(height: 12),
          Text('Rating dummy untuk acuan Phase 02. Kupon reward dibuat oleh backend nanti.'),
          SizedBox(height: 20),
          Text('★★★★★', style: TextStyle(fontSize: 36)),
          SizedBox(height: 12),
          TextField(minLines: 4, maxLines: 6, decoration: InputDecoration(labelText: 'Komentar', border: OutlineInputBorder())),
          SizedBox(height: 20),
          FilledButton(onPressed: null, child: Text('Submit review dummy belum aktif')),
        ],
      ),
    );
  }
}
