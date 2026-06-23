import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/platform_admin_repositories.dart';
import '../domain/platform_admin_models.dart';
import '../../../core/supabase_service.dart';

final adminRepositoryProvider = Provider<AdminRepository>((_) => AdminRepository());
final adminAuthRepositoryProvider = Provider<AdminAuthRepository>((_) => AdminAuthRepository());

final adminAuthProvider = AsyncNotifierProvider<AdminAuthNotifier, PlatformAdminUser?>(AdminAuthNotifier.new);

class AdminAuthNotifier extends AsyncNotifier<PlatformAdminUser?> {
  @override
  Future<PlatformAdminUser?> build() async {
    if (!sb.isLoggedIn || sb.role != 'platform_admin') return null;
    final meta = sb.user?.userMetadata ?? {};
    return PlatformAdminUser(id: sb.user!.id, username: meta['username'] as String? ?? 'admin', fullName: meta['full_name'] as String? ?? 'Admin');
  }

  Future<void> login(String username, String password) async {
    final repo = ref.read(adminAuthRepositoryProvider);
    final user = await repo.login(username, password);
    state = AsyncData(user);
  }

  Future<void> logout() async {
    await SupabaseService.instance.signOut();
    state = const AsyncData(null);
  }
}

final storeListProvider = FutureProvider.autoDispose<List<StoreListItem>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return repo.getStores();
});

final storeAdminListProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return repo.getStoreAdmins();
});

final userListProvider = FutureProvider.autoDispose<List<UserListItem>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return repo.getUsers();
});

final sb = SupabaseService.instance;
