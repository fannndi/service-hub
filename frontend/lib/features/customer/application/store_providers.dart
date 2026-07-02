import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/customer_repositories.dart';
import '../domain/customer_models.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/cache/cache_config.dart';

final storeDiscoveryRepositoryProvider = Provider<StoreDiscoveryRepository>((_) => StoreDiscoveryRepository());

final deviceModelsProvider = FutureProvider<List<DeviceModelGroup>>((ref) async {
  final cache = CacheManager.instance;
  final cached = await cache.getAsync<List<dynamic>>('device_models', ttl: CacheConfig.deviceModels);
  if (cached != null) {
    return cached.map((e) => DeviceModelGroup.fromJson(e as Map<String, dynamic>)).toList();
  }
  final repo = ref.read(storeDiscoveryRepositoryProvider);
  final data = await repo.getDeviceModels();
  await cache.set('device_models', data.map((e) => e.toJson()).toList(), ttl: CacheConfig.deviceModels);
  return data;
});

final storeListProvider = FutureProvider.autoDispose.family<List<ServiceStore>, ({String? brand, String? model})>((ref, params) async {
  final repo = ref.read(storeDiscoveryRepositoryProvider);
  return repo.getStores(brand: params.brand, model: params.model);
});

final storeDetailProvider = FutureProvider.autoDispose.family<ServiceStore, String>((ref, id) async {
  final repo = ref.read(storeDiscoveryRepositoryProvider);
  return repo.getDetail(id);
});

final sparepartsProvider = FutureProvider.autoDispose.family<List<SparePart>, String>((ref, storeId) async {
  final repo = ref.read(storeDiscoveryRepositoryProvider);
  return repo.getSpareparts(storeId);
});

final featuredStoresProvider = FutureProvider<List<ServiceStore>>((ref) async {
  final cache = CacheManager.instance;
  final cached = await cache.getAsync<List<dynamic>>('featured_stores', ttl: CacheConfig.stores);
  if (cached != null) {
    return cached.map((e) => ServiceStore.fromJson(e as Map<String, dynamic>)).toList();
  }
  final repo = ref.read(storeDiscoveryRepositoryProvider);
  final data = await repo.getStores();
  await cache.set('featured_stores', data.map((e) => {
    'id': e.id, 'store_name': e.storeName, 'address': e.address,
    'phone_number': e.phoneNumber, 'rating_avg': e.ratingAvg,
  }).toList(), ttl: CacheConfig.stores);
  return data;
});
