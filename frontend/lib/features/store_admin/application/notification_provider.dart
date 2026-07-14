import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/store_admin_repositories.dart';
import '../../../core/supabase_service.dart';

final storeNotificationRepositoryProvider = Provider<StoreNotificationRepository>((_) => StoreNotificationRepository());

final notificationsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.read(storeNotificationRepositoryProvider);
  return repo.getNotifications();
});

final storeUnreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.read(storeNotificationRepositoryProvider);
  return repo.getUnreadCount();
});

final storeUnreadStreamProvider = StreamProvider.autoDispose<int>((ref) {
  final repo = ref.read(storeNotificationRepositoryProvider);
  final storeId = SupabaseService.instance.storeId;
  if (storeId == null) return Stream.value(0);

  final channel = Supabase.instance.client
    .channel('store-notifications-$storeId')
    .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'store_id', value: storeId),
        callback: (payload) {
      ref.invalidate(notificationsProvider);
      ref.invalidate(storeUnreadCountProvider);
    })
    .subscribe();

  ref.onDispose(() {
    Supabase.instance.client.removeChannel(channel);
  });

  return Stream.periodic(const Duration(seconds: 30), (_) => 0)
    .asyncMap((_) => repo.getUnreadCount())
    .handleError((e) {
      debugPrint('Store unread count error: $e');
      return 0;
    });
});
