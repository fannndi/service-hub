import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/store_admin_providers.dart';
import '../../data/store_admin_repositories.dart';
import '../../domain/store_admin_models.dart';
import '../widgets/store_admin_widgets.dart';

class StoreLoginScreen extends ConsumerStatefulWidget {
  const StoreLoginScreen({super.key});
  @override
  ConsumerState<StoreLoginScreen> createState() => _StoreLoginScreenState();
}

class _StoreLoginScreenState extends ConsumerState<StoreLoginScreen> {
  final phone = TextEditingController();
  final password = TextEditingController();
  bool obscure = true;
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(storeAuthControllerProvider);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('ServisGadget - Portal Toko', style: Theme.of(context).textTheme.headlineSmall),
                const Text('Masuk sebagai Admin Toko'),
                const SizedBox(height: 24),
                TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Nomor HP', prefixText: '+62 ')),
                const SizedBox(height: 12),
                TextField(controller: password, obscureText: obscure, decoration: InputDecoration(labelText: 'Password', suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
                const SizedBox(height: 18),
                FilledButton.icon(onPressed: auth.isLoading ? null : () => ref.read(storeAuthControllerProvider.notifier).login(phone.text.trim(), password.text), icon: const Icon(Icons.login), label: const Text('Masuk')),
                if (auth.hasError) Padding(padding: const EdgeInsets.only(top: 12), child: Text(auth.error.toString(), style: TextStyle(color: Theme.of(context).colorScheme.error))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class StoreChangePasswordScreen extends ConsumerStatefulWidget {
  const StoreChangePasswordScreen({super.key});
  @override
  ConsumerState<StoreChangePasswordScreen> createState() => _StoreChangePasswordScreenState();
}

class _StoreChangePasswordScreenState extends ConsumerState<StoreChangePasswordScreen> {
  final oldPassword = TextEditingController();
  final newPassword = TextEditingController();
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Ganti Password')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: oldPassword, obscureText: true, decoration: const InputDecoration(labelText: 'Password lama')),
                const SizedBox(height: 12),
                TextField(controller: newPassword, obscureText: true, decoration: const InputDecoration(labelText: 'Password baru')),
                const SizedBox(height: 18),
                FilledButton.icon(onPressed: () => ref.read(storeAuthControllerProvider.notifier).changePassword(oldPassword.text, newPassword.text), icon: const Icon(Icons.lock_reset), label: const Text('Simpan Password')),
              ]),
            ),
          ),
        ),
      );
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    return StoreAdminScaffold(
      title: 'Dashboard',
      selectedIndex: 0,
      actions: [IconButton(onPressed: () => ref.read(storeAuthControllerProvider.notifier).logout(), icon: const Icon(Icons.logout), tooltip: 'Logout')],
      body: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorPanel(message: err.toString(), onRetry: () => ref.invalidate(dashboardSummaryProvider)),
        data: (data) => ListView(padding: const EdgeInsets.all(16), children: [
          Text('Halo, ${data.adminName}!', style: Theme.of(context).textTheme.headlineSmall),
          Text('${data.storeName} | Rating ${data.ratingAvg.toStringAsFixed(1)}'),
          const SizedBox(height: 16),
          _MetricGrid(cards: [
            MetricCard(title: 'Revenue', value: money(data.revenueMonth), subtitle: 'Bulan ini', icon: Icons.payments_outlined),
            MetricCard(title: 'Orders', value: '${data.todayOrders}', subtitle: '${data.activeOrders} aktif', icon: Icons.receipt_long_outlined, onTap: () => context.go('/orders')),
            MetricCard(title: 'Customers', value: '${data.customers}', subtitle: 'Profil pelanggan', icon: Icons.groups_outlined, onTap: () => context.go('/customers')),
            MetricCard(title: 'Reviews', value: data.ratingAvg.toStringAsFixed(1), subtitle: 'Rata-rata rating', icon: Icons.star_border, onTap: () => context.go('/reviews')),
            MetricCard(title: 'Pending Payment', value: '${data.pendingPayments}', subtitle: 'Butuh verifikasi', icon: Icons.fact_check_outlined, onTap: () => context.go('/payments')),
            MetricCard(title: 'Active Disputes', value: '${data.activeDisputes}', subtitle: 'Klaim terbuka', icon: Icons.gavel_outlined, onTap: () => context.go('/disputes')),
          ]),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final entry in data.statusBreakdown.entries) StatusPill(label: '${entry.key}: ${entry.value}')]),
          const SizedBox(height: 16),
          SimpleBarChart(title: 'Revenue Trend', items: data.revenueTrend.map((e) => CategoryMetric(e.label, e.value)).toList()),
          SimpleBarChart(title: 'Service Categories', items: data.serviceCategories),
          SimpleBarChart(title: 'Sparepart Consumption', items: data.sparepartConsumption),
          Text('Recent Orders', style: Theme.of(context).textTheme.titleMedium),
          AdminDataTable<StoreOrder>(
            items: data.recentOrders,
            columns: const [DataColumn(label: Text('Order')), DataColumn(label: Text('Pelanggan')), DataColumn(label: Text('Status')), DataColumn(label: Text('Estimasi'))],
            cells: (o) => [DataCell(Text(o.orderNumber)), DataCell(Text(o.customerName)), DataCell(StatusPill(label: o.status.label)), DataCell(Text(money(o.estimatedTotal)))],
            onTap: (o) => context.go('/orders/${o.id}'),
          ),
        ]),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.cards});
  final List<Widget> cards;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final columns = c.maxWidth >= 1100 ? 4 : c.maxWidth >= 700 ? 2 : 1;
        return GridView.count(crossAxisCount: columns, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 3.2, children: cards);
      });
}

