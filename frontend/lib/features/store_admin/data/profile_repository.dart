import 'api_helper.dart';

class StoreProfileRepository {
  Future<Map<String, dynamic>> getProfile() async {
    final data = await sb.from('store_admins').select('*, stores(*)').eq('id', sb.user!.id).single();
    return data;
  }

  Future<void> updateProfile(Map<String, dynamic> payload) async {}
}
