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

  String _parseError(Object? error) {
    final msg = error?.toString() ?? 'Terjadi kesalahan.';
    if (msg.contains('InvalidCredentialsException') || msg.contains('INVALID_CREDENTIALS')) return 'Nomor HP atau password salah.';
    if (msg.contains('StoreNotActiveException') || msg.contains('STORE_NOT_ACTIVE')) return 'Toko tidak aktif.';
    if (msg.contains('AccountLockedException') || msg.contains('ACCOUNT_LOCKED')) return 'Akun terkunci sementara.';
    return msg;
  }

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
                TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Nomor HP', prefixText: '08')),
                const SizedBox(height: 12),
                TextField(controller: password, obscureText: obscure, decoration: InputDecoration(labelText: 'Password', suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
                const SizedBox(height: 18),
                FilledButton.icon(onPressed: auth.isLoading ? null : () => ref.read(storeAuthControllerProvider.notifier).login('08${phone.text.trim()}', password.text), icon: const Icon(Icons.login), label: const Text('Masuk')),
                if (auth.hasError) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_parseError(auth.error), style: TextStyle(color: Theme.of(context).colorScheme.error))),
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
  final confirmPassword = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    if (oldPassword.text.isEmpty || newPassword.text.isEmpty) return;
    if (newPassword.text.length < 8) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password baru minimal 8 karakter.')));
      return;
    }
    if (newPassword.text != confirmPassword.text) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konfirmasi password tidak cocok.')));
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(storeAuthControllerProvider.notifier).changePassword(oldPassword.text, newPassword.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password berhasil diubah.')));
        context.go('/store/dashboard');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
                TextField(controller: newPassword, obscureText: true, decoration: const InputDecoration(labelText: 'Password baru', helperText: 'Minimal 8 karakter')),
                const SizedBox(height: 12),
                TextField(controller: confirmPassword, obscureText: true, decoration: const InputDecoration(labelText: 'Konfirmasi password baru')),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.lock_reset),
                  label: const Text('Simpan Password'),
                ),
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
            MetricCard(title: 'Orders', value: '${data.todayOrders}', subtitle: '${data.activeOrders} aktif', icon: Icons.receipt_long_outlined, onTap: () => context.go('/store/orders')),
            MetricCard(title: 'Customers', value: '${data.customers}', subtitle: 'Profil pelanggan', icon: Icons.groups_outlined, onTap: () => context.go('/store/customers')),
            MetricCard(title: 'Reviews', value: data.ratingAvg.toStringAsFixed(1), subtitle: 'Rata-rata rating', icon: Icons.star_border, onTap: () => context.go('/store/reviews')),
            MetricCard(title: 'Pending Payment', value: '${data.pendingPayments}', subtitle: 'Butuh verifikasi', icon: Icons.fact_check_outlined, onTap: () => context.go('/store/payments')),
            MetricCard(title: 'Active Disputes', value: '${data.activeDisputes}', subtitle: 'Klaim terbuka', icon: Icons.gavel_outlined, onTap: () => context.go('/store/disputes')),
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
            onTap: (o) => context.go('/store/orders/${o.id}'),
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
              onTap: (o) => context.go('/store/orders/${o.id}'),
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
      appBar: AppBar(title: const Text('Detail Order'), actions: [IconButton(onPressed: () => context.go('/store/orders/$orderId/tracking'), icon: const Icon(Icons.timeline), tooltip: 'Tracking')]),
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
          OrderActionPanel(order: o, onAction: (action) => action == 'submit_diagnosis' ? context.go('/store/orders/$orderId/diagnosis') : ref.read(storeOrdersProvider.notifier).runAction(orderId, action)),
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
  bool _loading = false;

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
          FilledButton.icon(
            onPressed: _loading ? null : () async {
              setState(() => _loading = true);
              try {
                await ref.read(storeOrdersProvider.notifier).submitDiagnosis(widget.orderId, {
                  'deviceCondition': condition.text,
                  'damageNotes': damage.text,
                  'repairNotes': repair.text,
                  'technicianNotes': technician.text,
                  'estimatedCost': num.tryParse(estimatedCost.text) ?? 0,
                  'estimatedDuration': estimatedDuration.text,
                  'diagnosisItems': <Map<String, Object?>>[],
                  'serviceFee': num.tryParse(estimatedCost.text) ?? 0,
                });
                if (context.mounted) context.go('/store/orders/${widget.orderId}');
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
            icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_outlined),
            label: const Text('Submit Diagnosis'),
          ),
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
  late Future<List<TrackingEvent>> _trackingFuture;

  @override
  void initState() {
    super.initState();
    _trackingFuture = ref.read(storeOperationsRepositoryProvider).tracking(widget.orderId);
  }

  void _refresh() {
    setState(() {
      _trackingFuture = ref.read(storeOperationsRepositoryProvider).tracking(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(storeOperationsRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tracking Timeline')),
      body: FutureBuilder<List<TrackingEvent>>(
        future: _trackingFuture,
        builder: (context, snapshot) => ListView(padding: const EdgeInsets.all(16), children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: 'Judul event')),
          TextField(controller: note, decoration: const InputDecoration(labelText: 'Catatan')),
          FilledButton.icon(
            onPressed: () async {
              await repo.addTracking(widget.orderId, title.text, note.text, 'progress');
              title.clear();
              note.clear();
              _refresh();
            },
            icon: const Icon(Icons.add),
            label: const Text('Tambah Event'),
          ),
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
    final query = ref.watch(inventoryQueryProvider);
    final brands = ref.watch(brandsProvider);

    return StoreAdminScaffold(
      title: 'Inventori',
      selectedIndex: 2,
      actions: [IconButton(onPressed: () => context.go('/store/inventory/new'), icon: const Icon(Icons.add), tooltip: 'Tambah sparepart')],
      body: Column(children: [
        // Filter bar
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              // Search
              SizedBox(
                width: 200,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari sparepart...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (q) => ref.read(inventoryQueryProvider.notifier).state = query.copyWith(search: q.isEmpty ? null : q, page: 1),
                ),
              ),
              const SizedBox(width: 8),
              // Brand filter
              brands.when(
                data: (list) => DropdownButton<String>(
                  value: query.brand,
                  hint: const Text('Brand'),
                  underline: const SizedBox(),
                  isDense: true,
                  items: [const DropdownMenuItem(value: null, child: Text('Semua Brand'))],
                  onChanged: (v) => ref.read(inventoryQueryProvider.notifier).state = query.copyWith(brand: v, deviceModel: null, page: 1),
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
              // PartType filter
              DropdownButton<String>(
                value: query.partType,
                hint: const Text('Tipe'),
                underline: const SizedBox(),
                isDense: true,
                items: const [
                  DropdownMenuItem(value: null, child: Text('Semua Tipe')),
                  DropdownMenuItem(value: 'screen_replacement', child: Text('Layar')),
                  DropdownMenuItem(value: 'battery_replacement', child: Text('Baterai')),
                  DropdownMenuItem(value: 'charging_port', child: Text('Charging Port')),
                  DropdownMenuItem(value: 'camera', child: Text('Kamera')),
                  DropdownMenuItem(value: 'other', child: Text('Lainnya')),
                ],
                onChanged: (v) => ref.read(inventoryQueryProvider.notifier).state = query.copyWith(partType: v, page: 1),
              ),
            ],
          ),
        ),
        // Table
        Expanded(
          child: data.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => ErrorPanel(message: err.toString(), onRetry: () => ref.invalidate(inventoryProvider)),
            data: (page) => page.items.isEmpty
                ? const Center(child: Text('Belum ada sparepart'))
                : ListView.builder(
                    itemCount: page.items.length,
                    itemBuilder: (context, index) {
                      final s = page.items[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.partName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text('${s.brand} · ${s.deviceModel} · ${s.partTypeLabel}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(money(s.price), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                        const SizedBox(width: 12),
                                        Text('Stok: ${s.availableStock}', style: TextStyle(color: s.isLowStock ? Colors.red : Colors.grey[700], fontSize: 12, fontWeight: s.isLowStock ? FontWeight.w700 : FontWeight.normal)),
                                        if (s.qtyReserved > 0) Text(' (${s.qtyReserved} direservasi)', style: TextStyle(color: Colors.orange[700], fontSize: 11)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Quick stock adjustment
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                      onPressed: s.qty > 0
                                          ? () => ref.read(inventoryProvider.notifier).adjustStock(s.id, -1)
                                          : null,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      padding: const EdgeInsets.all(2),
                                    ),
                                    Text('${s.qty}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                      onPressed: () => ref.read(inventoryProvider.notifier).adjustStock(s.id, 1),
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      padding: const EdgeInsets.all(2),
                                    ),
                                  ],
                                ),
                              ),
                              // Edit button
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => context.go('/store/inventory/${s.id}', extra: s),
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: const EdgeInsets.all(2),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
  String? _selectedBrand;
  String? _selectedDeviceModel;
  String _selectedPartType = 'screen_replacement';
  late final _partName = TextEditingController(text: widget.item?.partName);
  late final _price = TextEditingController(text: widget.item?.price.toString());
  late final _qty = TextEditingController(text: widget.item?.qty.toString());
  final _newBrandController = TextEditingController();
  final _newModelController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedBrand = widget.item?.brand;
    _selectedDeviceModel = widget.item?.deviceModel;
    if (widget.item != null) {
      _selectedPartType = widget.item!.partType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brands = ref.watch(brandsProvider);
    final deviceModels = ref.watch(deviceModelsProvider(_selectedBrand));

    return Scaffold(
      appBar: AppBar(title: Text(widget.item == null ? 'Tambah Sparepart' : 'Edit Sparepart')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Brand
        _buildBrandField(brands),
        const SizedBox(height: 12),
        // Device Model
        _buildModelField(deviceModels),
        const SizedBox(height: 12),
        // Part Type
        DropdownButtonFormField<String>(
          value: _selectedPartType,
          decoration: const InputDecoration(labelText: 'Jenis Sparepart', border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: 'screen_replacement', child: Text('Layar')),
            DropdownMenuItem(value: 'battery_replacement', child: Text('Baterai')),
            DropdownMenuItem(value: 'charging_port', child: Text('Charging Port')),
            DropdownMenuItem(value: 'camera', child: Text('Kamera')),
            DropdownMenuItem(value: 'other', child: Text('Lainnya')),
          ],
          onChanged: (v) => setState(() => _selectedPartType = v!),
        ),
        const SizedBox(height: 12),
        // Part Name
        TextField(controller: _partName, decoration: const InputDecoration(labelText: 'Nama Sparepart', hintText: 'LCD Samsung S24', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        // Price
        TextField(controller: _price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga', prefixText: 'Rp ', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        // Qty (only for new, edit uses +/- on list)
        if (widget.item == null)
          TextField(controller: _qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stok Awal', border: OutlineInputBorder())),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _loading ? null : _submit,
          icon: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_outlined),
          label: Text(widget.item == null ? 'Tambah' : 'Simpan'),
        ),
      ]),
    );
  }

  Widget _buildBrandField(List<String>? brands) {
    final allBrands = [...?brands];
    if (_selectedBrand != null && !allBrands.contains(_selectedBrand)) {
      allBrands.insert(0, _selectedBrand!);
    }

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedBrand,
            decoration: const InputDecoration(labelText: 'Brand', border: OutlineInputBorder()),
            items: allBrands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
            onChanged: (v) {
              setState(() {
                _selectedBrand = v;
                _selectedDeviceModel = null;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => _showAddDialog('Brand', _newBrandController, (val) {
            setState(() => _selectedBrand = val);
            ref.invalidate(brandsProvider);
          }),
        ),
      ],
    );
  }

  Widget _buildModelField(List<String>? models) {
    final allModels = [...?models];
    if (_selectedDeviceModel != null && !allModels.contains(_selectedDeviceModel)) {
      allModels.insert(0, _selectedDeviceModel!);
    }

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedDeviceModel,
            decoration: const InputDecoration(labelText: 'Model Device', border: OutlineInputBorder()),
            items: allModels.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => setState(() => _selectedDeviceModel = v),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: _selectedBrand == null
              ? null
              : () => _showAddDialog('Model Device', _newModelController, (val) {
                  setState(() => _selectedDeviceModel = val);
                  ref.invalidate(deviceModelsProvider(_selectedBrand));
                }),
        ),
      ],
    );
  }

  void _showAddDialog(String title, TextEditingController controller, Function(String) onAdd) {
    controller.clear();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Tambah $title'),
        content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(hintText: 'Nama $title')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                onAdd(val);
                Navigator.pop(c);
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedBrand == null || _selectedDeviceModel == null || _partName.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Brand, Model, dan Nama wajib diisi.')));
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(inventoryProvider.notifier).save({
        'brand': _selectedBrand!,
        'deviceModel': _selectedDeviceModel!,
        'partType': _selectedPartType,
        'partName': _partName.text,
        'price': num.tryParse(_price.text) ?? 0,
        'qty': int.tryParse(_qty.text) ?? 0,
      }, id: widget.item?.id);
      if (context.mounted) context.go('/store/inventory');
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
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
    return Scaffold(
      appBar: AppBar(title: const Text('Review Monitoring')),
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorPanel(message: e.toString()),
        data: (page) => ListView(
          children: [
            for (final r in page.items)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(r.customerName, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text('${r.rating}/5', style: const TextStyle(color: Colors.amber)),
                    ]),
                    if (r.comment.isNotEmpty) Text(r.comment),
                    Text(dateText(r.createdAt), style: Theme.of(context).textTheme.bodySmall),
                    if (r.response != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('Balasan: ${r.response}', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                      ),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
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
        onTap: (d) => context.go('/store/disputes/${d.id}', extra: d),
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
  bool _loading = false;

  Future<void> _resolve(bool accept) async {
    if (reason.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catatan resolusi wajib diisi.')));
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(disputesProvider.notifier).resolve(widget.dispute.id, accept, reason.text);
      if (mounted) context.go('/store/disputes');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.dispute.orderNumber)),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Text(widget.dispute.description),
          const SizedBox(height: 12),
          TextField(controller: reason, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'Catatan resolusi', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          Wrap(spacing: 8, children: [
            FilledButton.icon(onPressed: _loading ? null : () => _resolve(true), icon: const Icon(Icons.check), label: const Text('Terima Klaim')),
            OutlinedButton.icon(onPressed: _loading ? null : () => _resolve(false), icon: const Icon(Icons.close), label: const Text('Tolak Klaim')),
          ]),
        ]),
      );
}

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

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Center')),
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorPanel(message: e.toString()),
        data: (page) => ListView(children: [
          for (final item in page.items)
            ListTile(
              leading: Icon(item.isRead ? Icons.mark_email_read_outlined : Icons.notifications_active_outlined),
              title: Text(item.title),
              subtitle: Text('${item.message}\n${dateText(item.createdAt)}'),
            ),
        ]),
      ),
    );
  }
}

class StoreSettingsScreen extends ConsumerStatefulWidget {
  const StoreSettingsScreen({super.key});
  @override
  ConsumerState<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends ConsumerState<StoreSettingsScreen> {
  final storeName = TextEditingController();
  final address = TextEditingController();
  final phoneNumber = TextEditingController();
  bool _loading = false;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(storeProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Store Profile')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorPanel(message: e.toString()),
        data: (data) {
          if (!_initialized) {
            final store = data['store'] as Map<String, dynamic>? ?? {};
            storeName.text = store['storeName']?.toString() ?? '';
            address.text = store['address']?.toString() ?? '';
            phoneNumber.text = store['phoneNumber']?.toString() ?? '';
            _initialized = true;
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(controller: storeName, decoration: const InputDecoration(labelText: 'Nama Toko')),
              const SizedBox(height: 12),
              TextField(controller: address, maxLines: 2, decoration: const InputDecoration(labelText: 'Alamat')),
              const SizedBox(height: 12),
              TextField(controller: phoneNumber, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'No HP')),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loading ? null : () async {
                  setState(() => _loading = true);
                  try {
                    await ref.read(storeOperationsRepositoryProvider).updateStoreProfile({
                      'storeName': storeName.text,
                      'address': address.text,
                      'phoneNumber': phoneNumber.text,
                    });
                    ref.invalidate(storeProfileProvider);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil toko berhasil diupdate.')));
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
                icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_outlined),
                label: const Text('Simpan Perubahan'),
              ),
            ],
          );
        },
      ),
    );
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
            if (panel.password != null) Text('Password: ${"*" * 8}'),
            if (panel.expiresAt != null) Text('Berlaku s/d: ${dateText(panel.expiresAt!)}'),
          ]),
        ),
      );
}
