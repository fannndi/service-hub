import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../ui/theme/app_spacing.dart';
import '../../../../ui/widgets/modern_card.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  GestureDetector(
                    onLongPress: () => context.push('/admin/login'),
                    child: Container(
                      width: 88, height: 88,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: Icon(Icons.handyman_rounded, size: 44, color: scheme.primary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(context.l10n.appName, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.l10n.tagline,
                    style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  ModernCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 56,
                          child: FilledButton.icon(
                            onPressed: () => context.go('/service'),
                            icon: const Icon(Icons.add_task_rounded, size: 22),
                            label: Text(context.l10n.submitService, style: theme.textTheme.labelLarge),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () => context.go('/guest/track'),
                            icon: const Icon(Icons.search, size: 20),
                            label: Text(context.l10n.checkOrder, style: theme.textTheme.labelLarge),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push('/login'),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: scheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                  ),
                                  child: Icon(Icons.person_outline_rounded, color: scheme.primary, size: 24),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(context.l10n.customer, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text('Masuk', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push('/store-login'),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: scheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                  ),
                                  child: Icon(Icons.storefront_rounded, color: scheme.secondary, size: 24),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(context.l10n.store, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text('Masuk', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GestureDetector(
                    onTap: () => context.go('/store-register'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Text(
                        'Daftarkan Toko Baru',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ModernCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    color: scheme.primaryContainer.withValues(alpha: 0.35),
                    child: Row(
                      children: [
                        Icon(Icons.verified_user_rounded, size: 22, color: scheme.primary),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            context.l10n.appDescription,
                            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurface, height: 1.4),
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
