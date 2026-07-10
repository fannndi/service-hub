import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_notification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import '../../../core/supabase_service.dart';

final adminNotificationRepositoryProvider = Provider<AdminNotificationRepository>((_) => AdminNotificationRepository());

final adminNotificationsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.read(adminNotificationRepositoryProvider);
  return repo.getNotifications();
});

final adminUnreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.read(adminNotificationRepositoryProvider);
  return repo.getUnreadCount();
});

final adminPendingAppsProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.read(adminNotificationRepositoryProvider);
  return repo.getRecentStoreApplications();
});

final adminRealtimeProvider = StreamProvider.autoDispose<int>((ref) {
  final repo = ref.read(adminNotificationRepositoryProvider);
  final controller = StreamController<int>();
  final channel = Supabase.instance.client
    .channel('admin-notifications')
    .on('postgres_changes',
        event: 'INSERT',
        schema: 'public',
        table: 'notifications',
        filter: null,
        (payload) {
      ref.invalidate(adminNotificationsProvider);
      ref.invalidate(adminUnreadCountProvider);
    })
    .subscribe();
  ref.onDispose(() {
    Supabase.instance.client.removeChannel(channel);
    controller.close();
  });
  return Stream.periodic(const Duration(seconds: 30), (_) => 0)
    .asyncMap((_) => repo.getUnreadCount())
    .handleError((_) => 0);
});
