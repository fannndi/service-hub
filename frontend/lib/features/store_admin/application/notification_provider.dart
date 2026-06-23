import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/store_admin_repositories.dart';

final storeNotificationRepositoryProvider = Provider<StoreNotificationRepository>((_) => StoreNotificationRepository());

final notificationsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.read(storeNotificationRepositoryProvider);
  return repo.getNotifications();
});
