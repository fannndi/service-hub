import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../ui/theme/app_spacing.dart';
import '../../application/customer_providers.dart';
import '../../domain/user_session.dart';
import '../../../../ui/widgets/servis_dialog.dart';
import '../../../../shared_widgets/error_state.dart';
import '../widgets/customer_widgets.dart';
import 'package:m3_expressive/m3_expressive.dart';

class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});
  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  Future<List<dynamic>>? _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = ref.read(sessionRepositoryProvider).getSessions();
  }

  void _refresh() {
    setState(() {
      _sessionsFuture = ref.read(sessionRepositoryProvider).getSessions();
    });
  }

  Future<void> _revoke(String id) async {
    final confirm = await showServisConfirmDialog(
      context,
      title: context.l10n.revokeSession,
      message: context.l10n.revokeSessionConfirm,
      confirmLabel: context.l10n.revoke,
      isDestructive: true,
    );
    if (confirm) {
      await ref.read(sessionRepositoryProvider).revokeSession(id);
      _refresh();
    }
  }

  Future<void> _logoutAll() async {
    final confirm = await showServisConfirmDialog(
      context,
      title: context.l10n.logoutAll,
      message: context.l10n.logoutAllConfirm,
      confirmLabel: context.l10n.logoutAll,
      isDestructive: true,
    );
    if (confirm) {
      await ref.read(sessionRepositoryProvider).logoutAll();
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomerScaffold(
      title: context.l10n.loginSessions,
      actions: [
        IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logoutAll,
            tooltip: context.l10n.logoutAll),
      ],
      child: FutureBuilder<List<dynamic>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: M3LoadingIndicator());
          }
          if (snapshot.hasError) {
            return ErrorState(
                message: '${context.l10n.sessionLoadError} ${snapshot.error}',
                onRetry: _refresh);
          }
          final raw = snapshot.data ?? [];
          if (raw.isEmpty) {
            return EmptyMessage(context.l10n.noActiveSessions);
          }
          final sessions = raw
              .map((j) => UserSession.fromJson(j as Map<String, dynamic>))
              .toList();
          return ListView.separated(
            padding: EdgeInsets.all(AppSpacing.md),
            itemCount: sessions.length,
            separatorBuilder: (_, __) => Divider(),
            itemBuilder: (context, index) {
              final s = sessions[index];
              final deviceName = s.deviceInfo?['device'] as String? ??
                  context.l10n.unknownDevice;
              return ListTile(
                leading: Icon(
                    s.isActive ? Icons.phone_android : Icons.phone_android,
                    color: s.isActive ? theme.colorScheme.tertiary : theme.colorScheme.onSurfaceVariant),
                title: Text(deviceName, style: theme.textTheme.bodyLarge),
                subtitle: Text(
                  '${s.ipAddress ?? '-'} \u2022 ${_formatDate(context, s.lastActiveAt)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                trailing: s.isActive
                    ? TextButton(
                        onPressed: () => _revoke(s.id),
                        child: Text(context.l10n.revoke))
                    : Icon(Icons.check_circle,
                        size: 18, color: theme.colorScheme.onSurfaceVariant),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return context.l10n.justNow;
    if (diff.inHours < 1) return '${diff.inMinutes}m lalu';
    if (diff.inDays < 1) return '${diff.inHours}h lalu';
    return '${diff.inDays}d lalu';
  }
}
