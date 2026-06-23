import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/store_admin_repositories.dart';

final storeProfileRepositoryProvider = Provider<StoreProfileRepository>((_) => StoreProfileRepository());

final storeProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.read(storeProfileRepositoryProvider);
  return repo.getProfile();
});
