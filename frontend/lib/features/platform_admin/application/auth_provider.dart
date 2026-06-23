import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/platform_admin_repositories.dart';
import '../domain/platform_admin_models.dart';
import '../../../core/supabase_service.dart';

final adminAuthRepositoryProvider = Provider<AdminAuthRepository>((_) => AdminAuthRepository());

final adminAuthProvider = AsyncNotifierProvider<AdminAuthNotifier, PlatformAdminUser?>(AdminAuthNotifier.new);

class AdminAuthNotifier extends AsyncNotifier<PlatformAdminUser?> {
  final _sb = SupabaseService.instance;

  @override
  Future<PlatformAdminUser?> build() async {
    if (!_sb.isLoggedIn || _sb.role != 'platform_admin') return null;
    final meta = _sb.user?.userMetadata ?? {};
    return PlatformAdminUser(id: _sb.user!.id, username: meta['username'] as String? ?? 'admin', fullName: meta['full_name'] as String? ?? 'Admin');
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
