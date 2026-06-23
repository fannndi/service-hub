import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/profile_provider.dart';
import '../widgets/store_admin_widgets.dart';

class StoreSettingsScreen extends ConsumerStatefulWidget {
  const StoreSettingsScreen({super.key});
  @override
  ConsumerState<StoreSettingsScreen> createState() =>
      _StoreSettingsScreenState();
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
              TextField(
                  controller: storeName,
                  decoration: const InputDecoration(labelText: 'Nama Toko')),
              const SizedBox(height: 12),
              TextField(
                  controller: address,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Alamat')),
              const SizedBox(height: 12),
              TextField(
                  controller: phoneNumber,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'No HP')),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loading
                    ? null
                    : () async {
                        setState(() => _loading = true);
                        try {
                          await ref
                              .read(storeProfileRepositoryProvider)
                              .updateProfile({
                            'storeName': storeName.text,
                            'address': address.text,
                            'phoneNumber': phoneNumber.text,
                          });
                          ref.invalidate(storeProfileProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Profil toko berhasil diupdate.')));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Gagal: $e')));
                          }
                        } finally {
                          if (mounted) setState(() => _loading = false);
                        }
                      },
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined),
                label: const Text('Simpan Perubahan'),
              ),
            ],
          );
        },
      ),
    );
  }
}
