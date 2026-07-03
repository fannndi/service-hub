import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/customer_repositories.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((_) => NotificationRepository());

final notificationsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.read(notificationRepositoryProvider);
  return repo.getNotifications();
});

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.read(notificationRepositoryProvider);
  final count = await repo.getUnreadCount();
  return count;
});

final notificationPreferenceProvider = StateProvider<bool>((_) => true);

final unreadCountStreamProvider = StreamProvider.autoDispose<int>((ref) {
  final repo = ref.read(notificationRepositoryProvider);
  return Stream.periodic(const Duration(seconds: 30), (_) => 0)
    .asyncMap((_) => repo.getUnreadCount())
    .handleError((e) {
      debugPrint('Unread count error: $e');
      return 0;
    });
});
