import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/supabase_service.dart';
import 'package:m3_expressive/m3_expressive.dart';

class StoreRegisterScreen extends StatefulWidget {
  const StoreRegisterScreen({super.key});
  @override
  State<StoreRegisterScreen> createState() => _StoreRegisterScreenState();
}

class _StoreRegisterScreenState extends State<StoreRegisterScreen> {
  final _storeName = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _adminName = TextEditingController();
  final _adminPhone = TextEditingController();
  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    _storeName.dispose(); _address.dispose(); _phone.dispose(); _adminName.dispose(); _adminPhone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_storeName.text.trim().isEmpty || _address.text.trim().isEmpty || _phone.text.trim().isEmpty || _adminName.text.trim().isEmpty || _adminPhone.text.trim().isEmpty) {
      setState(() => _message = 'Semua field wajib diisi');
      return;
    }
    setState(() { _loading = true; _message = null; });
    try {
      await SupabaseService.instance.invoke('store-applications', body: {
        'store_name': _storeName.text.trim(),
        'address': _address.text.trim(),
        'phone_number': _phone.text.trim(),
        'admin_name': _adminName.text.trim(),
        'admin_phone': _adminPhone.text.trim(),
      });
      setState(() { _message = 'Pendaftaran berhasil dikirim! Admin akan mengonfirmasi pendaftaran kamu.'; _storeName.clear(); _address.clear(); _phone.clear(); _adminName.clear(); _adminPhone.clear(); });
    } catch (e) {
      setState(() => _message = 'Gagal: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftarkan Toko'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Icon(Icons.store, size: 64),
        const SizedBox(height: 16),
        Text('Daftarkan Toko Anda', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text('Isi data toko dan admin. Admin akan mengonfirmasi pendaftaran.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        TextField(controller: _storeName, decoration: const InputDecoration(labelText: 'Nama Toko', prefixIcon: Icon(Icons.store))),
        const SizedBox(height: 12),
        TextField(controller: _address, maxLines: 2, decoration: const InputDecoration(labelText: 'Alamat', prefixIcon: Icon(Icons.location_on), alignLabelWithHint: true)),
        const SizedBox(height: 12),
        TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'No HP Toko', prefixIcon: Icon(Icons.phone))),
        const SizedBox(height: 12),
        TextField(controller: _adminName, decoration: const InputDecoration(labelText: 'Nama Admin', prefixIcon: Icon(Icons.person))),
        const SizedBox(height: 12),
        TextField(controller: _adminPhone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'No HP Admin (login)', prefixIcon: Icon(Icons.phone_android))),
        const SizedBox(height: 24),
        if (_message != null)
          Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(_message!, style: TextStyle(color: _message!.contains('berhasil') ? Colors.green : Colors.red, fontWeight: FontWeight.w600))),
        FilledButton.icon(
          onPressed: _loading ? null : _submit,
          icon: _loading ? SizedBox(width: 18, height: 18, child: M3LoadingIndicator(size: 20, color: Colors.white)) : const Icon(Icons.send),
          label: Text(_loading ? 'Mengirim...' : 'Kirim Pendaftaran'),
        ),
      ]),
    );
  }
}
