import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/platform_admin_models.dart';
import '../../core/supabase_service.dart';
import '../../core/supabase_config.dart';

final sb = SupabaseService.instance;

class AdminAuthRepository {
  Future<PlatformAdminUser> login(String username, String password) async {
    final email = SupabaseConfig.buildPlatformAdminEmail(username);
    await sb.signIn(email, password);
    return PlatformAdminUser(id: sb.user!.id, username: username, fullName: 'Admin');
  }

  Future<void> logout() => sb.signOut();
}

class AdminRepository {
  Future<List<StoreListItem>> getStores() async {
    final data = await sb.from('stores').select('*, admins:store_admins(full_name, phone_number)');
    return data.map((json) => StoreListItem.fromJson(json)).toList();
  }

  Future<void> createStore({
    required String storeName, required String address, required String storePhone,
    required String adminName, required String adminPhone, required String password,
    bool handlesAndroid = true, bool handlesIos = true,
  }) async {
    await sb.invoke('admin', body: {
      'path': 'create-store',
      'store_name': storeName, 'address': address, 'store_phone': storePhone,
      'admin_name': adminName, 'admin_phone': adminPhone, 'password': password,
      'handles_android': handlesAndroid, 'handles_ios': handlesIos,
    });
  }

  Future<void> updateStore({required String storeId, String? storeName, String? address, String? phoneNumber, bool? isActive}) async {
    final updates = <String, dynamic>{};
    if (storeName != null) updates['store_name'] = storeName;
    if (address != null) updates['address'] = address;
    if (phoneNumber != null) updates['phone_number'] = phoneNumber;
    if (isActive != null) updates['is_active'] = isActive;
    await sb.from('stores').update(updates).eq('id', storeId);
  }

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
    await sb.client.auth.admin.updateUserById(userId, attributes: UserAttributes(password: newPassword));
  }

  Future<List<dynamic>> getStoreAdmins() async {
    final data = await sb.from('store_admins').select('*, stores(store_name)');
    return data;
  }

  Future<void> changeAdminPassword(String adminId, String newPassword) async {
    await sb.client.auth.admin.updateUserById(adminId, attributes: UserAttributes(password: newPassword));
  }
}