class OrderListScreen extends ConsumerWidget {
  const OrderListScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(storeOrdersProvider);
    return StoreAdminScaffold(
      title: 'Order Management',
      selectedIndex: 1,
      body: Column(children: [
        QueryToolbar(
          hint: 'Cari order, pelanggan, device',
          onSearch: (q) => ref.read(orderQueryProvider.notifier).state = ref.read(orderQueryProvider).copyWith(search: q, page: 1),
          filters: [for (final s in [null, ...StoreOrderStatus.values]) FilterChip(label: Text(s?.label ?? 'Semua'), selected: ref.watch(orderQueryProvider).status == s?.value, onSelected: (_) => ref.read(orderQueryProvider.notifier).state = ref.read(orderQueryProvider).copyWith(status: s?.value, page: 1))],
        ),
        Expanded(
          child: data.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => ErrorPanel(message: err.toString(), onRetry: () => ref.invalidate(storeOrdersProvider)),
            data: (page) => AdminDataTable<StoreOrder>(
              items: page.items,
              columns: const [DataColumn(label: Text('Order')), DataColumn(label: Text('Pelanggan')), DataColumn(label: Text('Device')), DataColumn(label: Text('Status')), DataColumn(label: Text('SLA'))],
              cells: (o) => [DataCell(Text(o.orderNumber)), DataCell(Text(o.customerName)), DataCell(Text(o.deviceName)), DataCell(StatusPill(label: o.status.label)), DataCell(Text(o.slaDeadline == null ? '-' : dateText(o.slaDeadline!)))],
              onTap: (o) => context.go('/orders/${o.id}'),
            ),
          ),
        ),
      ]),
    );
  }
}

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId));
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Order'), actions: [IconButton(onPressed: () => context.go('/orders/$orderId/tracking'), icon: const Icon(Icons.timeline), tooltip: 'Tracking')]),
      body: order.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorPanel(message: err.toString(), onRetry: () => ref.invalidate(orderDetailProvider(orderId))),
        data: (o) => ListView(padding: const EdgeInsets.all(16), children: [
          Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [Text(o.orderNumber, style: Theme.of(context).textTheme.headlineSmall), StatusPill(label: o.status.label)]),
          _InfoCard(title: 'Pelanggan', rows: {'Nama': o.customerName, 'HP': o.customerPhone, 'Device': o.deviceName, 'Alamat': o.deliveryAddress ?? '-'}),
          if (o.credentialPanel != null) _CredentialCard(panel: o.credentialPanel!),
          _InfoCard(title: 'Harga', rows: {'Estimasi': money(o.estimatedTotal), 'Final': money(o.finalPrice), 'Payment': o.paymentStatus}),
          Text('Item Order', style: Theme.of(context).textTheme.titleMedium),
          AdminDataTable<OrderItem>(items: o.items, columns: const [DataColumn(label: Text('Service')), DataColumn(label: Text('Sparepart')), DataColumn(label: Text('Harga')), DataColumn(label: Text('Status'))], cells: (i) => [DataCell(Text(i.serviceType)), DataCell(Text(i.sparepartName)), DataCell(Text(money(i.price))), DataCell(Text(i.status))]),
          const SizedBox(height: 16),
          OrderActionPanel(order: o, onAction: (action) => action == 'submit_diagnosis' ? context.go('/orders/$orderId/diagnosis') : ref.read(storeOrdersProvider.notifier).runAction(orderId, action)),
        ]),
      ),
    );
  }
}

