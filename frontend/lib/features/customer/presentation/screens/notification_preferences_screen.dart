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

class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(notificationPreferenceProvider);
    return CustomerScaffold(
      title: 'Preferensi Notifikasi',
      child: enabled.when(
        data: (value) => SwitchListTile(
            title: const Text('Notifikasi WhatsApp dan aplikasi'),
            value: value,
            onChanged: (next) async {
              await ref
                  .read(customerSessionProvider)
                  .saveNotificationPreference(next);
              ref.invalidate(notificationPreferenceProvider);
            }),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const EmptyMessage('Preferensi belum bisa dimuat.'),
      ),
    );
  }
}
