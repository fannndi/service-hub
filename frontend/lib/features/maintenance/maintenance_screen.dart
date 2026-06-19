import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/config_service.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/widgets/modern_card.dart';

class MaintenanceScreen extends StatefulWidget {
  final String message;
  final bool isOffline;

  const MaintenanceScreen({
    super.key,
    required this.message,
    this.isOffline = false,
  });

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  Timer? _retryTimer;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _startAutoRetry();
  }

  void _startAutoRetry() {
    _retryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _retryConnection();
    });
  }

  Future<void> _retryConnection() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);

    try {
      final config = await ConfigService.fetch();
      if (!config.maintenanceMode && mounted) {
        context.go('/splash');
      }
    } catch (_) {
      // Still offline or maintenance, keep showing
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              child: ModernCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: scheme.tertiaryContainer.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.isOffline
                            ? Icons.wifi_off_rounded
                            : Icons.construction_rounded,
                        size: 44,
                        color: scheme.tertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      widget.isOffline
                          ? 'Koneksi Tidak Ditemukan'
                          : 'Sedang Maintenance',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _isRetrying ? null : _retryConnection,
                        icon: _isRetrying
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded),
                        label: Text(_isRetrying ? 'Mencoba...' : 'Coba Lagi'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Auto-retry tiap 30 detik',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
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
