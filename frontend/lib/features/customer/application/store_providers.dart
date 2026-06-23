import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/customer_repositories.dart';
import '../domain/customer_models.dart';

final storeDiscoveryRepositoryProvider = Provider<StoreDiscoveryRepository>((_) => StoreDiscoveryRepository());

final deviceModelsProvider = FutureProvider.autoDispose<List<DeviceModelGroup>>((ref) async {
  final repo = ref.read(storeDiscoveryRepositoryProvider);
  return repo.getDeviceModels();
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

final featuredStoresProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.read(storeDiscoveryRepositoryProvider);
  return repo.getStores();
});
