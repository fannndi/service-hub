import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/customer_providers.dart';
import '../../data/customer_repositories.dart';
import '../../domain/customer_models.dart';
import '../../domain/user_session.dart';
import '../../../../shared_widgets/error_state.dart';
import '../../../../shared_widgets/status_badge.dart';
import '../../../../shared_widgets/empty_state.dart';
import '../../../../shared_widgets/formatters.dart';
import '../widgets/customer_widgets.dart';

class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});
  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}
class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  Future<List<UserSession>> _fetch() => ref.read(sessionRepositoryProvider).getSessions();

  Future<void> _revoke(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Revoke Sesi'),
        content: const Text('Sesi ini akan diakhiri. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Revoke')),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(sessionRepositoryProvider).revokeSession(id);
      setState(() {});
    }
  }

  Future<void> _logoutAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Logout Semua'),
        content: const Text('Semua sesi akan diakhiri kecuali sesi saat ini. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Logout All')),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(sessionRepositoryProvider).logoutAll();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomerScaffold(
      title: 'Sesi Login',
      actions: [
        IconButton(icon: const Icon(Icons.logout), onPressed: _logoutAll, tooltip: 'Logout Semua'),
      ],
      child: FutureBuilder<List<UserSession>>(
        future: _fetch(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorState(message: 'Gagal memuat sesi: ${snapshot.error}', onRetry: () => setState(() {}));
          }
          final sessions = snapshot.data ?? [];
          if (sessions.isEmpty) {
            return const EmptyMessage('Tidak ada sesi aktif');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final s = sessions[index];
              final deviceName = s.deviceInfo?['device'] as String? ?? 'Perangkat tidak dikenal';
              return ListTile(
                leading: Icon(s.isActive ? Icons.phone_android : Icons.phone_android, color: s.isActive ? Colors.green : Colors.grey),
                title: Text(deviceName, style: theme.textTheme.bodyLarge),
                subtitle: Text(
                  '${s.ipAddress ?? '-'} Ã¢â‚¬Â¢ ${_formatDate(s.lastActiveAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                trailing: s.isActive
                    ? TextButton(onPressed: () => _revoke(s.id), child: const Text('Revoke'))
                    : const Icon(Icons.check_circle, size: 18, color: Colors.grey),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes}m lalu';
    if (diff.inDays < 1) return '${diff.inHours}h lalu';
    return '${diff.inDays}h lalu';
  }
}
