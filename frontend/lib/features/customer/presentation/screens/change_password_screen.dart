import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/customer_providers.dart';
import '../../data/customer_repositories.dart';
import '../widgets/customer_widgets.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(customerAuthProvider.notifier)
          .changePassword(_old.text, _next.text);
      if (mounted) context.go('/home');
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
  Widget build(BuildContext context) => CustomerScaffold(
        title: 'Ganti Password',
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Material(
                  color: Colors.amber.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                          'Ganti password sementaramu sebelum melanjutkan.'))),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _old,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Password Lama', border: OutlineInputBorder()),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Wajib diisi.' : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _next,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Password Baru', border: OutlineInputBorder()),
                  validator: (v) {
                    if (v == null || v.length < 8) return 'Minimal 8 karakter.';
                    if (v == _old.text) {
                      return 'Password baru tidak boleh sama.';
                    }
                    return null;
                  }),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Konfirmasi Password Baru',
                      border: OutlineInputBorder()),
                  validator: (v) =>
                      v != _next.text ? 'Konfirmasi tidak sama.' : null),
              const SizedBox(height: 20),
              FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Simpan Password')),
            ],
          ),
        ),
      );
}
