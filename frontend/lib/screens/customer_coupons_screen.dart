import 'package:flutter/material.dart';

class CustomerCouponsScreen extends StatelessWidget {
  const CustomerCouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kupon Saya')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.confirmation_number_outlined),
              title: Text('SGREVIEW10'),
              subtitle: Text('Reward review • Diskon 10% • Ownership wajib dicek backend'),
              trailing: Text('Aktif'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.confirmation_number_outlined),
              title: Text('WELCOME25'),
              subtitle: Text('Dummy first-order coupon'),
              trailing: Text('Aktif'),
            ),
          ),
        ],
      ),
    );
  }
}
