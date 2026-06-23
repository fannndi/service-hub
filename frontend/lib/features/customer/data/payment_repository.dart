import 'api_helper.dart';

class PaymentRepository {
  Future<void> createPayment(String orderId, {required int amount, required String paymentMethod, required String paymentType, String? proofUrl}) async {
    await sb.from('payments').insert({
      'order_id': orderId,
      'user_id': sb.user!.id,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_type': paymentType,
      'proof_url': proofUrl,
    });
  }
}
