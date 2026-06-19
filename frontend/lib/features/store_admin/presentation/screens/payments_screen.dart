import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/store_admin_providers.dart';
import '../../domain/store_admin_models.dart';
import '../widgets/store_admin_widgets.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      PagedTableScreen<PaymentRecord>(
        title: 'Payments',
        selectedIndex: 3,
        value: ref.watch(paymentsProvider),
        columns: const [
          DataColumn(label: Text('Tanggal')),
          DataColumn(label: Text('Nominal')),
          DataColumn(label: Text('Metode')),
          DataColumn(label: Text('Status'))
        ],
        cells: (p) => [
          DataCell(Text(dateText(p.createdAt))),
          DataCell(Text(money(p.amount))),
          DataCell(Text(p.method)),
          DataCell(Text(p.status.label))
        ],
      );
}
