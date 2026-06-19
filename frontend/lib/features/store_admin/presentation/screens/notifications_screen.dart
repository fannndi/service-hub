import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/store_admin_providers.dart';
import '../widgets/store_admin_widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Center')),
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorPanel(message: e.toString()),
        data: (page) => ListView(children: [
          for (final item in page.items)
            ListTile(
              leading: Icon(item.isRead ? Icons.mark_email_read_outlined : Icons.notifications_active_outlined),
              title: Text(item.title),
              subtitle: Text('${item.message}\n${dateText(item.createdAt)}'),
            ),
        ]),
      ),
    );
  }
}
