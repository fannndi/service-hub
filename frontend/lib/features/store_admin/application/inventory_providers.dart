import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/store_admin_repositories.dart';
import '../domain/store_admin_models.dart';

final storeInventoryRepositoryProvider = Provider<StoreInventoryRepository>((_) => StoreInventoryRepository());

class InventoryQuery {
  final String? search;
  final String? brand;
  final String? deviceModel;
  final String? partType;
  final int page;
  InventoryQuery({this.search, this.brand, this.deviceModel, this.partType, this.page = 1});
  InventoryQuery copyWith({String? search, String? brand, String? deviceModel, String? partType, int? page}) => InventoryQuery(
    search: search ?? this.search, brand: brand ?? this.brand, deviceModel: deviceModel ?? this.deviceModel,
    partType: partType ?? this.partType, page: page ?? this.page,
  );
}

final inventoryQueryProvider = StateProvider<InventoryQuery>((_) => InventoryQuery());

final inventoryProvider = AsyncNotifierProvider<InventoryController, PageResult<Sparepart>>(InventoryController.new);

class InventoryController extends AsyncNotifier<PageResult<Sparepart>> {
  @override
  Future<PageResult<Sparepart>> build() => _fetch();

  Future<PageResult<Sparepart>> _fetch() async {
    final repo = ref.read(storeInventoryRepositoryProvider);
    final query = ref.read(inventoryQueryProvider);
    final result = await repo.getSpareparts(search: query.search, brand: query.brand, deviceModel: query.deviceModel, partType: query.partType, page: query.page);
    return PageResult(items: (result['items'] as List).map((j) => Sparepart.fromJson(j)).toList(), total: result['total'] as int, page: query.page, limit: 20);
  }

  Future<void> save(Map<String, dynamic> data, {String? id}) async {
    final repo = ref.read(storeInventoryRepositoryProvider);
    await repo.saveSparepart(data, id: id);
    ref.invalidateSelf();
  }

  Future<void> adjustStock(String id, int delta) async {
    final repo = ref.read(storeInventoryRepositoryProvider);
    await repo.adjustStock(id, delta);
    ref.invalidateSelf();
  }
}

final brandsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final repo = ref.read(storeInventoryRepositoryProvider);
  return repo.getBrands();
});

final deviceModelsProvider = FutureProvider.autoDispose.family<List<String>, String?>((ref, brand) async {
  final repo = ref.read(storeInventoryRepositoryProvider);
  return repo.getDeviceModels(brand);
});
