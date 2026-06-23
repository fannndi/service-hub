import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/platform_admin_models.dart';
import '../../../core/supabase_config.dart';
import 'api_helper.dart';

class AdminAuthRepository {
  Future<PlatformAdminUser> login(String username, String password) async {
    final email = SupabaseConfig.buildPlatformAdminEmail(username);
    await sb.signIn(email, password);
    return PlatformAdminUser(id: sb.user!.id, username: username, fullName: 'Admin');
  }

  Future<void> logout() => sb.signOut();
}
