import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/demo_auth_controller.dart';
import 'store_disputes_screen.dart';
import 'store_inventory_screen.dart';
import 'store_notifications_screen.dart';
import 'store_orders_screen.dart';
import 'store_settings_screen.dart';

class StoreAdminHomeScreen extends ConsumerWidget {
  const StoreAdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(demoAuthProvider).account!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Toko'),
        actions: [IconButton(onPressed: () => ref.read(demoAuthProvider.notifier).logout(), icon: const Icon(Icons.logout))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(account.storeName ?? 'Toko', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Login sebagai ${account.name}'),
          const SizedBox(height: 24),
          OutlinedButton.icon(onPressed: () => _open(context, const StoreNotificationsScreen()), icon: const Icon(Icons.notifications_outlined), label: const Text('Notifikasi Toko')),
          const SizedBox(height: 16),
          const _MetricRow(),
          const SizedBox(height: 16),
          _MenuTile(icon: Icons.assignment_outlined, title: 'Order Masuk', subtitle: 'List dan aksi status dummy', onTap: () => _open(context, const StoreOrdersScreen())),
          _MenuTile(icon: Icons.handyman_outlined, title: 'Diagnosis', subtitle: 'Aksi diagnosis ada di detail order', onTap: () => _open(context, const StoreOrdersScreen())),
          _MenuTile(icon: Icons.inventory_2_outlined, title: 'Inventory Sparepart', subtitle: 'Stok, reserved, tersedia', onTap: () => _open(context, const StoreInventoryScreen())),
          _MenuTile(icon: Icons.verified_outlined, title: 'Konfirmasi Pembayaran', subtitle: 'Aksi konfirmasi ada di detail order', onTap: () => _open(context, const StoreOrdersScreen())),
          _MenuTile(icon: Icons.gavel_outlined, title: 'Dispute Garansi', subtitle: 'List klaim dummy', onTap: () => _open(context, const StoreDisputesScreen())),
          _MenuTile(icon: Icons.settings_outlined, title: 'Pengaturan', subtitle: 'Warranty dan stok threshold', onTap: () => _open(context, const StoreSettingsScreen())),
        ],
      ),
    );
  }

  static void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _MetricCard(label: 'Order Aktif', value: '3')),
        SizedBox(width: 12),
        Expanded(child: _MetricCard(label: 'Menunggu Bayar', value: '1')),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          Text(label),
        ]),
      ),
    );
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
