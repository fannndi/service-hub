import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/store_admin_providers.dart';

class StoreChangePasswordScreen extends ConsumerStatefulWidget {
  const StoreChangePasswordScreen({super.key});
  @override
  ConsumerState<StoreChangePasswordScreen> createState() =>
      _StoreChangePasswordScreenState();
}

class _StoreChangePasswordScreenState
    extends ConsumerState<StoreChangePasswordScreen> {
  final oldPassword = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    if (oldPassword.text.isEmpty || newPassword.text.isEmpty) return;
    if (newPassword.text.length < 8) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password baru minimal 8 karakter.')));
      }
      return;
    }
    if (newPassword.text != confirmPassword.text) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Konfirmasi password tidak cocok.')));
      }
      return;
    }
    setState(() => _loading = true);
    try {
      await ref
          .read(storeAuthControllerProvider.notifier)
          .changePassword(oldPassword.text, newPassword.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password berhasil diubah.')));
        context.go('/store/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Ganti Password')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: oldPassword,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Password lama')),
                const SizedBox(height: 12),
                TextField(
                    controller: newPassword,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Password baru',
                        helperText: 'Minimal 8 karakter')),
                const SizedBox(height: 12),
                TextField(
                    controller: confirmPassword,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Konfirmasi password baru')),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.lock_reset),
                  label: const Text('Simpan Password'),
                ),
              ]),
            ),
          ),
        ),
      );
}
