import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/customer_providers.dart';
import '../widgets/customer_widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => CustomerScaffold(
        title: 'Notifikasi',
        child: AsyncPage(
            value: ref.watch(notificationsProvider),
            builder: (items) => items.isEmpty
                ? const EmptyMessage('Belum ada notifikasi.')
                : ListView(
                    children: items
                        .map((item) => ListTile(
                            leading: Icon(item.isRead
                                ? Icons.mark_email_read
                                : Icons.mark_email_unread),
                            title: Text(item.title),
                            subtitle: Text(item.message),
                            onTap: () => context.push(
                                '/notifications/${item.id}',
                                extra: item)))
                        .toList())),
      );
}
