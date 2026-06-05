import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/demo_auth_controller.dart';
import '../shared_widgets/app_info_card.dart';
import 'customer_coupons_screen.dart';
import 'customer_create_order_screen.dart';
import 'customer_dispute_screen.dart';
import 'customer_notifications_screen.dart';
import 'customer_orders_screen.dart';
import 'customer_profile_screen.dart';
import 'customer_review_screen.dart';

class CustomerShellScreen extends ConsumerStatefulWidget {
  const CustomerShellScreen({super.key});

  @override
  ConsumerState<CustomerShellScreen> createState() => _CustomerShellScreenState();
}

class _CustomerShellScreenState extends ConsumerState<CustomerShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _CustomerDashboard(onOpen: _open),
      const CustomerOrdersScreen(),
      const CustomerCouponsScreen(),
      const CustomerProfileScreen(),
    ];
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Order'),
          NavigationDestination(icon: Icon(Icons.confirmation_number_outlined), selectedIcon: Icon(Icons.confirmation_number), label: 'Kupon'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _CustomerDashboard extends ConsumerWidget {
  const _CustomerDashboard({required this.onOpen});

  final void Function(Widget screen) onOpen;

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
          const Text('Data masih dummy lokal untuk bantu Phase 02.'),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => onOpen(const CustomerNotificationsScreen()), icon: const Icon(Icons.notifications_outlined), label: const Text('Notifikasi'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(onPressed: () => onOpen(const CustomerCouponsScreen()), icon: const Icon(Icons.confirmation_number_outlined), label: const Text('Kupon'))),
          ]),
          const SizedBox(height: 16),
          AppInfoCard(icon: Icons.build_circle_outlined, title: 'Buat Service', subtitle: 'Form order gadget dummy', onTap: () => onOpen(const CustomerCreateOrderScreen())),
          AppInfoCard(icon: Icons.receipt_long_outlined, title: 'Order Saya', subtitle: 'List dan detail order dummy', onTap: () => onOpen(const CustomerOrdersScreen())),
          AppInfoCard(icon: Icons.payments_outlined, title: 'Pembayaran', subtitle: 'Aksi pembayaran ada di detail order', onTap: () => onOpen(const CustomerOrdersScreen())),
          AppInfoCard(icon: Icons.reviews_outlined, title: 'Review & Kupon', subtitle: 'Form review dummy', onTap: () => onOpen(const CustomerReviewScreen())),
          AppInfoCard(icon: Icons.report_problem_outlined, title: 'Klaim Garansi', subtitle: 'Form klaim garansi dummy', onTap: () => onOpen(const CustomerDisputeScreen(orderNumber: 'SG-Z1N8BV'))),
        ],
      ),
    );
  }
}

