import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/store_admin_repositories.dart';
import '../domain/store_admin_models.dart';

final disputesProvider = AsyncNotifierProvider<DisputesController, PageResult<DisputeCase>>(DisputesController.new);

final storeDisputeRepositoryProvider = Provider<StoreDisputeRepository>((_) => StoreDisputeRepository());

class DisputesController extends AsyncNotifier<PageResult<DisputeCase>> {
  @override
  Future<PageResult<DisputeCase>> build() async {
    final repo = ref.read(storeDisputeRepositoryProvider);
    final result = await repo.getDisputes();
    return PageResult(items: (result['items'] as List).map((j) => DisputeCase.fromJson(j)).toList(), total: result['total'] as int, page: 1, limit: 20);
  }

  Future<void> resolve(String disputeId, bool accept, String reason) async {
    final repo = ref.read(storeDisputeRepositoryProvider);
    await repo.resolveDispute(disputeId, accept, reason);
    ref.invalidateSelf();
  }
}
