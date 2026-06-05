import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/demo_account.dart';
import '../auth/demo_auth_controller.dart';

class DemoLoginScreen extends ConsumerStatefulWidget {
  const DemoLoginScreen({super.key});

  @override
  ConsumerState<DemoLoginScreen> createState() => _DemoLoginScreenState();
}

class _DemoLoginScreenState extends ConsumerState<DemoLoginScreen> {
  DemoRole _role = DemoRole.customer;
  final _phoneController = TextEditingController(text: demoCustomerAccount.phone);
  final _passwordController = TextEditingController(text: demoCustomerAccount.password);

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setRole(DemoRole role) {
    final account = role == DemoRole.customer ? demoCustomerAccount : demoStoreAdminAccount;
    setState(() {
      _role = role;
      _phoneController.text = account.phone;
      _passwordController.text = account.password;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(demoAuthProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('ServisGadget')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Dummy Login', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Partial Phase 02/03. Lokal dulu, nanti sambung Supabase/API.'),
            const SizedBox(height: 24),
            SegmentedButton<DemoRole>(
              segments: const [
                ButtonSegment(value: DemoRole.customer, label: Text('Customer')),
                ButtonSegment(value: DemoRole.storeAdmin, label: Text('Admin Toko')),
              ],
              selected: {_role},
              onSelectionChanged: (value) => _setRole(value.first),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Nomor HP', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
            ),
            if (auth.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(auth.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => ref.read(demoAuthProvider.notifier).login(
                    role: _role,
                    phone: _phoneController.text,
                    password: _passwordController.text,
                  ),
              child: const Text('Masuk'),
            ),
            TextButton(
              onPressed: () => ref.read(demoAuthProvider.notifier).loginAsDemo(_role),
              child: const Text('Masuk cepat sebagai dummy'),
            ),
            const SizedBox(height: 24),
            const _CredentialCard(account: demoCustomerAccount),
            const SizedBox(height: 12),
            const _CredentialCard(account: demoStoreAdminAccount),
          ],
        ),
      ),
    );
  }
}

class _CredentialCard extends StatelessWidget {
  const _CredentialCard({required this.account});

  final DemoAccount account;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(account.label, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('HP: ${account.phone}'),
            Text('Password: ${account.password}'),
            if (account.storeName != null) Text('Toko: ${account.storeName}'),
          ],
        ),
      ),
    );
  }
}
