import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_helper.dart';

class AdminMgmtRepository {
  Future<List<dynamic>> getStoreAdmins() async {
    final data = await sb.from('store_admins').select('*, stores(store_name)');
    return data;
  }

  Future<void> changeAdminPassword(String adminId, String newPassword) async {
    await sb.client.auth.admin.updateUserById(adminId, attributes: AdminUserAttributes(password: newPassword));
  }
}
