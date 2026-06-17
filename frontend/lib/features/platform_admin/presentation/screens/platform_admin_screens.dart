import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/platform_admin_providers.dart';
import '../../../../core/widgets/address_dropdowns.dart';

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
      await ref.read(adminAuthProvider.notifier).login(_username.text.trim(), _password.text);
      if (!mounted) return;
      context.go('/admin/dashboard');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username atau password salah.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Admin Platform', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _username,
                    decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Masuk'),
                    ),
                  ),
                ]),
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
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
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
    if (_storeName.text.trim().length < 3) errors.add('Nama Toko minimal 3 karakter');

    if (!(_addressKey.currentState?.isValid ?? false)) errors.add('Alamat belum lengkap (Provinsi s/d Kelurahan)');

    if (_storePhone.text.trim().isEmpty) errors.add('No HP Toko wajib diisi');
    if (_storePhone.text.trim().length < 8) errors.add('No HP Toko minimal 8 digit');

    if (_adminName.text.trim().isEmpty) errors.add('Nama Admin Toko wajib diisi');

    if (_adminPhone.text.trim().isEmpty) errors.add('No HP Admin wajib diisi');
    if (_adminPhone.text.trim().length < 8) errors.add('No HP Admin minimal 8 digit');

    if (_password.text.isEmpty) errors.add('Password wajib diisi');
    if (_password.text.length < 8) errors.add('Password minimal 8 karakter');

    if (!_android && !_ios) errors.add('Pilih minimal 1 tipe perangkat');

    return errors;
  }

  void _check() {
    final errors = _validate();
    setState(() {
      _validationErrors = errors;
      _validated = true;
    });

    if (errors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua data valid! Siap disimpan.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${errors.length} data belum valid.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  String get _previewAddress => _addressKey.currentState?.addressString ?? '(belum diisi)';

  Future<void> _create() async {
    final errors = _validate();
    if (errors.isNotEmpty) {
      setState(() {
        _validationErrors = errors;
        _validated = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Periksa kembali: ${errors.first}')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Toko berhasil dibuat!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      String msg = 'Gagal menyimpan.';
      if (e.toString().contains('DioException')) {
        final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(e.toString());
        if (match != null) msg = match.group(1)!;
        else msg = 'Gagal: cek isi form atau hubungi admin.';
      } else {
        msg = 'Gagal: $e';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stores = ref.watch(storeListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Platform'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(adminAuthProvider.notifier).logout();
              if (mounted) context.go('/admin/login');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() {
          _showCreate = !_showCreate;
          _validated = false;
          _validationErrors = [];
        }),
        icon: Icon(_showCreate ? Icons.close : Icons.add),
        label: Text(_showCreate ? 'Batal' : 'Buat Toko'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_showCreate) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Buat Toko Baru', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),

                  TextField(controller: _storeName, decoration: const InputDecoration(labelText: 'Nama Toko', isDense: true)),
                  const SizedBox(height: 16),

                  Text('Alamat', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  AddressDropdowns(key: _addressKey),
                  const SizedBox(height: 16),

                  TextField(controller: _storePhone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'No HP Toko', prefixText: '08', isDense: true)),
                  const SizedBox(height: 16),
                  const Divider(),
                  Text('Admin Toko', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextField(controller: _adminName, decoration: const InputDecoration(labelText: 'Nama Admin Toko', isDense: true)),
                  const SizedBox(height: 12),
                  TextField(controller: _adminPhone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'No HP Admin (untuk login)', prefixText: '08', isDense: true)),
                  const SizedBox(height: 12),
                  TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password Admin Toko', isDense: true, helperText: 'Min 8 karakter')),
                  const SizedBox(height: 16),
                  const Divider(),
                  Text('Tipe Perangkat', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Row(children: [
                    FilterChip(label: const Text('Android'), selected: _android, onSelected: (v) => setState(() { _android = v; _validated = false; })),
                    const SizedBox(width: 8),
                    FilterChip(label: const Text('iPhone / iOS'), selected: _ios, onSelected: (v) => setState(() { _ios = v; _validated = false; })),
                  ]),

                  if (_validated && _validationErrors.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.error, color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Text('Yang perlu diperbaiki:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                          ]),
                          const SizedBox(height: 4),
                          ..._validationErrors.map((e) => Padding(
                            padding: const EdgeInsets.only(left: 26, top: 2),
                            child: Text('- $e', style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                          )),
                        ],
                      ),
                    ),
                  ],

                  if (_validated && _validationErrors.isEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 18),
                            const SizedBox(width: 8),
                            Text('Semua data valid!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                          ]),
                          const SizedBox(height: 8),
                          _previewRow('Nama Toko', _storeName.text.trim()),
                          _previewRow('Alamat', _previewAddress),
                          _previewRow('HP Toko', '08${_storePhone.text.trim()}'),
                          _previewRow('Admin', _adminName.text.trim()),
                          _previewRow('HP Admin', '08${_adminPhone.text.trim()}'),
                          _previewRow('Perangkat', '${_android ? "Android " : ""}${_ios ? "iOS" : ""}'),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : _check,
                        icon: const Icon(Icons.fact_check),
                        label: const Text('Cek Data'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: (_loading || !_validated || _validationErrors.isNotEmpty) ? null : _create,
                        icon: _loading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save),
                        label: const Text('Buat Toko'),
                      ),
                    ),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text('Daftar Toko', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          stores.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Gagal memuat: $e'),
            data: (list) => list.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Belum ada toko.'),
                  )
                : Column(
                    children: list.map((store) {
                      final types = store.deviceTypes;
                      final android = types?['android'] as bool? ?? true;
                      final ios = types?['ios'] as bool? ?? true;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(store.storeName, style: theme.textTheme.titleSmall),
                            Text(store.address, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Chip(label: Text('Android', style: TextStyle(fontSize: 11, color: android ? Colors.green : Colors.red)), backgroundColor: android ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1)),
                              const SizedBox(width: 4),
                              Chip(label: Text('iOS', style: TextStyle(fontSize: 11, color: ios ? Colors.green : Colors.red)), backgroundColor: ios ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1)),
                              const Spacer(),
                              Row(children: [const Icon(Icons.star, size: 14, color: Colors.amber), const SizedBox(width: 2), Text(store.ratingAvg.toStringAsFixed(1), style: theme.textTheme.bodySmall)]),
                            ]),
                            if (store.admins.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('Admin: ${store.admins.map((a) => a['fullName']).join(', ')}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                              ),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(left: 26, top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