class DiagnosisScreen extends ConsumerStatefulWidget {
  const DiagnosisScreen({super.key, required this.orderId});
  final String orderId;
  @override
  ConsumerState<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends ConsumerState<DiagnosisScreen> {
  final condition = TextEditingController();
  final damage = TextEditingController();
  final repair = TextEditingController();
  final technician = TextEditingController();
  final estimatedCost = TextEditingController();
  final estimatedDuration = TextEditingController();
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Diagnosis Form')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(controller: condition, maxLines: 2, decoration: const InputDecoration(labelText: 'Device Condition')),
          TextField(controller: damage, maxLines: 3, decoration: const InputDecoration(labelText: 'Damage Notes')),
          TextField(controller: repair, maxLines: 3, decoration: const InputDecoration(labelText: 'Repair Notes')),
          TextField(controller: technician, maxLines: 3, decoration: const InputDecoration(labelText: 'Technician Notes')),
          TextField(controller: estimatedCost, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Estimated Cost')),
          TextField(controller: estimatedDuration, decoration: const InputDecoration(labelText: 'Estimated Duration')),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: () async {
            await ref.read(storeOrdersProvider.notifier).submitDiagnosis(widget.orderId, {'deviceCondition': condition.text, 'damageNotes': damage.text, 'repairNotes': repair.text, 'technicianNotes': technician.text, 'estimatedCost': num.tryParse(estimatedCost.text) ?? 0, 'estimatedDuration': estimatedDuration.text, 'diagnosisItems': <Map<String, Object?>>[], 'serviceFee': num.tryParse(estimatedCost.text) ?? 0});
            if (context.mounted) context.go('/orders/${widget.orderId}');
          }, icon: const Icon(Icons.save_outlined), label: const Text('Submit Diagnosis')),
        ]),
      );
}

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key, required this.orderId});
  final String orderId;
  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  final title = TextEditingController();
  final note = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(storeOperationsRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tracking Timeline')),
      body: FutureBuilder<List<TrackingEvent>>(
        future: repo.tracking(widget.orderId),
        builder: (context, snapshot) => ListView(padding: const EdgeInsets.all(16), children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: 'Judul event')),
          TextField(controller: note, decoration: const InputDecoration(labelText: 'Catatan')),
          FilledButton.icon(onPressed: () async { await repo.addTracking(widget.orderId, title.text, note.text, 'progress'); setState(() {}); }, icon: const Icon(Icons.add), label: const Text('Tambah Event')),
          const SizedBox(height: 16),
          if (snapshot.connectionState == ConnectionState.waiting) const Center(child: CircularProgressIndicator()),
          for (final event in snapshot.data ?? const <TrackingEvent>[]) ListTile(leading: const Icon(Icons.check_circle_outline), title: Text(event.title), subtitle: Text('${event.note}\n${dateText(event.createdAt)}')),
        ]),
      ),
    );
  }
}

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(inventoryProvider);
    return StoreAdminScaffold(
      title: 'Sparepart Management',
      selectedIndex: 2,
      actions: [IconButton(onPressed: () => context.go('/inventory/new'), icon: const Icon(Icons.add), tooltip: 'Tambah sparepart')],
      body: Column(children: [
        QueryToolbar(hint: 'Cari sparepart', onSearch: (q) => ref.read(inventoryQueryProvider.notifier).state = ref.read(inventoryQueryProvider).copyWith(search: q)),
        Expanded(
          child: data.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => ErrorPanel(message: err.toString(), onRetry: () => ref.invalidate(inventoryProvider)),
            data: (page) => AdminDataTable<Sparepart>(
              items: page.items,
              columns: const [DataColumn(label: Text('Nama')), DataColumn(label: Text('Harga')), DataColumn(label: Text('Stok')), DataColumn(label: Text('Reserved')), DataColumn(label: Text('Alert'))],
              cells: (s) => [DataCell(Text(s.name)), DataCell(Text(money(s.price))), DataCell(Text('${s.qty}')), DataCell(Text('${s.qtyReserved}')), DataCell(StatusPill(label: s.isLowStock ? 'Low Stock' : 'Aman', warning: s.isLowStock))],
              onTap: (s) => context.go('/inventory/${s.id}', extra: s),
            ),
          ),
        ),
      ]),
    );
  }
}

