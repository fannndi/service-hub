import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/store_admin_repositories.dart';

final storeCustomerRepositoryProvider = Provider<StoreCustomerRepository>((_) => StoreCustomerRepository());

final customersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.read(storeCustomerRepositoryProvider);
  final result = await repo.getCustomers();
  return result['items'] as List<dynamic>;
});
