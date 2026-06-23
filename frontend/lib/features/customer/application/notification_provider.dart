import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/customer_repositories.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((_) => NotificationRepository());

final notificationsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.read(notificationRepositoryProvider);
  return repo.getNotifications();
});

final notificationPreferenceProvider = StateProvider<bool>((_) => true);
