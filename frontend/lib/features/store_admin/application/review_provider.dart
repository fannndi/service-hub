import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/store_admin_repositories.dart';

final storeReviewRepositoryProvider = Provider<StoreReviewRepository>((_) => StoreReviewRepository());

final reviewsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.read(storeReviewRepositoryProvider);
  final result = await repo.getReviews();
  return result['items'] as List<dynamic>;
});
