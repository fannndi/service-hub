import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../ui/theme/app_spacing.dart';
import '../../../../ui/widgets/modern_card.dart';
import '../../application/store_admin_providers.dart';
import 'package:m3_expressive/m3_expressive.dart';

class StoreLoginScreen extends ConsumerStatefulWidget {
  const StoreLoginScreen({super.key});
  @override
  ConsumerState<StoreLoginScreen> createState() => _StoreLoginScreenState();
}

class _StoreLoginScreenState extends ConsumerState<StoreLoginScreen> {
  final phone = TextEditingController();
  final password = TextEditingController();
  bool obscure = true;

  String _parseError(Object? error, AppLocalizations l10n) {
    final msg = error?.toString() ?? 'Terjadi kesalahan.';
    if (msg.contains('InvalidCredentialsException') || msg.contains('INVALID_CREDENTIALS')) return l10n.invalidCredentials;
    if (msg.contains('StoreNotActiveException') || msg.contains('STORE_NOT_ACTIVE')) return l10n.storeNotActive;
    if (msg.contains('AccountLockedException') || msg.contains('ACCOUNT_LOCKED')) return l10n.accountLocked;
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(storeAuthControllerProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Icon(Icons.storefront_rounded, size: 40, color: scheme.secondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(context.l10n.storePortal, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.l10n.storeLoginSubtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  ModernCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: phone,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: context.l10n.phoneNumber,
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: password,
                          obscureText: obscure,
                          decoration: InputDecoration(
                            labelText: context.l10n.password,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => obscure = !obscure),
                              icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          height: 56,
                          child: FilledButton.icon(
                            onPressed: auth.isLoading ? null : () => ref.read(storeAuthControllerProvider.notifier).login(phone.text.trim(), password.text),
                            icon: auth.isLoading
                              ? M3LoadingIndicator(size: 20, color: Colors.white)
                              : const Icon(Icons.login_rounded),
                            label: Text(context.l10n.login, style: theme.textTheme.labelLarge),
                          ),
                        ),
                        if (auth.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.md),
                            child: Text(
                              _parseError(auth.error, context.l10n),
                              style: TextStyle(color: scheme.error),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
