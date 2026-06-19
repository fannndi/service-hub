import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    if (msg.contains('InvalidCredentialsException') ||
        msg.contains('INVALID_CREDENTIALS')) {
      return 'Nomor HP atau password salah.';
    }
    if (msg.contains('StoreNotActiveException') ||
        msg.contains('STORE_NOT_ACTIVE')) {
      return 'Toko tidak aktif.';
    }
    if (msg.contains('AccountLockedException') ||
        msg.contains('ACCOUNT_LOCKED')) {
      return 'Akun terkunci sementara.';
    }
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(storeAuthControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                                color: scheme.primaryContainer
                                    .withValues(alpha: .72),
                                borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.storefront_outlined,
                                color: scheme.onPrimaryContainer),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text('Portal Toko',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall),
                                Text('Masuk sebagai admin operasional',
                                    style: TextStyle(
                                        color: scheme.onSurfaceVariant)),
                              ])),
                        ]),
                        const SizedBox(height: 24),
                        TextField(
                            controller: phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                                labelText: 'Nomor HP',
                                prefixIcon: Icon(Icons.phone_outlined),
                                prefixText: '08')),
                        const SizedBox(height: 12),
                        TextField(
                            controller: password,
                            obscureText: obscure,
                            decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                    onPressed: () =>
                                        setState(() => obscure = !obscure),
                                    icon: Icon(obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined)))),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                            onPressed: auth.isLoading
                                ? null
                                : () => ref
                                    .read(storeAuthControllerProvider.notifier)
                                    .login('08${phone.text.trim()}',
                                        password.text),
                            icon: auth.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.2))
                                : const Icon(Icons.login),
                            label: const Text('Masuk')),
                        if (auth.hasError)
                          Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(_parseError(auth.error),
                                  style: TextStyle(color: scheme.error))),
                      ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
