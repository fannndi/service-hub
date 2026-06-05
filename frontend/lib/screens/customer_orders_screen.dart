import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../shared_widgets/search_filter_bar.dart';
import 'customer_payment_screen.dart';
import 'customer_dispute_screen.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  String _filter = 'Semua';

  @override
  Widget build(BuildContext context) {
    final orders = _filter == 'Semua' ? demoOrders : demoOrders.where((order) => order.status.label == _filter).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Order Saya')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return SearchFilterBar(
              hintText: 'Cari nomor order / gadget',
              filters: const ['Semua', 'Menunggu Persetujuan', 'Sedang Diperbaiki', 'Menunggu Pembayaran', 'Selesai'],
              selectedFilter: _filter,
              onFilterSelected: (value) => setState(() => _filter = value),
            );
          }
          final order = orders[index - 1];
          return Card(
            child: ListTile(
              title: Text(order.orderNumber),
              subtitle: Text('${order.device}\n${order.status.label}'),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CustomerOrderDetailScreen(order: order))),
            ),
          );
        },
      ),
    );
  }
}

class CustomerOrderDetailScreen extends StatelessWidget {
  const CustomerOrderDetailScreen({super.key, required this.order});

  final DemoServiceOrder order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(order.orderNumber)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(order.device, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(order.issue),
          const SizedBox(height: 20),
          _Info(label: 'Status', value: order.status.label),
          _Info(label: 'Estimasi', value: rupiah(order.estimatedPrice)),
          _Info(label: 'Final', value: order.finalPrice == null ? '-' : rupiah(order.finalPrice!)),
          const SizedBox(height: 20),
          if (order.status == DemoOrderStatus.waitingApproval)
            FilledButton(onPressed: () {}, child: const Text('Setujui Estimasi')),
          if (order.status == DemoOrderStatus.waitingPayment)
            FilledButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CustomerPaymentScreen(orderNumber: order.orderNumber))), child: const Text('Upload Bukti Pembayaran')),
          OutlinedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CustomerDisputeScreen(orderNumber: order.orderNumber))), child: const Text('Ajukan Klaim Garansi')),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))]),
    );
  }
}

