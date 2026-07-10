import '../domain/store_admin_models.dart';
import '../../../core/supabase_config.dart';
import 'api_helper.dart';

class StoreAuthRepository {
  Future<StoreAdminSession> login(String phone, String password) async {
    final email = SupabaseConfig.buildStoreAdminEmail(phone);
    final response = await sb.signIn(email, password);
    final meta = response.user?.userMetadata ?? {};
    final uid = response.user?.id;
    if (uid == null) throw Exception('Not authenticated');

    // H13: Check is_active in store_admins table
    final adminData = await sb.from('store_admins').select('is_active').eq('id', uid).maybeSingle();
    if (adminData?['is_active'] == false) {
      await sb.signOut();
      throw Exception('Akun toko tidak aktif. Silakan hubungi admin platform.');
    }

    return StoreAdminSession(
      adminId: uid,
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
    final uid = sb.user?.id;
    if (uid == null) return null; // H12: return null instead of throw

    // H13: Check is_active on session restore
    final adminData = await sb.from('store_admins').select('is_active').eq('id', uid).maybeSingle();
    if (adminData?['is_active'] == false) {
      await sb.signOut();
      return null;
    }

    return StoreAdminSession(
      adminId: uid,
      adminName: meta['full_name'] as String? ?? 'Admin',
      phoneNumber: '',
      storeId: meta['store_id'] as String? ?? '',
      storeName: '',
      isFirstLogin: meta['is_first_login'] as bool? ?? true,
    );
  }
}
