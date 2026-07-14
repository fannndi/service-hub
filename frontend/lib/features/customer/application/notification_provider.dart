import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/customer_repositories.dart';
import '../../../core/supabase_service.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((_) => NotificationRepository());

final notificationsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.read(notificationRepositoryProvider);
  return repo.getNotifications();
});

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.read(notificationRepositoryProvider);
  return repo.getUnreadCount();
});

final notificationPreferenceProvider = StateProvider<bool>((_) => true);

final unreadCountStreamProvider = StreamProvider.autoDispose<int>((ref) {
  final repo = ref.read(notificationRepositoryProvider);
  final uid = SupabaseService.instance.user?.id;
  if (uid == null) return Stream.value(0);

  final channel = Supabase.instance.client
    .channel('customer-notifications-$uid')
    .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: uid),
        callback: (payload) {
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadCountProvider);
    })
    .subscribe();

  ref.onDispose(() {
    Supabase.instance.client.removeChannel(channel);
  });

  return Stream.periodic(const Duration(seconds: 30), (_) => 0)
    .asyncMap((_) => repo.getUnreadCount())
    .handleError((e) {
      debugPrint('Unread count error: $e');
      return 0;
    });
});
