import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/store_admin_providers.dart';
import '../../../../../core/l10n/app_localizations.dart';
import 'package:m3_expressive/m3_expressive.dart';

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
            SnackBar(content: Text(context.l10n.minLength8)));
      }
      return;
    }
    if (newPassword.text != confirmPassword.text) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.confirmationMismatch)));
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
            SnackBar(content: Text(context.l10n.passwordChanged)));
        context.go('/store/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.failed.replaceFirst('{error}', '$e'))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.changePassword), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/store/dashboard'))),
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
                        InputDecoration(labelText: context.l10n.oldPassword)),
                const SizedBox(height: 12),
                TextField(
                    controller: newPassword,
                    obscureText: true,
                    decoration: InputDecoration(
                        labelText: context.l10n.newPassword,
                        helperText: context.l10n.minLength8)),
                const SizedBox(height: 12),
                TextField(
                    controller: confirmPassword,
                    obscureText: true,
                    decoration: InputDecoration(
                        labelText: context.l10n.confirmPassword)),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: M3LoadingIndicator(size: 20, color: Colors.white))
                      : const Icon(Icons.lock_reset),
                  label: Text(context.l10n.savePassword),
                ),
              ]),
            ),
          ),
        ),
      );
}
