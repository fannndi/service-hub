import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../ui/theme/app_decorations.dart';
import '../../../../ui/theme/app_spacing.dart';
import '../../../../ui/widgets/modern_card.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: AppDecorations.heroBanner(context),
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Icon(
                              Icons.handyman_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'ServisGadget',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Servis gadget, tracking jelas, pembayaran rapi.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Mulai dari sini',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Pilih cara Anda ingin melanjutkan',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SizedBox(
                            height: 54,
                            child: FilledButton.icon(
                              onPressed: () => context.go('/service'),
                              icon: const Icon(Icons.add_task_rounded, size: 22),
                              label: const Text('Ajukan Servis'),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () => context.go('/guest/track'),
                              icon: const Icon(Icons.search, size: 20),
                              label: const Text('Cek Pesanan'),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => context.push('/login'),
                                  icon: const Icon(Icons.person_outline_rounded,
                                      size: 20),
                                  label: const Text('Pelanggan'),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => context.push('/store-login'),
                                  icon: const Icon(Icons.storefront_rounded,
                                      size: 20),
                                  label: const Text('Toko'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          OutlinedButton.icon(
                            onPressed: () => context.push('/admin/login'),
                            icon: const Icon(
                              Icons.admin_panel_settings_outlined,
                              size: 20,
                            ),
                            label: const Text('Admin Platform'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ModernCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      color: scheme.primaryContainer.withValues(alpha: 0.35),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            size: 22,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'Progress servis, estimasi biaya, dan riwayat pembayaran dalam satu tempat.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
