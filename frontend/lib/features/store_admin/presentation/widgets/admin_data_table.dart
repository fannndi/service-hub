import 'package:flutter/material.dart';
import '../../../../ui/widgets/modern_card.dart';
import 'empty_panel.dart';

class AdminDataTable<T> extends StatelessWidget {
  const AdminDataTable(
      {super.key,
      required this.items,
      required this.columns,
      required this.cells,
      this.onTap,
      this.emptyText = 'Belum ada data'});
  final List<T> items;
  final List<DataColumn> columns;
  final List<DataCell> Function(T item) cells;
  final void Function(T item)? onTap;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return EmptyPanel(message: emptyText);
    return ModernCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: true,
          columns: columns,
          rows: [
            for (final item in items)
              DataRow(
                  cells: cells(item),
                  onSelectChanged: onTap == null ? null : (_) => onTap!(item))
          ],
        ),
      ),
    );
  }
}
