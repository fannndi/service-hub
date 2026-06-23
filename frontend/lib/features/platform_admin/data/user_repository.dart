import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/platform_admin_models.dart';
import 'api_helper.dart';

class AdminUserRepository {
  Future<List<UserListItem>> getUsers() async {
    final data = await sb.from('users').select('*').order('created_at', ascending: false);
    return data.map((json) => UserListItem.fromJson(json)).toList();
  }

  Future<void> updateUser({required String userId, String? fullName, String? phoneNumber, String? address, String? accountStatus, bool? isFirstLogin, bool? isCredentialSent}) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (phoneNumber != null) updates['phone_number'] = phoneNumber;
    if (address != null) updates['address'] = address;
    if (accountStatus != null) updates['account_status'] = accountStatus;
    if (isFirstLogin != null) updates['is_first_login'] = isFirstLogin;
    if (isCredentialSent != null) updates['is_credential_sent'] = isCredentialSent;
    await sb.from('users').update(updates).eq('id', userId);
  }

  Future<void> changeUserPassword(String userId, String newPassword) async {
    await sb.client.auth.admin.updateUserById(userId, attributes: AdminUserAttributes(password: newPassword));
  }
}
