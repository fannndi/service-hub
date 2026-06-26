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
              child: ListView(
                children: list
                    .map((item) => ListTile(
                        leading: Icon(item.isRead
                            ? Icons.mark_email_read
                            : Icons.mark_email_unread,
                            color: item.isRead ? Colors.grey : null),
                        title: Text(item.title,
                            style: TextStyle(
                                fontWeight: item.isRead
                                    ? FontWeight.normal
                                    : FontWeight.w600)),
                        subtitle: Text(item.message,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
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
                        }))
                    .toList(),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
