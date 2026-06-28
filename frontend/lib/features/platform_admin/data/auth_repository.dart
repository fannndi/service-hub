
import '../domain/platform_admin_models.dart';
import '../../../core/supabase_config.dart';
import 'api_helper.dart';

class AdminAuthRepository {
  Future<PlatformAdminUser> login(String username, String password) async {
    final email = SupabaseConfig.buildPlatformAdminEmail(username);
    await sb.signIn(email, password);
    final uid = sb.user?.id ?? '';
    return PlatformAdminUser(id: uid, username: username, fullName: 'Admin');
  }

  Future<void> logout() => sb.signOut();
}
