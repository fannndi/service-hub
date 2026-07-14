import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3_expressive/m3_expressive.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../data/admin_notification_repository.dart';
import '../../application/admin_notification_provider.dart';

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});
  @override
  ConsumerState<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends ConsumerState<AdminNotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  String _typeForTab(int index) {
    switch (index) {
      case 0: return 'all';
      case 1: return 'broadcast';
      default: return 'new_order,payment,dispute,order_completion';
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(adminNotificationRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifikasi Platform'),
        bottom: TabBar(controller: _tabCtrl, tabs: [
          Tab(text: 'Semua'),
          Tab(text: 'Broadcast'),
          Tab(text: 'Sistem'),
        ]),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await repo.markAllRead();
              ref.invalidate(adminNotificationsProvider);
              ref.invalidate(adminUnreadCountProvider);
            },
            icon: const Icon(Icons.done_all, size: 18),
            label: Text('Tandai Dibaca'),
          ),
        ],
      ),
      body: TabBarView(controller: _tabCtrl, children: [
        _buildTab('all', repo),
        _buildTab('broadcast', repo),
        _buildTab('system', repo),
      ]),
    );
  }

  Widget _buildTab(String type, AdminNotificationRepository repo) {
    final value = ref.watch(adminNotificationsProvider);
    return value.when(
      loading: () => const Center(child: M3LoadingIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        final list = items.whereType<Map<String, dynamic>>().toList();
        if (list.isEmpty) return Center(child: Text('Belum ada notifikasi'));
        return RefreshIndicator(
          onRefresh: () async { ref.invalidate(adminNotificationsProvider); },
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final n = list[i];
              final title = n['title'] as String? ?? '';
              final message = n['message'] as String? ?? '';
              final isRead = n['is_read'] as bool? ?? false;
              final createdAt = n['created_at'] as String? ?? '';
              final type = n['type'] as String? ?? '';
              final linkTo = n['link_to'] as String? ?? '';

              IconData icon;
              Color iconColor;
              switch (type) {
                case 'broadcast': icon = Icons.campaign; iconColor = Colors.purple; break;
                case 'new_order': icon = Icons.add_box; iconColor = Colors.blue; break;
                case 'payment': icon = Icons.payment; iconColor = Colors.green; break;
                case 'dispute': icon = Icons.warning; iconColor = Colors.orange; break;
                default: icon = Icons.notifications; iconColor = Colors.grey;
              }

              return ListTile(
                leading: Icon(icon, color: iconColor),
                title: Text(title, style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.w600)),
                subtitle: Text('$message\n${_relativeTime(createdAt)}', maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: isRead ? null : Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                onTap: () async {
                  if (!isRead) {
                    await repo.markAsRead(n['id'] as String? ?? '');
                    ref.invalidate(adminNotificationsProvider);
                    ref.invalidate(adminUnreadCountProvider);
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  String _relativeTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
      if (diff.inHours < 24) return '${diff.inHours}j lalu';
      if (diff.inDays < 7) return '${diff.inDays}h lalu';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      debugPrint('_relativeTime error: $e');
      return '';
    }
  }
}
