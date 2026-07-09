import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m3_expressive/m3_expressive.dart';

import '../../application/platform_admin_providers.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../ui/theme/app_spacing.dart';
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
      await ref.read(adminAuthProvider.notifier).login(_username.text.trim(), _password.text);
      if (!mounted) return;
      context.go('/admin/dashboard');
    } catch (_) {
      if (mounted) showServisSnackbar(context, context.l10n.invalidCredentials, type: SnackbarType.error);
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go("/welcome"),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: ModernCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
          child: ModernCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.admin_panel_settings, size: 40, color: scheme.primary),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(context.l10n.platformAdmin, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(context.l10n.adminLoginSubtitle, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _username,
                  decoration: InputDecoration(labelText: context.l10n.username, prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: context.l10n.password,
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                      ? M3LoadingIndicator(size: 20, color: Colors.white)
                      : Text(context.l10n.login),
                  ),
                ),
              ]),
            ),
          ),
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }
}
