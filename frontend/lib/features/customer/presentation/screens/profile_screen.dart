import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/customer_providers.dart';
import '../../data/customer_repositories.dart';
import '../widgets/customer_widgets.dart';


class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  bool _dirty = false;
  bool _loading = false;

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(customerAuthProvider.notifier)
          .updateProfile(fullName: _name.text, address: _address.text);
      setState(() => _dirty = false);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = ref.watch(customerAuthProvider).valueOrNull;
    if (user != null && !_dirty && _name.text.isEmpty) {
      _name.text = user.fullName;
      _address.text = user.address ?? '';
    }
    return CustomerScaffold(
      title: 'Profil',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              (user?.fullName.isNotEmpty ?? false) ? user!.fullName[0] : 'S',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: scheme.primary),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                      onChanged: (_) => setState(() => _dirty = true)),
                  const SizedBox(height: 16),
                  TextFormField(
                      initialValue: user?.phoneNumber ?? '-',
                      readOnly: true,
                      decoration: const InputDecoration(
                          labelText: 'Nomor HP (tidak bisa diubah)')),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: _address,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Alamat'),
                      onChanged: (_) => setState(() => _dirty = true)),
                  if (_dirty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                          onPressed: _loading ? null : _save, child: const Text('Simpan')),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: const Text('Pesanan Saya'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/orders')),
                const Divider(height: 1),
                ListTile(
                    leading: const Icon(Icons.local_offer_outlined),
                    title: const Text('Kupon Saya'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/coupons')),
                const Divider(height: 1),
                ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: const Text('Preferensi Notifikasi'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/notification-preferences')),
                const Divider(height: 1),
                ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Ganti Password'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/change-password')),
                const Divider(height: 1),
                ListTile(
                    leading: const Icon(Icons.devices_outlined),
                    title: const Text('Sesi Login'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/sessions')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFEF4444)),
              title: const Text('Logout', style: TextStyle(color: Color(0xFFEF4444))),
              onTap: () async {
                await ref.read(customerAuthProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
