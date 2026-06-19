import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/store_admin_providers.dart';

class StoreLoginScreen extends ConsumerStatefulWidget {
  const StoreLoginScreen({super.key});
  @override
  ConsumerState<StoreLoginScreen> createState() => _StoreLoginScreenState();
}

class _StoreLoginScreenState extends ConsumerState<StoreLoginScreen> {
  final phone = TextEditingController();
  final password = TextEditingController();
  bool obscure = true;

  String _parseError(Object? error) {
    final msg = error?.toString() ?? 'Terjadi kesalahan.';
    if (msg.contains('InvalidCredentialsException') || msg.contains('INVALID_CREDENTIALS')) return 'Nomor HP atau password salah.';
    if (msg.contains('StoreNotActiveException') || msg.contains('STORE_NOT_ACTIVE')) return 'Toko tidak aktif.';
    if (msg.contains('AccountLockedException') || msg.contains('ACCOUNT_LOCKED')) return 'Akun terkunci sementara.';
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(storeAuthControllerProvider);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('ServisGadget - Portal Toko', style: Theme.of(context).textTheme.headlineSmall),
                const Text('Masuk sebagai Admin Toko'),
                const SizedBox(height: 24),
                TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Nomor HP', prefixText: '08')),
                const SizedBox(height: 12),
                TextField(controller: password, obscureText: obscure, decoration: InputDecoration(labelText: 'Password', suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
                const SizedBox(height: 18),
                FilledButton.icon(onPressed: auth.isLoading ? null : () => ref.read(storeAuthControllerProvider.notifier).login('08${phone.text.trim()}', password.text), icon: const Icon(Icons.login), label: const Text('Masuk')),
                if (auth.hasError) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_parseError(auth.error), style: TextStyle(color: Theme.of(context).colorScheme.error))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
