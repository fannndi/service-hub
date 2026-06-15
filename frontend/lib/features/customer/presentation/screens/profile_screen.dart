import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/customer_providers.dart';
import '../../data/customer_repositories.dart';
import '../../domain/customer_models.dart';
import '../../domain/user_session.dart';
import '../../../../shared_widgets/error_state.dart';
import '../../../../shared_widgets/status_badge.dart';
import '../../../../shared_widgets/empty_state.dart';
import '../../../../shared_widgets/formatters.dart';
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
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(customerAuthProvider).valueOrNull;
    if (user != null && !_dirty && _name.text.isEmpty) {
      _name.text = user.fullName;
      _address.text = user.address ?? '';
    }
    return CustomerScaffold(
      title: 'Profil',
      child: ListView(padding: const EdgeInsets.all(16), children: [
        CircleAvatar(
            radius: 44,
            child: Text((user?.fullName.isNotEmpty ?? false)
                ? user!.fullName[0]
                : 'S')),
        const SizedBox(height: 16),
        TextFormField(
            controller: _name,
            decoration: const InputDecoration(
                labelText: 'Nama Lengkap', border: OutlineInputBorder()),
            onChanged: (_) => setState(() => _dirty = true)),
        const SizedBox(height: 12),
        TextFormField(
            initialValue: user?.phoneNumber ?? '-',
            readOnly: true,
            decoration: const InputDecoration(
                labelText: 'Nomor HP (tidak bisa diubah)',
                border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextFormField(
            controller: _address,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
                labelText: 'Alamat', border: OutlineInputBorder()),
            onChanged: (_) => setState(() => _dirty = true)),
        if (_dirty)
          FilledButton(
              onPressed: _loading ? null : _save, child: const Text('Simpan')),
        const Divider(),
        ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Pesanan Saya'),
            onTap: () => context.push('/orders')),
        ListTile(
            leading: const Icon(Icons.local_offer),
            title: const Text('Kupon Saya'),
            onTap: () => context.push('/coupons')),
        ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Preferensi Notifikasi'),
            onTap: () => context.push('/notification-preferences')),
        ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Ganti Password'),
            onTap: () => context.push('/change-password')),
        ListTile(
            leading: const Icon(Icons.devices),
            title: const Text('Sesi Login'),
            onTap: () => context.push('/sessions')),
        ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: () async {
              await ref.read(customerAuthProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            }),
      ]),
    );
  }
}
