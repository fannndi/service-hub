import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/platform_admin_providers.dart';
import '../../../../core/widgets/address_dropdowns.dart';
import '../../domain/platform_admin_models.dart';
import '../../../../ui/theme/app_theme.dart';
import '../../../../ui/widgets/modern_card.dart';
import '../../../../ui/widgets/servis_snackbar.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  Future<void> _submit() async {
    if (_username.text.isEmpty || _password.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(adminAuthProvider.notifier)
          .login(_username.text.trim(), _password.text);
      if (!mounted) return;
      context.go('/admin/dashboard');
    } catch (_) {
      if (mounted) {
        showServisSnackbar(context, 'Username atau password salah.', type: SnackbarType.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: GradientBackground(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.admin_panel_settings,
                          size: 40, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text('Admin Platform',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text('Kelola toko dan pelanggan',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 24),
                  TextField(
                    controller: _username,
                    decoration: const InputDecoration(
                        labelText: 'Username', prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Masuk'),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }
}

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Platform'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(adminAuthProvider.notifier).logout();
              if (context.mounted) context.go('/admin/login');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.store), text: 'Toko'),
            Tab(icon: Icon(Icons.people), text: 'Pelanggan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _StoresTab(),
          _CustomersTab(),
        ],
      ),
    );
  }
}

class _StoresTab extends ConsumerStatefulWidget {
  const _StoresTab();
  @override
  ConsumerState<_StoresTab> createState() => _StoresTabState();
}

class _StoresTabState extends ConsumerState<_StoresTab> {
  final _storeName = TextEditingController();
  final _storePhone = TextEditingController();
  final _adminName = TextEditingController();
  final _adminPhone = TextEditingController();
  final _password = TextEditingController();
  final _addressKey = GlobalKey<AddressDropdownsState>();
  bool _android = true;
  bool _ios = true;
  bool _loading = false;
  bool _showCreate = false;

  List<String> _validationErrors = [];
  bool _validated = false;

  @override
  void dispose() {
    _storeName.dispose();
    _storePhone.dispose();
    _adminName.dispose();
    _adminPhone.dispose();
    _password.dispose();
    super.dispose();
  }

  List<String> _validate() {
    final errors = <String>[];
    if (_storeName.text.trim().isEmpty) errors.add('Nama Toko wajib diisi');
    if (_storeName.text.trim().length < 3) {
      errors.add('Nama Toko minimal 3 karakter');
    }
    if (!(_addressKey.currentState?.isValid ?? false)) {
      errors.add('Alamat belum lengkap (Provinsi s/d Kelurahan)');
    }
    if (_storePhone.text.trim().isEmpty) errors.add('No HP Toko wajib diisi');
    if (_adminName.text.trim().isEmpty) errors.add('Nama Admin wajib diisi');
    if (_adminPhone.text.trim().isEmpty) errors.add('No HP Admin wajib diisi');
    if (_password.text.isEmpty) errors.add('Password wajib diisi');
    if (_password.text.length < 8) errors.add('Password minimal 8 karakter');
    if (!_android && !_ios) errors.add('Pilih minimal 1 tipe perangkat');
    return errors;
  }

