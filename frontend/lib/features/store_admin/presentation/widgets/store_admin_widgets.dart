import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/store_admin_models.dart';

final _currency =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
final _date = DateFormat('dd MMM yyyy HH:mm', 'id_ID');

String money(num value) => _currency.format(value);
String dateText(DateTime value) =>
    value.millisecondsSinceEpoch == 0 ? '-' : _date.format(value);

class StoreAdminScaffold extends StatelessWidget {
  const StoreAdminScaffold(
      {super.key,
      required this.title,
      required this.selectedIndex,
      required this.body,
      this.actions});
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      drawer: wide
          ? null
          : Drawer(
              child: SafeArea(child: _NavList(selectedIndex: selectedIndex))),
      body: Row(
        children: [
          if (wide)
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(
                    right: BorderSide(
                        color: scheme.outlineVariant.withValues(alpha: .7))),
              ),
              child: NavigationRail(
                  extended: MediaQuery.sizeOf(context).width >= 1200,
                  selectedIndex: selectedIndex,
                  destinations: [
                    for (final item in destinations)
                      NavigationRailDestination(
                          icon: Icon(item.$2), label: Text(item.$1))
                  ],
                  onDestinationSelected: (index) =>
                      context.go(destinations[index].$3)),
            ),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex,
              destinations: [
                for (final item in destinations)
                  NavigationDestination(icon: Icon(item.$2), label: item.$1)
              ],
              onDestinationSelected: (index) =>
                  context.go(destinations[index].$3),
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('ServisGadget Admin',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text('Operasional toko'),
          ),
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
    if (value.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (value.hasError) return ErrorPanel(message: value.error.toString());
    final data = value.data;
    return data == null
        ? const EmptyPanel(message: 'Data belum tersedia')
        : builder(data);
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
            Icon(Icons.error_outline,
                size: 36, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null)
              TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Muat ulang')),
          ]),
        ),
      );
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({super.key, required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant))));
}

class MetricCard extends StatelessWidget {
  const MetricCard(
      {super.key,
      required this.title,
      required this.value,
      required this.icon,
      this.subtitle,
      this.onTap});
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: .7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon,
                    size: 22,
                    color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Text(title,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    Text(value,
                        style: Theme.of(context).textTheme.headlineSmall),
                    if (subtitle != null)
                      Text(subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant))
                  ])),
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
        decoration: BoxDecoration(
            color: warning
                ? Colors.orange.withValues(alpha: .14)
                : Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: .72),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: .7))),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w800))),
      );
}

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
    return Card(
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

class QueryToolbar extends StatelessWidget {
  const QueryToolbar(
      {super.key,
      required this.hint,
      required this.onSearch,
      this.filters = const []});
  final String hint;
  final ValueChanged<String> onSearch;
  final List<Widget> filters;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                  width: 320,
                  child: SearchBar(
                      hintText: hint,
                      leading: const Icon(Icons.search),
                      elevation: const WidgetStatePropertyAll(0),
                      onSubmitted: onSearch)),
              ...filters,
              OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Export')),
            ]),
      );
}

class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({super.key, required this.title, required this.items});
  final String title;
  final List<CategoryMetric> items;
  @override
  Widget build(BuildContext context) {
    final max = items.fold<num>(
        1, (value, item) => item.value > value ? item.value : value);
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
                SizedBox(
                    width: 120,
                    child: Text(item.label,
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                Expanded(
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                            value: (item.value / max).clamp(0, 1).toDouble(),
                            minHeight: 10))),
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
  const OrderActionPanel(
      {super.key, required this.order, required this.onAction});
  final StoreOrder order;
  final ValueChanged<String> onAction;
  @override
  Widget build(BuildContext context) {
    if (order.allowedActions.isEmpty) {
      return const Text('Tidak ada aksi valid dari state machine backend.');
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final action in order.allowedActions)
          FilledButton.icon(
              onPressed: () => onAction(action),
              icon: const Icon(Icons.play_arrow),
              label: Text(_actionLabel(action))),
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

// ─── Shared Widgets (split from store_admin_screens.dart) ───

class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.cards});
  final List<Widget> cards;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final columns = c.maxWidth >= 1100
            ? 4
            : c.maxWidth >= 700
                ? 2
                : 1;
        return GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3.2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: cards);
      });
}

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

class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.title, required this.rows});
  final String title;
  final Map<String, String> rows;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final row in rows.entries)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    SizedBox(width: 120, child: Text(row.key)),
                    Expanded(child: Text(row.value))
                  ]))
          ])));
}

class CredentialCard extends StatelessWidget {
  const CredentialCard({super.key, required this.panel});
  final CredentialPanel panel;
  @override
  Widget build(BuildContext context) => Card(
        color: panel.hasCredential
            ? Theme.of(context).colorScheme.tertiaryContainer
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                panel.hasCredential
                    ? 'Pelanggan Baru - Kirim via WA'
                    : 'Kredensial sudah terkirim atau expired',
                style: Theme.of(context).textTheme.titleMedium),
            Text('HP: ${panel.phoneNumber}'),
            if (panel.password != null) Text('Password: ${"*" * 8}'),
            if (panel.expiresAt != null)
              Text('Berlaku s/d: ${dateText(panel.expiresAt!)}'),
          ]),
        ),
      );
}
