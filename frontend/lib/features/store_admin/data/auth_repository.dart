import '../domain/store_admin_models.dart';
import '../../../core/supabase_config.dart';
import 'api_helper.dart';

class StoreAuthRepository {
  Future<StoreAdminSession> login(String phone, String password) async {
    final email = SupabaseConfig.buildStoreAdminEmail(phone);
    final response = await sb.signIn(email, password);
    final meta = response.user?.userMetadata ?? {};
    return StoreAdminSession(
      adminId: response.user!.id,
      adminName: meta['full_name'] as String? ?? 'Admin',
      phoneNumber: phone,
      storeId: meta['store_id'] as String? ?? '',
      storeName: '',
      isFirstLogin: meta['is_first_login'] as bool? ?? true,
    );
  }

  Future<void> changePassword(String oldPw, String newPw) => sb.updatePassword(newPw);

  Future<StoreAdminSession?> restoreSession() async {
    if (!sb.isLoggedIn || sb.role != 'store_admin') return null;
    final meta = sb.user?.userMetadata ?? {};
    return StoreAdminSession(
      adminId: sb.user!.id,
      adminName: meta['full_name'] as String? ?? 'Admin',
      phoneNumber: '',
      storeId: meta['store_id'] as String? ?? '',
      storeName: '',
      isFirstLogin: meta['is_first_login'] as bool? ?? true,
    );
  }
}
