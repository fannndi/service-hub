import 'api_helper.dart';

class StoreInventoryRepository {
  String get storeId => sb.storeId ?? '';

  Future<Map<String, dynamic>> getSpareparts({String? search, String? brand, String? deviceModel, String? partType, int page = 1}) async {
    var query = sb.from('spareparts').select('*').eq('store_id', storeId);
    if (search != null && search.isNotEmpty) query = query.ilike('part_name', '%$search%');
    if (brand != null) query = query.eq('brand', brand);
    if (deviceModel != null) query = query.eq('device_model', deviceModel);
    if (partType != null) query = query.eq('part_type', partType);
    final items = await query.order('created_at', ascending: false).range((page - 1) * 20, page * 20 - 1);
    return {'items': items, 'total': items.length};
  }

  Future<void> saveSparepart(Map<String, dynamic> data, {String? id}) async {
    if (id != null) {
      await sb.from('spareparts').update(data).eq('id', id);
    } else {
      await sb.from('spareparts').insert({...data, 'store_id': storeId});
    }
  }

  Future<void> adjustStock(String sparepartId, int delta) async {
    final item = await sb.from('spareparts').select('qty').eq('id', sparepartId).single();
    final newQty = (item['qty'] as int? ?? 0) + delta;
    await sb.from('spareparts').update({'qty': newQty}).eq('id', sparepartId);
  }

  Future<List<String>> getBrands() async {
    final data = await sb.from('spareparts').select('brand').eq('store_id', storeId);
    return data.map((d) => d['brand'] as String? ?? '').toSet().toList()..sort();
  }

  Future<List<String>> getDeviceModels(String? brand) async {
    var q = sb.from('spareparts').select('device_model').eq('store_id', storeId);
    if (brand != null) q = q.eq('brand', brand);
    final data = await q;
    return data.map((d) => d['device_model'] as String? ?? '').toSet().toList()..sort();
  }
}