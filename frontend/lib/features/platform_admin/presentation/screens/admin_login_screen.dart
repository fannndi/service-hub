import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/platform_admin_providers.dart';
import '../../../../ui/theme/app_decorations.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../ui/theme/app_theme.dart';
import '../../../../ui/widgets/modern_card.dart';
import '../../../../ui/widgets/servis_snackbar.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  Future<void> _submit() async {
    if (_username.text.isEmpty || _password.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(adminAuthProvider.notifier)
          .login(_username.text.trim(), _password.text);
      if (!mounted) return;
      context.go('/admin/dashboard');
    } catch (_) {
      if (mounted) {
        showServisSnackbar(context, context.l10n.invalidCredentials, type: SnackbarType.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: GradientBackground(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.admin_panel_settings,
                          size: 40, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(context.l10n.platformAdmin,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(context.l10n.adminLoginSubtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 24),
                  TextField(
                    controller: _username,
                    decoration: InputDecoration(
                        labelText: context.l10n.username, prefixIcon: const Icon(Icons.person)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: context.l10n.password,
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(context.l10n.login),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }
}
