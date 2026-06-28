import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/store_admin_providers.dart';
import '../../domain/store_admin_models.dart';
import '../widgets/store_admin_widgets.dart';
import '../../../../core/l10n/app_localizations.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      PagedTableScreen<PaymentRecord>(
        title: context.l10n.payment,
        selectedIndex: 3,
        value: ref.watch(paymentsProvider),
        columns: [
          DataColumn(label: Text(context.l10n.date)),
          DataColumn(label: Text(context.l10n.amount)),
          DataColumn(label: Text(context.l10n.method)),
          DataColumn(label: Text(context.l10n.status))
        ],
        cells: (p) => [
          DataCell(Text(dateText(p.createdAt))),
          DataCell(Text(money(p.amount))),
          DataCell(Text(p.method)),
          DataCell(Text(p.status.label))
        ],
      );
}