  Future<void> _create() async {
    final errors = _validate();
    if (errors.isNotEmpty) {
      setState(() { _validationErrors = errors; _validated = true; });
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(adminRepositoryProvider).createStore(
            storeName: _storeName.text.trim(),
            address: _addressKey.currentState!.addressString,
            storePhone: '08${_storePhone.text.trim()}',
            adminName: _adminName.text.trim(),
            adminPhone: '08${_adminPhone.text.trim()}',
            password: _password.text,
            handlesAndroid: _android,
            handlesIos: _ios,
          );
      ref.invalidate(storeListProvider);
      ref.invalidate(storeAdminListProvider);
      setState(() {
        _showCreate = false;
        _validated = false;
        _validationErrors = [];
        _storeName.clear();
        _storePhone.clear();
        _adminName.clear();
        _adminPhone.clear();
        _password.clear();
        _addressKey.currentState?.clear();
      });
      if (mounted) {
        showServisSnackbar(context, 'Toko berhasil dibuat!', type: SnackbarType.success);
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(Object e) {
    String msg = 'Gagal.';
    if (e.toString().contains('DioException')) {
      final m = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(e.toString());
      msg = m?.group(1) ?? 'Cek isi form.';
    } else { msg = e.toString(); }
    if (mounted) {
      showServisSnackbar(context, msg, type: SnackbarType.error);
    }
  }

  void _editStore(StoreListItem store) {
    final nameCtrl = TextEditingController(text: store.storeName);
    final addrCtrl = TextEditingController(text: store.address);
    final phoneCtrl = TextEditingController(text: store.phoneNumber);
    bool active = true;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Edit Toko'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Toko', isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Alamat', isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'No HP', isDense: true)),
              const SizedBox(height: 8),
              Row(children: [
                const Text('Aktif: '),
                Switch(value: active, onChanged: (v) => setD(() => active = v)),
              ]),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(onPressed: () async {
              try {
                await ref.read(adminRepositoryProvider).updateStore(
                  storeId: store.id,
                  storeName: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
                  address: addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(),
                  phoneNumber: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                  isActive: active,
                );
                ref.invalidate(storeListProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) { _showError(e); }
            }, child: const Text('Simpan')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stores = ref.watch(storeListProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: () => setState(() { _showCreate = !_showCreate; _validated = false; _validationErrors = []; }),
          icon: Icon(_showCreate ? Icons.close : Icons.add),
          label: Text(_showCreate ? 'Batal' : 'Buat Toko Baru'),
        ),
        if (_showCreate) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Buat Toko Baru', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  TextField(controller: _storeName, decoration: const InputDecoration(labelText: 'Nama Toko', isDense: true)),
                  const SizedBox(height: 12),
                  Text('Alamat', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  AddressDropdowns(key: _addressKey),
                  const SizedBox(height: 12),
                  TextField(controller: _storePhone, keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'No HP Toko', prefixText: '08', isDense: true)),
                  const SizedBox(height: 12),
                  const Divider(),
                  Text('Admin Toko', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextField(controller: _adminName, decoration: const InputDecoration(labelText: 'Nama Admin', isDense: true)),
                  const SizedBox(height: 8),
                  TextField(controller: _adminPhone, keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'No HP Admin (login)', prefixText: '08', isDense: true)),
                  const SizedBox(height: 8),
                  TextField(controller: _password,
                    decoration: const InputDecoration(labelText: 'Password Admin', isDense: true, helperText: 'Min 8 karakter')),
                  const SizedBox(height: 12),
                  const Divider(),
                  Text('Tipe Perangkat', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Row(children: [
                    FilterChip(label: const Text('Android'), selected: _android,
                      onSelected: (v) => setState(() { _android = v; _validated = false; })),
                    const SizedBox(width: 8),
                    FilterChip(label: const Text('iPhone / iOS'), selected: _ios,
                      onSelected: (v) => setState(() { _ios = v; _validated = false; })),
                  ]),
                  if (_validated && _validationErrors.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200)),
                      child: Column(children: [
                        Row(children: [const Icon(Icons.error, color: Colors.red, size: 18), const SizedBox(width: 8),
                          Text('Perbaiki:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700))]),
                        ..._validationErrors.map((e) => Padding(
                          padding: const EdgeInsets.only(left: 26, top: 2),
                          child: Text('- $e', style: TextStyle(color: Colors.red.shade700, fontSize: 13)))),
                      ]),
                    ),
                  ],
                  if (_validated && _validationErrors.isEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200)),
                      child: Column(children: [
                        Row(children: [const Icon(Icons.check_circle, color: Colors.green, size: 18),
                          const SizedBox(width: 8), Text('Valid!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700))]),
                        Padding(padding: const EdgeInsets.only(left: 26, top: 4),
                          child: Text('Nama: ${_storeName.text.trim()} | Admin: ${_adminName.text.trim()} | Android: $_android iOS: $_ios', style: const TextStyle(fontSize: 12))),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(onPressed: () { setState(() { _validationErrors = _validate(); _validated = true; }); },
                      icon: const Icon(Icons.fact_check), label: const Text('Cek Data'))),
                    const SizedBox(width: 8),
                    Expanded(child: FilledButton.icon(onPressed: (_loading || !_validated || _validationErrors.isNotEmpty) ? null : _create,
                      icon: _loading ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white))
                        : const Icon(Icons.save), label: const Text('Buat Toko'))),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 8),
        Text('Daftar Toko', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        stores.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Gagal: $e'),
          data: (list) => list.isEmpty
              ? const Padding(padding: EdgeInsets.all(16), child: Text('Belum ada toko.'))
              : Column(children: list.map((store) {
                  final dt = store.deviceTypes;
                  final android = dt?['android'] as bool? ?? true;
                  final ios = dt?['ios'] as bool? ?? true;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(store.storeName, style: theme.textTheme.titleSmall)),
                          IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _editStore(store)),
                        ]),
                        Text(store.address, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                        Text(store.phoneNumber, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Row(children: [
                          Chip(label: Text('Android', style: TextStyle(fontSize: 11, color: android ? AppColors.success : AppColors.error)),
                            backgroundColor: android ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1)),
                          const SizedBox(width: 4),
                          Chip(label: Text('iOS', style: TextStyle(fontSize: 11, color: ios ? AppColors.success : AppColors.error)),
                            backgroundColor: ios ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1)),
                          const Spacer(),
                          Row(children: [const Icon(Icons.star, size: 14, color: AppColors.warning), const SizedBox(width: 2),
                            Text(store.ratingAvg.toStringAsFixed(1), style: theme.textTheme.bodySmall)]),
                        ]),
                        if (store.admins.isNotEmpty)
                          Padding(padding: const EdgeInsets.only(top: 4),
                            child: Text('Admin: ${store.admins.map((a) => a['fullName']).join(', ')}',
                              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary))),
                      ]),
                    ),
                  );
                }).toList()),
        ),
      ],
    );
  }
}

