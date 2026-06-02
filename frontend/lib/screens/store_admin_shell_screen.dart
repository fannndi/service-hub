import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/demo_auth_controller.dart';
import '../shared_widgets/app_info_card.dart';
import 'store_disputes_screen.dart';
import 'store_inventory_screen.dart';
import 'store_notifications_screen.dart';
import 'store_orders_screen.dart';
import 'store_settings_screen.dart';

class StoreAdminShellScreen extends ConsumerStatefulWidget {
  const StoreAdminShellScreen({super.key});

  @override
  ConsumerState<StoreAdminShellScreen> createState() => _StoreAdminShellScreenState();
}

class _StoreAdminShellScreenState extends ConsumerState<StoreAdminShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _StoreDashboard(onOpen: _open),
      const StoreOrdersScreen(),
      const StoreInventoryScreen(),
      const StoreSettingsScreen(),
    ];
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Order'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Stok'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Setting'),
        ],
      ),
    );
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _StoreDashboard extends ConsumerWidget {
  const _StoreDashboard({required this.onOpen});

  final void Function(Widget screen) onOpen;

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
          OutlinedButton.icon(onPressed: () => onOpen(const StoreNotificationsScreen()), icon: const Icon(Icons.notifications_outlined), label: const Text('Notifikasi Toko')),
          const SizedBox(height: 16),
          const Row(children: [
            Expanded(child: _MetricCard(label: 'Order Aktif', value: '3')),
            SizedBox(width: 12),
            Expanded(child: _MetricCard(label: 'Menunggu Bayar', value: '1')),
          ]),
          const SizedBox(height: 16),
          AppInfoCard(icon: Icons.assignment_outlined, title: 'Order Masuk', subtitle: 'List dan aksi status dummy', onTap: () => onOpen(const StoreOrdersScreen())),
          AppInfoCard(icon: Icons.handyman_outlined, title: 'Diagnosis', subtitle: 'Aksi diagnosis ada di detail order', onTap: () => onOpen(const StoreOrdersScreen())),
          AppInfoCard(icon: Icons.inventory_2_outlined, title: 'Inventory Sparepart', subtitle: 'Stok, reserved, tersedia', onTap: () => onOpen(const StoreInventoryScreen())),
          AppInfoCard(icon: Icons.gavel_outlined, title: 'Dispute Garansi', subtitle: 'List klaim dummy', onTap: () => onOpen(const StoreDisputesScreen())),
        ],
      ),
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
