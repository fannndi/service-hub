import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../shared_widgets/credential_panel_card.dart';
import '../shared_widgets/search_filter_bar.dart';
import '../shared_widgets/sla_countdown_badge.dart';
import 'store_diagnosis_screen.dart';
import 'store_payment_confirm_screen.dart';

class StoreOrdersScreen extends StatefulWidget {
  const StoreOrdersScreen({super.key});

  @override
  State<StoreOrdersScreen> createState() => _StoreOrdersScreenState();
}

class _StoreOrdersScreenState extends State<StoreOrdersScreen> {
  String _filter = 'Semua';

  @override
  Widget build(BuildContext context) {
    final orders = _filter == 'Semua' ? demoOrders : demoOrders.where((order) => order.status.label == _filter).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Order Toko')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return SearchFilterBar(
              hintText: 'Cari customer / nomor order',
              filters: const ['Semua', 'Menunggu Persetujuan', 'Sedang Diperbaiki', 'Menunggu Pembayaran', 'Klaim Garansi'],
              selectedFilter: _filter,
              onFilterSelected: (value) => setState(() => _filter = value),
            );
          }
          final order = orders[index - 1];
          return Card(
            child: ListTile(
              title: Text('${order.orderNumber} • ${order.customerName}'),
              subtitle: Text('${order.device}\n${order.status.label}'),
              isThreeLine: true,
              trailing: const SlaCountdownBadge(hoursLeft: 5),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StoreOrderDetailScreen(order: order))),
            ),
          );
        },
      ),
    );
  }
}

class StoreOrderDetailScreen extends StatelessWidget {
  const StoreOrderDetailScreen({super.key, required this.order});

  final DemoServiceOrder order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(order.orderNumber)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(order.customerName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          Text(order.device),
          const SizedBox(height: 16),
          Text(order.issue),
          const SizedBox(height: 20),
          const CredentialPanelCard(),
          const SizedBox(height: 12),
          const _ActionButton(label: 'Tandai Perangkat Diterima'),
          _ActionButton(label: 'Input Diagnosis', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StoreDiagnosisScreen(orderNumber: order.orderNumber)))),
          const _ActionButton(label: 'Mulai Repairing'),
          const _ActionButton(label: 'Quality Check'),
          _ActionButton(label: 'Konfirmasi Pembayaran', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StorePaymentConfirmScreen(orderNumber: order.orderNumber)))),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton(onPressed: onTap, child: Text(label)),
    );
  }
}
