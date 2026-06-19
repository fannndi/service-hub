import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/store_admin_providers.dart';
import '../../domain/store_admin_models.dart';
import '../widgets/store_admin_widgets.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(customersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Management')),
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorPanel(message: e.toString()),
        data: (page) => AdminDataTable<CustomerProfile>(
          items: page.items,
          columns: const [DataColumn(label: Text('Nama')), DataColumn(label: Text('HP')), DataColumn(label: Text('Order')), DataColumn(label: Text('Total Spend'))],
          cells: (c) => [DataCell(Text(c.name)), DataCell(Text(c.phone)), DataCell(Text('${c.totalOrders}')), DataCell(Text(money(c.totalSpent)))],
        ),
      ),
    );
  }
}
