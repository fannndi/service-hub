import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/store_admin_repositories.dart';
import '../domain/store_admin_models.dart';

final paymentsProvider = AsyncNotifierProvider<PaymentsController, PageResult<PaymentRecord>>(PaymentsController.new);

final storePaymentRepositoryProvider = Provider<StorePaymentRepository>((_) => StorePaymentRepository());

class PaymentsController extends AsyncNotifier<PageResult<PaymentRecord>> {
  @override
  Future<PageResult<PaymentRecord>> build() async {
    final repo = ref.read(storePaymentRepositoryProvider);
    final result = await repo.getPayments();
    return PageResult(items: (result['items'] as List).map((j) => PaymentRecord.fromJson(j as Map<String, dynamic>)).toList(), total: result['total'] as int, page: 1, limit: 20);
  }

  Future<void> confirm(String orderId, String paymentId) async {
    final repo = ref.read(storePaymentRepositoryProvider);
    await repo.confirmPayment(orderId, paymentId);
    ref.invalidateSelf();
  }
}
