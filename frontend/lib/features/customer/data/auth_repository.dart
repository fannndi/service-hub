import '../domain/customer_models.dart';
import '../../../core/supabase_config.dart';
import 'api_helper.dart';

class CustomerAuthRepository {
  Future<CustomerUser> login(String phone, String password) async {
    final email = SupabaseConfig.buildCustomerEmail(phone);
    final response = await sb.signIn(email, password);
    final meta = response.user?.userMetadata ?? {};
    return CustomerUser(
      id: response.user!.id,
      fullName: meta['full_name'] as String? ?? 'Pelanggan',
      phoneNumber: phone,
      isFirstLogin: meta['is_first_login'] as bool? ?? true,
    );
  }

  Future<void> logout() => sb.signOut();

  Future<void> changePassword(String oldPw, String newPw) => sb.updatePassword(newPw);

  Future<CustomerUser?> restoreSession() async {
    if (!sb.isLoggedIn) return null;
    final meta = sb.user?.userMetadata ?? {};
    return CustomerUser(
      id: sb.user!.id,
      fullName: meta['full_name'] as String? ?? 'Pelanggan',
      phoneNumber: meta['phone'] as String? ?? '',
      isFirstLogin: meta['is_first_login'] as bool? ?? true,
    );
  }

  Future<void> updateProfile({String? fullName, String? address}) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (address != null) updates['address'] = address;
    if (updates.isNotEmpty) {
      await sb.from('users').update(updates).eq('id', sb.user!.id);
    }
  }
}
