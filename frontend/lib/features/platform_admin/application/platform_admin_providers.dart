import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/app_config.dart';
import '../data/platform_admin_repositories.dart';
import '../domain/platform_admin_models.dart';

final adminStorageProvider = Provider<AdminSessionStorage>(
    (ref) => const AdminSessionStorage(FlutterSecureStorage()));
final adminApiClientProvider = Provider<AdminApiClient>((ref) => AdminApiClient(
    ref.watch(appConfigProvider), ref.watch(adminStorageProvider)));
final adminRepositoryProvider = Provider<AdminRepository>((ref) =>
    AdminRepository(
        ref.watch(adminApiClientProvider), ref.watch(adminStorageProvider)));

class AdminAuthNotifier extends AsyncNotifier<AdminSession?> {
  @override
  Future<AdminSession?> build() async {
    final token = await ref.read(adminStorageProvider).readToken();
    if (token == null) return null;
    try {
      await ref.read(adminRepositoryProvider).listStores();
      final cached = await ref.read(adminStorageProvider).readSession();
      if (cached != null) return cached;
    } catch (_) {}
    await ref.read(adminStorageProvider).clear();
    return null;
  }

  Future<AdminSession> login(String username, String password) async {
    state = const AsyncLoading();
    final result =
        await ref.read(adminRepositoryProvider).login(username, password);
    state = AsyncData(result.admin);
    return result.admin;
  }

  Future<void> logout() async {
    await ref.read(adminStorageProvider).clear();
    state = const AsyncData(null);
  }
}

final adminAuthProvider =
    AsyncNotifierProvider<AdminAuthNotifier, AdminSession?>(
        AdminAuthNotifier.new);

final storeListProvider = FutureProvider<List<StoreListItem>>((ref) {
  return ref.watch(adminRepositoryProvider).listStores();
});
