import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withValues(alpha: .82),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color:
                                  scheme.outlineVariant.withValues(alpha: .7)),
                        ),
                        child: Icon(Icons.handyman_outlined,
                            color: scheme.onPrimaryContainer),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ServisGadget',
                                style: theme.textTheme.headlineMedium),
                            Text(
                                'Servis gadget, tracking jelas, pembayaran rapi.',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: .75)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Mulai dari sini',
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: () => context.go('/service'),
                              icon:
                                  const Icon(Icons.add_task_outlined, size: 21),
                              label: const Text('Ajukan Servis'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => context.push('/login'),
                                  icon: const Icon(Icons.person_outline,
                                      size: 20),
                                  label: const Text('Pelanggan'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => context.push('/store-login'),
                                  icon: const Icon(Icons.storefront_outlined,
                                      size: 20),
                                  label: const Text('Toko'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () => context.push('/admin/login'),
                            icon: const Icon(
                                Icons.admin_panel_settings_outlined,
                                size: 20),
                            label: const Text('Admin Platform'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Icon(Icons.verified_user_outlined,
                          size: 18, color: scheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Progress servis, estimasi biaya, dan riwayat pembayaran dalam satu tempat.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
