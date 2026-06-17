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

  @override
  void dispose() {
    _storeName.dispose();
    _storePhone.dispose();
    _adminName.dispose();
    _adminPhone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final addressDropdown = _addressKey.currentState!;
    if (!addressDropdown.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi alamat (Provinsi s/d Kelurahan).')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(adminRepositoryProvider).createStore(
            storeName: _storeName.text.trim(),
            address: addressDropdown.addressString,
            storePhone: _storePhone.text.trim(),
            adminName: _adminName.text.trim(),
            adminPhone: _adminPhone.text.trim(),
            password: _password.text,
            handlesAndroid: _android,
            handlesIos: _ios,
          );
      ref.invalidate(storeListProvider);
      setState(() {
        _showCreate = false;
        _storeName.clear();
        _storePhone.clear();
        _adminName.clear();
        _adminPhone.clear();
        _password.clear();
        addressDropdown.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Toko berhasil dibuat!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
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
        onPressed: () => setState(() => _showCreate = !_showCreate),
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
                    FilterChip(label: const Text('Android'), selected: _android, onSelected: (v) => setState(() => _android = v)),
                    const SizedBox(width: 8),
                    FilterChip(label: const Text('iPhone / iOS'), selected: _ios, onSelected: (v) => setState(() => _ios = v)),
                  ]),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _create,
                      child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Buat Toko'),
                    ),
                  ),
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
}
