import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/store_admin_models.dart';

final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
final _date = DateFormat('dd MMM yyyy HH:mm', 'id_ID');

String money(num value) => _currency.format(value);
String dateText(DateTime value) => value.millisecondsSinceEpoch == 0 ? '-' : _date.format(value);

class StoreAdminScaffold extends StatelessWidget {
  const StoreAdminScaffold({super.key, required this.title, required this.selectedIndex, required this.body, this.actions});
  final String title;
  final int selectedIndex;
  final Widget body;
  final List<Widget>? actions;

  static const destinations = [
    ('Dashboard', Icons.dashboard_outlined, '/store/dashboard'),
    ('Order', Icons.receipt_long_outlined, '/store/orders'),
    ('Stok', Icons.inventory_2_outlined, '/store/inventory'),
    ('Bayar', Icons.payments_outlined, '/store/payments'),
    ('Analitik', Icons.query_stats_outlined, '/store/analytics'),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      drawer: wide ? null : Drawer(child: SafeArea(child: _NavList(selectedIndex: selectedIndex))),
      body: Row(
        children: [
          if (wide) NavigationRail(extended: MediaQuery.sizeOf(context).width >= 1200, selectedIndex: selectedIndex, destinations: [for (final item in destinations) NavigationRailDestination(icon: Icon(item.$2), label: Text(item.$1))], onDestinationSelected: (index) => context.go(destinations[index].$3)),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex,
              destinations: [for (final item in destinations) NavigationDestination(icon: Icon(item.$2), label: item.$1)],
              onDestinationSelected: (index) => context.go(destinations[index].$3),
            ),
    );
  }
}

class _NavList extends StatelessWidget {
  const _NavList({required this.selectedIndex});
  final int selectedIndex;

  @override
  Widget build(BuildContext context) => ListView(
        children: [
          const ListTile(title: Text('ServisGadget Admin'), subtitle: Text('Operasional toko')),
          for (var i = 0; i < StoreAdminScaffold.destinations.length; i++)
            ListTile(
              selected: i == selectedIndex,
              leading: Icon(StoreAdminScaffold.destinations[i].$2),
              title: Text(StoreAdminScaffold.destinations[i].$1),
              onTap: () => context.go(StoreAdminScaffold.destinations[i].$3),
            ),
        ],
      );
}

class AsyncPage<T> extends StatelessWidget {
  const AsyncPage({super.key, required this.value, required this.builder});
  final AsyncSnapshot<T> value;
  final Widget Function(T data) builder;
  @override
  Widget build(BuildContext context) {
    if (value.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
    if (value.hasError) return ErrorPanel(message: value.error.toString());
    final data = value.data;
    return data == null ? const EmptyPanel(message: 'Data belum tersedia') : builder(data);
  }
}

class ErrorPanel extends StatelessWidget {
  const ErrorPanel({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 36),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Muat ulang')),
          ]),
        ),
      );
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({super.key, required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(message, textAlign: TextAlign.center)));
}

class MetricCard extends StatelessWidget {
  const MetricCard({super.key, required this.title, required this.value, required this.icon, this.subtitle, this.onTap});
  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Icon(icon, size: 32),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(title, style: Theme.of(context).textTheme.labelLarge), Text(value, style: Theme.of(context).textTheme.headlineSmall), if (subtitle != null) Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis)])),
            ]),
          ),
        ),
      );
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, this.warning = false});
  final String label;
  final bool warning;
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: warning ? Colors.orange.withValues(alpha: .14) : Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(999)),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: Text(label, style: Theme.of(context).textTheme.labelMedium)),
      );
}

class AdminDataTable<T> extends StatelessWidget {
  const AdminDataTable({super.key, required this.items, required this.columns, required this.cells, this.onTap, this.emptyText = 'Belum ada data'});
  final List<T> items;
  final List<DataColumn> columns;
  final List<DataCell> Function(T item) cells;
  final void Function(T item)? onTap;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return EmptyPanel(message: emptyText);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        showCheckboxColumn: true,
        columns: columns,
        rows: [for (final item in items) DataRow(cells: cells(item), onSelectChanged: onTap == null ? null : (_) => onTap!(item))],
      ),
    );
  }
}

class QueryToolbar extends StatelessWidget {
  const QueryToolbar({super.key, required this.hint, required this.onSearch, this.filters = const []});
  final String hint;
  final ValueChanged<String> onSearch;
  final List<Widget> filters;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(width: 320, child: SearchBar(hintText: hint, leading: const Icon(Icons.search), onSubmitted: onSearch)),
          ...filters,
          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.download_outlined), label: const Text('Export')),
        ]),
      );
}

class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({super.key, required this.title, required this.items});
  final String title;
  final List<CategoryMetric> items;
  @override
  Widget build(BuildContext context) {
    final max = items.fold<num>(1, (value, item) => item.value > value ? item.value : value);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (items.isEmpty) const Text('Data grafik belum tersedia dari API'),
          for (final item in items.take(8))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                SizedBox(width: 120, child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis)),
                Expanded(child: LinearProgressIndicator(value: (item.value / max).clamp(0, 1).toDouble(), minHeight: 10)),
                const SizedBox(width: 8),
                Text(item.value.toString()),
              ]),
            ),
        ]),
      ),
    );
  }
}

class OrderActionPanel extends StatelessWidget {
  const OrderActionPanel({super.key, required this.order, required this.onAction});
  final StoreOrder order;
  final ValueChanged<String> onAction;
  @override
  Widget build(BuildContext context) {
    if (order.allowedActions.isEmpty) return const Text('Tidak ada aksi valid dari state machine backend.');
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final action in order.allowedActions)
          FilledButton.icon(onPressed: () => onAction(action), icon: const Icon(Icons.play_arrow), label: Text(_actionLabel(action))),
      ],
    );
  }

  String _actionLabel(String value) => switch (value) {
        'receive_device' => 'Terima Device',
        'start_diagnosis' => 'Mulai Diagnosa',
        'submit_diagnosis' => 'Submit Diagnosa',
        'start_repair' => 'Mulai Repair',
        'quality_check' => 'QC Selesai',
        'request_payment' => 'Tagih Bayar',
        _ => value.replaceAll('_', ' '),
      };
}
