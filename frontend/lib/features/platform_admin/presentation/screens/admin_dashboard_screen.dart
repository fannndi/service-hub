import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:m3_expressive/m3_expressive.dart';
import '../../application/platform_admin_providers.dart';
import '../../domain/platform_admin_models.dart';
import '../../../../core/supabase_service.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../ui/widgets/servis_snackbar.dart';
import '../../../../ui/theme/app_spacing.dart';
import '../../../../ui/widgets/modern_card.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  @override void initState() { super.initState(); _tabCtrl = TabController(length: 3, vsync: this); }
  @override void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _broadcast() async {
    final roleCtrl = TextEditingController(text: 'customer');
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    bool loading = false;
    if (!mounted) return;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
      title: Text(context.l10n.broadcastNotification),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(value: 'customer', decoration: InputDecoration(labelText: context.l10n.target, isDense: true),
          items: [DropdownMenuItem(value: 'customer', child: Text(context.l10n.allCustomers)), DropdownMenuItem(value: 'store_admin', child: Text(context.l10n.allStoreAdmins))],
          onChanged: (v) => setD(() => roleCtrl.text = v ?? 'customer')),
        const SizedBox(height: 8),
        TextField(controller: titleCtrl, decoration: InputDecoration(labelText: context.l10n.title, isDense: true)),
        const SizedBox(height: 8),
        TextField(controller: msgCtrl, maxLines: 3, decoration: InputDecoration(labelText: context.l10n.message, isDense: true)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.cancel)),
        FilledButton(onPressed: loading ? null : () async {
          setD(() => loading = true);
          try {
            await SupabaseService.instance.invoke('notifications', body: {'action': 'broadcast', 'target_role': roleCtrl.text, 'title': titleCtrl.text.trim(), 'message': msgCtrl.text.trim()});
            if (ctx.mounted) Navigator.pop(ctx);
            if (mounted) showServisSnackbar(context, context.l10n.broadcastSent, type: SnackbarType.success);
          } catch (_) { if (mounted) showServisSnackbar(context, 'Gagal', type: SnackbarType.error); } finally { setD(() => loading = false); }
        }, child: Text(context.l10n.send)),
      ],
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.platformAdmin),
        actions: [
          IconButton(icon: const Icon(Icons.campaign_outlined), onPressed: _broadcast),
          IconButton(icon: const Icon(Icons.logout), onPressed: () async {
            await ref.read(adminAuthProvider.notifier).logout();
            if (mounted) context.go('/admin/login');
          }),
        ],
        bottom: TabBar(controller: _tabCtrl, tabs: [
          Tab(icon: const Icon(Icons.assignment), text: 'Applications'),
          Tab(icon: const Icon(Icons.store), text: context.l10n.stores),
          Tab(icon: const Icon(Icons.people), text: context.l10n.customers),
        ]),
      ),
      body: TabBarView(controller: _tabCtrl, children: const [
        _ApplicationsTab(),
        _StoresTab(),
        _CustomersTab(),
      ]),
    );
  }
}

// ─── APPLICATIONS TAB ───
class _ApplicationsTab extends ConsumerStatefulWidget {
  const _ApplicationsTab();
  @override ConsumerState<_ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends ConsumerState<_ApplicationsTab> {
  List<Map<String, dynamic>>? _apps;
  bool _loading = true;

  @override void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final result = await SupabaseService.instance.invoke('admin', body: {'action': 'applications'});
      _apps = (result as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) { _apps = []; }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _approve(Map<String, dynamic> app) async {
    final pwCtrl = TextEditingController();
    bool loading = false;
    if (!mounted) return;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
      title: const Text('Setujui Toko'),
      content: TextField(controller: pwCtrl, decoration: const InputDecoration(labelText: 'Password Admin', isDense: true), obscureText: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        FilledButton(onPressed: loading ? null : () async {
          if (pwCtrl.text.length < 6) return;
          setD(() => loading = true);
          try {
            await SupabaseService.instance.invoke('admin', body: {'action': 'approve', 'application_id': app['id'], 'password': pwCtrl.text});
            if (ctx.mounted) Navigator.pop(ctx);
            if (mounted) { showServisSnackbar(context, 'Toko disetujui!', type: SnackbarType.success); _fetch(); }
          } catch (e) { if (mounted) showServisSnackbar(context, 'Gagal: $e', type: SnackbarType.error); }
          finally { setD(() => loading = false); }
        }, child: const Text('Setujui')),
      ],
    )));
  }

  Future<void> _reject(String id) async {
    try {
      await SupabaseService.instance.invoke('admin', body: {'action': 'reject', 'application_id': id});
      if (mounted) showServisSnackbar(context, 'Ditolak', type: SnackbarType.success);
      _fetch();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_loading) return const Center(child: M3LoadingIndicator());
    if (_apps == null || _apps!.isEmpty) return const Center(child: Text('Belum ada aplikasi masuk.'));
    return M3RefreshIndicator(
      onRefresh: _fetch,
      child: ListView(padding: const EdgeInsets.all(12), children: _apps!.where((a) => a['status'] == 'pending').map((app) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ModernCard(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(app['store_name'] as String? ?? '', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(app['address'] as String? ?? '', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
            Text('${app['phone_number']}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Admin: ${app['applicant_name']}', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              OutlinedButton.icon(onPressed: () => _reject(app['id'] as String), icon: const Icon(Icons.close, size: 16), label: const Text('Tolak')),
              const SizedBox(width: 8),
              FilledButton.icon(onPressed: () => _approve(app), icon: const Icon(Icons.check, size: 16), label: const Text('Setujui')),
            ]),
          ]),
        ),
      )).toList()),
    );
  }
}

