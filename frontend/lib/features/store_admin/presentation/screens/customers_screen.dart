import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/store_admin_providers.dart';
import '../../domain/store_admin_models.dart';
import '../widgets/store_admin_widgets.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'package:m3_expressive/m3_expressive.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(customersProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.customerManagement)),
      body: value.when(
        loading: () => const Center(child: M3LoadingIndicator()),
        error: (e, _) => ErrorPanel(message: e.toString()),
        data: (items) {
          final profiles = items
              .whereType<Map<String, dynamic>>()
              .map(CustomerProfile.fromJson)
              .toList();
          return AdminDataTable<CustomerProfile>(
            items: profiles,
            columns: [
              DataColumn(label: Text(context.l10n.name)),
              DataColumn(label: Text(context.l10n.phone)),
              DataColumn(label: Text(context.l10n.orders)),
              DataColumn(label: Text(context.l10n.totalSpend))
            ],
            cells: (c) => [
              DataCell(Text(c.name)),
              DataCell(Text(c.phone)),
              DataCell(Text('${c.totalOrders}')),
              DataCell(Text(money(c.totalSpent)))
            ],
          );
        },
      ),
    );
  }
}
