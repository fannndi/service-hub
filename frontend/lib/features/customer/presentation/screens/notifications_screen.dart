import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../application/customer_providers.dart';
import '../../application/notification_provider.dart';
import '../../domain/notification_models.dart';
import '../widgets/customer_widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(notificationRepositoryProvider);
    return CustomerScaffold(
      title: context.l10n.notifications,
      child: AsyncPage(
        value: ref.watch(notificationsProvider),
        builder: (items) {
          final list = items
              .whereType<Map<String, dynamic>>()
              .map(NotificationItem.fromJson)
              .toList();
          if (list.isEmpty) return EmptyMessage(context.l10n.noNotifications);
          return Column(children: [
            if (list.any((i) => !i.isRead))
              TextButton.icon(
                onPressed: () async {
                  await repo.markAllRead();
                  ref.invalidate(notificationsProvider);
                  ref.invalidate(unreadCountProvider);
                },
                icon: const Icon(Icons.done_all, size: 18),
                label: Text(context.l10n.markAllRead),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async { ref.invalidate(notificationsProvider); },
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final item = list[i];
                    return ListTile(
                        leading: Icon(item.isRead
                            ? Icons.mark_email_read
                            : Icons.mark_email_unread,
                            color: item.isRead ? Colors.grey : null),
                        title: Text(item.title,
                            style: TextStyle(
                                fontWeight: item.isRead
                                    ? FontWeight.normal
                                    : FontWeight.w600)),
                        subtitle: Text('${item.message}\n${_relativeTime(item.createdAt)}',
                            maxLines: 3, overflow: TextOverflow.ellipsis),
                        trailing: item.isRead ? null : Container(width: 8, height: 8,
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                        onTap: () async {
                          if (!item.isRead && item.id.isNotEmpty) {
                            await repo.markAsRead(item.id);
                            ref.invalidate(notificationsProvider);
                            ref.invalidate(unreadCountProvider);
                          }
                          final link = item.linkTo;
                          if (link != null && link.isNotEmpty && context.mounted) {
                            context.push(link);
                          }
                        });
                  },
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