// ─── STORES TAB ───
class _StoresTab extends ConsumerStatefulWidget {
  const _StoresTab();
  @override ConsumerState<_StoresTab> createState() => _StoresTabState();
}

class _StoresTabState extends ConsumerState<_StoresTab> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final stores = ref.watch(storeListProvider);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(context.l10n.storeList, style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
        stores.when(
          loading: () => const Center(child: M3LoadingIndicator()),
        error: (e, _) => Text('Gagal: $e'),
        data: (list) => list.isEmpty
            ? const Padding(padding: EdgeInsets.all(16), child: Text('Belum ada toko.'))
            : Column(children: list.map((store) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ModernCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(store.storeName, style: theme.textTheme.titleSmall)),
                      IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _editStore(store)),
                    ]),
                    Text(store.address, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                    Text(store.phoneNumber, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                  ]),
                ),
              )).toList()),
      ),
    ]);
  }

  void _editStore(StoreListItem store) {
    final nameCtrl = TextEditingController(text: store.storeName);
    final addrCtrl = TextEditingController(text: store.address);
    final phoneCtrl = TextEditingController(text: store.phoneNumber);
    final adminNameCtrl = TextEditingController(text: store.admins.isNotEmpty ? store.admins.first['fullName'] as String? ?? '' : '');
    final adminPwCtrl = TextEditingController();
    final adminId = store.admins.isNotEmpty ? store.admins.first['id'] as String? : null;

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Edit Toko'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Toko', isDense: true)),
        const SizedBox(height: 8),
        TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Alamat', isDense: true)),
        const SizedBox(height: 8),
        TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'No HP', isDense: true)),
        const Divider(),
        TextField(controller: adminNameCtrl, decoration: const InputDecoration(labelText: 'Nama Admin', isDense: true)),
        const SizedBox(height: 8),
        TextField(controller: adminPwCtrl, decoration: const InputDecoration(labelText: 'Password Baru (opsional)', isDense: true), obscureText: true),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.cancel)),
        FilledButton(onPressed: () async {
          try {
            await SupabaseService.instance.invoke('admin', body: {'action': 'update-store', 'store_id': store.id, 'store_name': nameCtrl.text.trim(), 'address': addrCtrl.text.trim(), 'phone_number': phoneCtrl.text.trim()});
            if (adminNameCtrl.text.trim().isNotEmpty && adminId != null) {
              final Map<String, dynamic> body = {'action': 'update-admin', 'admin_id': adminId, 'full_name': adminNameCtrl.text.trim()};
              if (adminPwCtrl.text.trim().length >= 6) body['password'] = adminPwCtrl.text.trim();
              await SupabaseService.instance.invoke('admin', body: body);
            }
            ref.invalidate(storeListProvider);
            if (ctx.mounted) Navigator.pop(ctx);
            if (mounted) showServisSnackbar(context, 'Toko diupdate!', type: SnackbarType.success);
          } catch (e) { if (mounted) showServisSnackbar(context, 'Gagal: $e', type: SnackbarType.error); }
        }, child: Text(context.l10n.save)),
      ],
    ));
  }
}

// ─── CUSTOMERS TAB ───
class _CustomersTab extends ConsumerStatefulWidget {
  const _CustomersTab();
  @override ConsumerState<_CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends ConsumerState<_CustomersTab> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final users = ref.watch(userListProvider);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(context.l10n.customerList, style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
        users.when(
          loading: () => const Center(child: M3LoadingIndicator()),
        error: (e, _) => Text('Gagal: $e'),
        data: (list) => list.isEmpty
            ? Padding(padding: const EdgeInsets.all(16), child: Text(context.l10n.noCustomers))
            : Column(children: list.map((u) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ModernCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(u.fullName, style: theme.textTheme.titleSmall)),
                      IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _editUser(u)),
                    ]),
                    Text(u.phoneNumber, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                    if (u.address != null && u.address!.isNotEmpty) Text(u.address!, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                  ]),
                ),
              )).toList()),
      ),
    ]);
  }

  void _editUser(UserListItem user) {
    final nameCtrl = TextEditingController(text: user.fullName);
    final phoneCtrl = TextEditingController(text: user.phoneNumber);
    final addrCtrl = TextEditingController(text: user.address ?? '');
    final pwCtrl = TextEditingController();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(context.l10n.editCustomer),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: InputDecoration(labelText: context.l10n.name, isDense: true)),
        const SizedBox(height: 8),
        TextField(controller: phoneCtrl, decoration: InputDecoration(labelText: context.l10n.phoneNumber, isDense: true)),
        const SizedBox(height: 8),
        TextField(controller: addrCtrl, decoration: InputDecoration(labelText: context.l10n.address, isDense: true), maxLines: 2),
        const SizedBox(height: 8),
        TextField(controller: pwCtrl, decoration: InputDecoration(labelText: context.l10n.newPasswordOptional, isDense: true), obscureText: true),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.cancel)),
        FilledButton(onPressed: () async {
          try {
            await SupabaseService.instance.invoke('admin', body: {'action': 'update-customer', 'user_id': user.id, 'full_name': nameCtrl.text.trim(), 'phone_number': phoneCtrl.text.trim(), 'address': addrCtrl.text.trim(), if (pwCtrl.text.length >= 6) 'password': pwCtrl.text.trim()});
            ref.invalidate(userListProvider);
            if (ctx.mounted) Navigator.pop(ctx);
            if (mounted) showServisSnackbar(context, context.l10n.customerUpdated, type: SnackbarType.success);
          } catch (e) { if (mounted) showServisSnackbar(context, 'Gagal: $e', type: SnackbarType.error); }
        }, child: Text(context.l10n.save)),
      ],
    ));
  }
}
