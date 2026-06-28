import 'api_helper.dart';

class StoreProfileRepository {
  Future<Map<String, dynamic>> getProfile() async {
    final adminId = sb.user?.id;
    if (adminId == null) throw Exception('Not authenticated');
    final data = await sb.from('store_admins').select('*, stores(*)').eq('id', adminId).single();
    return data;
  }

  Future<void> updateProfile(Map<String, dynamic> payload) async {}
}