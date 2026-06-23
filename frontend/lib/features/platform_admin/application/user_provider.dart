import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/platform_admin_repositories.dart';
import '../domain/platform_admin_models.dart';

final adminUserRepositoryProvider = Provider<AdminUserRepository>((_) => AdminUserRepository());

final userListProvider = FutureProvider.autoDispose<List<UserListItem>>((ref) async {
  final repo = ref.read(adminUserRepositoryProvider);
  return repo.getUsers();
});
