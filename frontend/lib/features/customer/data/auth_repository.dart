import '../domain/customer_models.dart';
import '../../../core/supabase_config.dart';
import 'api_helper.dart';

class CustomerAuthRepository {
  Future<CustomerUser> login(String email, String password) async {
    final response = await sb.signIn(email, password);
    final meta = response.user?.userMetadata ?? {};
    final uid = response.user?.id;
    if (uid == null) throw Exception('Not authenticated');

    // H9: Check account_status after login
    final userData = await sb.from('users').select('account_status, phone_number').eq('id', uid).maybeSingle();
    if (userData?['account_status'] == 'suspended') {
      await sb.signOut();
      throw Exception('Akun Anda sedang tidak aktif. Silakan hubungi toko.');
    }

    return CustomerUser(
      id: uid,
      fullName: meta['full_name'] as String? ?? 'Pelanggan',
      // H8: Use phone from DB, fallback to metadata, never email
      phoneNumber: userData?['phone_number'] as String? ?? meta['phone'] as String? ?? email,
      isFirstLogin: meta['is_first_login'] as bool? ?? true,
    );
  }

  Future<void> logout() => sb.signOut();

  Future<void> changePassword(String oldPw, String newPw) => sb.updatePassword(newPw);

  Future<CustomerUser?> restoreSession() async {
    if (!sb.isLoggedIn || sb.role != 'customer') return null;
    final meta = sb.user?.userMetadata ?? {};
    final uid = sb.user?.id;
    if (uid == null) return null;

    // H9: Also check account_status on session restore
    final userData = await sb.from('users').select('account_status, phone_number').eq('id', uid).maybeSingle();
    if (userData?['account_status'] == 'suspended') {
      await sb.signOut();
      return null;
    }

    return CustomerUser(
      id: uid,
      fullName: meta['full_name'] as String? ?? 'Pelanggan',
      phoneNumber: userData?['phone_number'] as String? ?? meta['phone'] as String? ?? '',
      isFirstLogin: meta['is_first_login'] as bool? ?? true,
      address: meta['address'] as String?,
    );
  }

  Future<CustomerUser?> getCurrentUser() async {
    if (!sb.isLoggedIn) return null;
    return restoreSession();
  }

  Future<void> updateProfile({String? fullName, String? address}) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (address != null) updates['address'] = address;
    if (updates.isNotEmpty) {
      final uid = sb.user?.id;
      if (uid == null) throw Exception('Not authenticated');
      await sb.from('users').update(updates).eq('id', uid);
    }
  }
}
