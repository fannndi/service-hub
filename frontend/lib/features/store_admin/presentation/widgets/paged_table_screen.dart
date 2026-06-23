import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/store_admin_models.dart';
import 'admin_data_table.dart';
import 'error_panel.dart';
import 'store_admin_scaffold.dart';

class PagedTableScreen<T> extends StatelessWidget {
  const PagedTableScreen(
      {super.key,
      required this.title,
      required this.selectedIndex,
      required this.value,
      required this.columns,
      required this.cells,
      this.onTap});
  final String title;
  final int selectedIndex;
  final AsyncValue<PageResult<T>> value;
  final List<DataColumn> columns;
  final List<DataCell> Function(T item) cells;
  final void Function(T item)? onTap;
  @override
  Widget build(BuildContext context) => StoreAdminScaffold(
        title: title,
        selectedIndex: selectedIndex,
        body: value.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorPanel(message: e.toString()),
            data: (page) => AdminDataTable<T>(
                items: page.items,
                columns: columns,
                cells: cells,
                onTap: onTap)),
      );
}