class SparepartFormScreen extends ConsumerStatefulWidget {
  const SparepartFormScreen({super.key, this.item});
  final Sparepart? item;
  @override
  ConsumerState<SparepartFormScreen> createState() => _SparepartFormScreenState();
}

class _SparepartFormScreenState extends ConsumerState<SparepartFormScreen> {
  late final name = TextEditingController(text: widget.item?.name);
  late final description = TextEditingController(text: widget.item?.description);
  late final price = TextEditingController(text: widget.item?.price.toString());
  late final qty = TextEditingController(text: widget.item?.qty.toString());
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.item == null ? 'Create Sparepart' : 'Edit Sparepart')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama')),
          TextField(controller: description, decoration: const InputDecoration(labelText: 'Deskripsi')),
          TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga')),
          TextField(controller: qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stok')),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: () async { await ref.read(inventoryProvider.notifier).save({'name': name.text, 'description': description.text, 'price': num.tryParse(price.text) ?? 0, 'qty': int.tryParse(qty.text) ?? 0}, id: widget.item?.id); if (context.mounted) context.go('/inventory'); }, icon: const Icon(Icons.save_outlined), label: const Text('Simpan')),
        ]),
      );
}

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => _PagedTableScreen<PaymentRecord>(
        title: 'Payments',
        selectedIndex: 3,
        value: ref.watch(paymentsProvider),
        columns: const [DataColumn(label: Text('Tanggal')), DataColumn(label: Text('Nominal')), DataColumn(label: Text('Metode')), DataColumn(label: Text('Status'))],
        cells: (p) => [DataCell(Text(dateText(p.createdAt))), DataCell(Text(money(p.amount))), DataCell(Text(p.method)), DataCell(Text(p.status.label))],
      );
}

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(reviewsProvider);
    return Scaffold(appBar: AppBar(title: const Text('Review Monitoring')), body: value.when(loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => ErrorPanel(message: e.toString()), data: (page) => AdminDataTable<ReviewItem>(items: page.items, columns: const [DataColumn(label: Text('Pelanggan')), DataColumn(label: Text('Rating')), DataColumn(label: Text('Komentar')), DataColumn(label: Text('Tanggal'))], cells: (r) => [DataCell(Text(r.customerName)), DataCell(Text('${r.rating}/5')), DataCell(Text(r.comment)), DataCell(Text(dateText(r.createdAt)))])));
  }
}

class DisputesScreen extends ConsumerWidget {
  const DisputesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => _PagedTableScreen<DisputeCase>(
        title: 'Dispute Queue',
        selectedIndex: 1,
        value: ref.watch(disputesProvider),
        columns: const [DataColumn(label: Text('Order')), DataColumn(label: Text('Pelanggan')), DataColumn(label: Text('Tipe')), DataColumn(label: Text('Status'))],
        cells: (d) => [DataCell(Text(d.orderNumber)), DataCell(Text(d.customerName)), DataCell(Text(d.type)), DataCell(Text(d.status.label))],
        onTap: (d) => context.go('/disputes/${d.id}', extra: d),
      );
}