class _CustomersTab extends ConsumerStatefulWidget {
  const _CustomersTab();
  @override
  ConsumerState<_CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends ConsumerState<_CustomersTab> {
  void _editUser(UserListItem user) {
    final nameCtrl = TextEditingController(text: user.fullName);
    final phoneCtrl = TextEditingController(text: user.phoneNumber);
    final addrCtrl = TextEditingController(text: user.address ?? '');
    String status = user.accountStatus;
    final pwCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Pelanggan'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama', isDense: true)),
            const SizedBox(height: 8),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'No HP', isDense: true)),
            const SizedBox(height: 8),
            TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Alamat', isDense: true), maxLines: 2),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'Status', isDense: true),
              items: const [DropdownMenuItem(value: 'active', child: Text('Active')), DropdownMenuItem(value: 'suspended', child: Text('Suspended')), DropdownMenuItem(value: 'deleted', child: Text('Deleted'))],
              onChanged: (v) => status = v ?? 'active',
              borderRadius: const BorderRadius.all(Radius.circular(14)),
            ),
            const Divider(),
            TextField(controller: pwCtrl, decoration: const InputDecoration(labelText: 'Password Baru (kosongkan jika tidak diubah)', isDense: true), obscureText: true),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(onPressed: () async {
            try {
              final repo = ref.read(adminRepositoryProvider);
              await repo.updateUser(
                userId: user.id,
                fullName: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
                phoneNumber: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                address: addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(),
                accountStatus: status,
              );
              if (pwCtrl.text.isNotEmpty && pwCtrl.text.length >= 6) {
                await repo.changeUserPassword(user.id, pwCtrl.text);
              }
              ref.invalidate(userListProvider);
              if (mounted) {
                showServisSnackbar(context, 'Pelanggan diupdate.', type: SnackbarType.success);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            } catch (e) {
              String msg = 'Gagal.';
              if (e.toString().contains('DioException')) {
                final m = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(e.toString());
                msg = m?.group(1) ?? 'Cek isi form.';
              } else { msg = e.toString(); }
              if (mounted) {
                showServisSnackbar(context, msg, type: SnackbarType.error);
              }
            }
          }, child: const Text('Simpan')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final users = ref.watch(userListProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Daftar Pelanggan', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        users.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Gagal: $e'),
          data: (list) => list.isEmpty
              ? const Padding(padding: EdgeInsets.all(16), child: Text('Belum ada pelanggan.'))
              : Column(children: list.map((u) {
                  final isNew = u.isFirstLogin && u.plainPassword != null;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(u.fullName, style: theme.textTheme.titleSmall)),
                          IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _editUser(u)),
                        ]),
                        Row(children: [const Icon(Icons.phone, size: 14, color: AppColors.textSecondary), const SizedBox(width: 4),
                          Text(u.phoneNumber, style: theme.textTheme.bodySmall)]),
                        if (u.plainPassword != null)
                          Row(children: [const Icon(Icons.key, size: 14, color: AppColors.warning), const SizedBox(width: 4),
                            Text('Password: ${u.plainPassword}', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600))]),
                        if (u.address != null && u.address!.isNotEmpty)
                          Text(u.address!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Row(children: [
                          _badge(u.accountStatus),
                          const SizedBox(width: 8),
                          if (isNew)
                            _badge('BARU', AppColors.primary),
                          if (u.isFirstLogin)
                            _badge('first login', AppColors.accent),
                        ]),
                        Text('Bergabung: ${u.createdAt.substring(0, 10)}', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontSize: 11)),
                      ]),
                    ),
                  );
                }).toList()),
        ),
      ],
    );
  }

  Widget _badge(String text, [Color? color]) {
    final c = color ??
        (text == 'active' ? AppColors.success : text == 'suspended' ? AppColors.error : AppColors.textSecondary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
    );
  }
}
