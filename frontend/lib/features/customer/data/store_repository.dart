import '../domain/customer_models.dart';
import 'api_helper.dart';

class StoreDiscoveryRepository {
  Future<List<ServiceStore>> getStores({String? brand, String? model}) async {
    var q = sb.from('stores').select('*').eq('is_active', true);
    if (brand != null && brand != 'All') q = q.eq('brand', brand);
    if (model != null && model.isNotEmpty) q = q.ilike('device_model', '%$model%');
    final data = await q.order('created_at', ascending: false).limit(20);
    return data.map((json) => ServiceStore.fromJson(json)).toList();
  }

  Future<List<DeviceModelGroup>> getDeviceModels() async {
    final data = await sb.client.rpc('get_device_models');
    return (data as List).map((json) => DeviceModelGroup.fromJson(json)).toList();
  }

  Future<List<StoreMatchResult>> matchStores({required String brand, required String deviceModel, required String partType}) async {
    final data = await sb.from('stores').select('''
      id, store_name, address, phone_number, rating_avg,
      spareparts!inner(brand, device_model, part_type, part_name, price, qty, qty_reserved)
    ''').eq('is_active', true).eq('spareparts.brand', brand).eq('spareparts.device_model', deviceModel).eq('spareparts.part_type', partType);
    final results = data.map((json) => StoreMatchResult.fromJson(json)).toList();
    return _dedupeStores(results);
  }

  List<StoreMatchResult> _dedupeStores(List<StoreMatchResult> stores) {
    final map = <String, StoreMatchResult>{};
    for (final store in stores) {
      final existing = map[store.storeId];
      if (existing != null) {
        map[store.storeId] = StoreMatchResult(
          storeId: store.storeId,
          storeName: store.storeName,
          address: store.address,
          phoneNumber: store.phoneNumber,
          ratingAvg: store.ratingAvg,
          totalCompleted: store.totalCompleted,
          spareparts: [...existing.spareparts, ...store.spareparts],
          estimatedCost: store.estimatedCost,
        );
      } else {
        map[store.storeId] = store;
      }
    }
    return map.values.toList();
  }

  Future<ServiceStore> getDetail(String storeId) async {
    final data = await sb.from('stores').select('*, reviews(*, users(full_name))').eq('id', storeId).single();
    return ServiceStore.fromJson(data);
  }

  Future<List<SparePart>> getSpareparts(String storeId) async {
    final data = await sb.from('spareparts').select('*').eq('store_id', storeId).eq('status', 'available');
    return data.map((json) => SparePart.fromJson(json)).toList();
  }
}
