import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../application/store_admin_providers.dart';
import '../../domain/store_admin_notification_models.dart';
import '../widgets/store_admin_widgets.dart';
import 'package:m3_expressive/m3_expressive.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(storeNotificationRepositoryProvider);
    final value = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.notificationCenter),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await repo.markAllRead();
              ref.invalidate(notificationsProvider);
              ref.invalidate(storeUnreadCountProvider);
            },
            icon: const Icon(Icons.done_all, size: 18),
            label: Text(context.l10n.readAll),
          ),
        ],
      ),
      body: value.when(
        loading: () => const Center(child: M3LoadingIndicator()),
        error: (e, _) => ErrorPanel(message: e.toString()),
        data: (page) {
          final items = page
              .whereType<Map<String, dynamic>>()
              .map(NotificationItem.fromJson)
              .toList();
          if (items.isEmpty) return Center(child: Text(context.l10n.noNotifications));
          return ListView(children: [
            for (final item in items)
              ListTile(
                leading: Icon(
                  item.isRead
                      ? Icons.mark_email_read_outlined
                      : Icons.notifications_active_outlined,
                  color: item.isRead ? Colors.grey : null,
                ),
                title: Text(item.title,
                    style: TextStyle(
                        fontWeight: item.isRead ? FontWeight.normal : FontWeight.w600)),
                subtitle: Text('${item.message}\n${dateText(item.createdAt)}',
                    maxLines: 3, overflow: TextOverflow.ellipsis),
                onTap: () async {
                  if (!item.isRead) {
                    await repo.markAsRead(item.id);
                    ref.invalidate(notificationsProvider);
                    ref.invalidate(storeUnreadCountProvider);
                  }
                },
              ),
          ]);
        },
      ),
    );
  }
}
