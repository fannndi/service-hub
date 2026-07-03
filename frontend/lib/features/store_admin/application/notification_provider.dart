import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/store_admin_repositories.dart';

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
  return Stream.periodic(const Duration(seconds: 30), (_) => 0)
    .asyncMap((_) => repo.getUnreadCount())
    .handleError((e) {
      debugPrint('Unread count error: $e');
      return 0;
    });
});
