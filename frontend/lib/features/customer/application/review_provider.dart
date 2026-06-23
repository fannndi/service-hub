import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/customer_repositories.dart';
import '../domain/customer_models.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((_) => ReviewRepository());

final couponsProvider = FutureProvider.autoDispose<List<CouponReward>>((ref) async {
  final repo = ref.read(reviewRepositoryProvider);
  return repo.getCoupons();
});