class DisputeDetailScreen extends ConsumerStatefulWidget {
  const DisputeDetailScreen({super.key, required this.dispute});
  final DisputeCase dispute;
  @override
  ConsumerState<DisputeDetailScreen> createState() => _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends ConsumerState<DisputeDetailScreen> {
  final reason = TextEditingController();
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.dispute.orderNumber)),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Text(widget.dispute.description),
          TextField(controller: reason, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'Catatan resolusi')),
          Wrap(spacing: 8, children: [
            FilledButton.icon(onPressed: () => _resolve(true), icon: const Icon(Icons.check), label: const Text('Terima Klaim')),
            OutlinedButton.icon(onPressed: () => _resolve(false), icon: const Icon(Icons.close), label: const Text('Tolak Klaim')),
          ]),
        ]),
      );
  Future<void> _resolve(bool accept) async {
    await ref.read(disputesProvider.notifier).resolve(widget.dispute.id, accept, reason.text);
    if (mounted) context.go('/disputes');
  }
}

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(customersProvider);
    return Scaffold(appBar: AppBar(title: const Text('Customer Management')), body: value.when(loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => ErrorPanel(message: e.toString()), data: (page) => AdminDataTable<CustomerProfile>(items: page.items, columns: const [DataColumn(label: Text('Nama')), DataColumn(label: Text('HP')), DataColumn(label: Text('Order')), DataColumn(label: Text('Total Spend'))], cells: (c) => [DataCell(Text(c.name)), DataCell(Text(c.phone)), DataCell(Text('${c.totalOrders}')), DataCell(Text(money(c.totalSpent)))])));
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(notificationsProvider);
    return Scaffold(appBar: AppBar(title: const Text('Notification Center')), body: value.when(loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => ErrorPanel(message: e.toString()), data: (page) => ListView(children: [for (final item in page.items) ListTile(leading: Icon(item.isRead ? Icons.mark_email_read_outlined : Icons.notifications_active_outlined), title: Text(item.title), subtitle: Text('${item.message}\n${dateText(item.createdAt)}'))])));
  }
}

class StoreSettingsScreen extends ConsumerWidget {
  const StoreSettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(storeProfileProvider);
    return Scaffold(appBar: AppBar(title: const Text('Store Profile')), body: profile.when(loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => ErrorPanel(message: e.toString()), data: (data) => ListView(padding: const EdgeInsets.all(16), children: [for (final entry in data.entries) ListTile(title: Text(entry.key), subtitle: Text(entry.value.toString()))])));
  }
}

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(analyticsProvider);
    return StoreAdminScaffold(
      title: 'Analytics',
      selectedIndex: 4,
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorPanel(message: e.toString()),
        data: (data) => ListView(padding: const EdgeInsets.all(16), children: [
          _MetricGrid(cards: [
            MetricCard(title: 'Revenue', value: money(data.revenueMonth), icon: Icons.payments_outlined),
            MetricCard(title: 'Orders', value: '${data.activeOrders + data.pendingOrders}', icon: Icons.receipt_long_outlined),
            MetricCard(title: 'Completion', value: '${data.completionRate.toStringAsFixed(1)}%', icon: Icons.task_alt_outlined),
            MetricCard(title: 'Rating', value: data.ratingAvg.toStringAsFixed(1), icon: Icons.star_outline),
          ]),
          SimpleBarChart(title: 'Order Trends', items: data.ordersTrend.map((e) => CategoryMetric(e.label, e.value)).toList()),
          SimpleBarChart(title: 'Popular Services', items: data.serviceCategories),
          SimpleBarChart(title: 'Sparepart Usage', items: data.sparepartConsumption),
        ]),
      ),
    );
  }
}

class _PagedTableScreen<T> extends StatelessWidget {
  const _PagedTableScreen({required this.title, required this.selectedIndex, required this.value, required this.columns, required this.cells, this.onTap});
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
        body: value.when(loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => ErrorPanel(message: e.toString()), data: (page) => AdminDataTable<T>(items: page.items, columns: columns, cells: cells, onTap: onTap)),
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows});
  final String title;
  final Map<String, String> rows;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8), for (final row in rows.entries) Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [SizedBox(width: 120, child: Text(row.key)), Expanded(child: Text(row.value))]))])));
}

class _CredentialCard extends StatelessWidget {
  const _CredentialCard({required this.panel});
  final CredentialPanel panel;
  @override
  Widget build(BuildContext context) => Card(
        color: panel.hasCredential ? Theme.of(context).colorScheme.tertiaryContainer : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(panel.hasCredential ? 'Pelanggan Baru - Kirim via WA' : 'Kredensial sudah terkirim atau expired', style: Theme.of(context).textTheme.titleMedium),
            Text('HP: ${panel.phoneNumber}'),
            if (panel.password != null) Text('Password: ${panel.password}'),
            if (panel.expiresAt != null) Text('Berlaku s/d: ${dateText(panel.expiresAt!)}'),
          ]),
        ),
      );
}
