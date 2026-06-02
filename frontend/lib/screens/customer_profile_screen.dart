import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/demo_auth_controller.dart';
import 'customer_coupons_screen.dart';
import 'change_password_screen.dart';

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(demoAuthProvider).account!;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(account.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(account.phone),
          const SizedBox(height: 24),
          ListTile(leading: const Icon(Icons.confirmation_number_outlined), title: const Text('Kupon Saya'), subtitle: const Text('Dummy: SGREVIEW10'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CustomerCouponsScreen()))),
          ListTile(leading: const Icon(Icons.lock_outline), title: const Text('Ubah Password'), subtitle: const Text('Belum aktif sampai auth backend siap'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen()))),
        ],
      ),
    );
  }
}


