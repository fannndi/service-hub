import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/platform_admin_repositories.dart';
import '../domain/platform_admin_models.dart';

final adminStoreRepositoryProvider = Provider<AdminStoreRepository>((_) => AdminStoreRepository());
final adminMgmtRepositoryProvider = Provider<AdminMgmtRepository>((_) => AdminMgmtRepository());

final storeListProvider = FutureProvider.autoDispose<List<StoreListItem>>((ref) async {
  final repo = ref.read(adminStoreRepositoryProvider);
  return repo.getStores();
});

final storeAdminListProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.read(adminMgmtRepositoryProvider);
  return repo.getStoreAdmins();
});
