import '../domain/platform_admin_models.dart';
import 'api_helper.dart';

class AdminStoreRepository {
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
      'action': 'create-store',
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
}
