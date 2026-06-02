import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/demo_auth_controller.dart';
import 'customer_create_order_screen.dart';
import 'customer_coupons_screen.dart';
import 'customer_notifications_screen.dart';
import 'customer_orders_screen.dart';
import 'customer_profile_screen.dart';
import 'customer_review_screen.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(demoAuthProvider).account!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer'),
        actions: [IconButton(onPressed: () => ref.read(demoAuthProvider.notifier).logout(), icon: const Icon(Icons.logout))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Halo, ${account.name}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Shell Customer App Phase 02. Data masih dummy lokal.'),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => _open(context, const CustomerNotificationsScreen()), icon: const Icon(Icons.notifications_outlined), label: const Text('Notifikasi'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(onPressed: () => _open(context, const CustomerCouponsScreen()), icon: const Icon(Icons.confirmation_number_outlined), label: const Text('Kupon'))),
          ]),
          const SizedBox(height: 16),
          _MenuTile(icon: Icons.build_circle_outlined, title: 'Buat Service', subtitle: 'Form order gadget dummy', onTap: () => _open(context, const CustomerCreateOrderScreen())),
          _MenuTile(icon: Icons.receipt_long_outlined, title: 'Order Saya', subtitle: 'List dan detail order dummy', onTap: () => _open(context, const CustomerOrdersScreen())),
          _MenuTile(icon: Icons.payments_outlined, title: 'Pembayaran', subtitle: 'Aksi pembayaran ada di detail order', onTap: () => _open(context, const CustomerOrdersScreen())),
          _MenuTile(icon: Icons.reviews_outlined, title: 'Review & Kupon', subtitle: 'Form review dummy', onTap: () => _open(context, const CustomerReviewScreen())),
          _MenuTile(icon: Icons.person_outline, title: 'Profil', subtitle: 'Profil dan kupon dummy', onTap: () => _open(context, const CustomerProfileScreen())),
          _MenuTile(icon: Icons.report_problem_outlined, title: 'Klaim Garansi', subtitle: 'Aksi klaim ada di detail order', onTap: () => _open(context, const CustomerOrdersScreen())),
        ],
      ),
    );
  }

  static void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(leading: Icon(icon), title: Text(title), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right), onTap: onTap),
    );
  }
}
