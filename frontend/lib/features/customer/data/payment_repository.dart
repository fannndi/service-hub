import 'api_helper.dart';

class PaymentRepository {
  Future<void> createPayment(String orderId, {required int amount, required String paymentMethod, required String paymentType, String? proofUrl}) async {
    final uid = sb.user?.id;
    if (uid == null) throw Exception('Not authenticated');
    await sb.from('payments').insert({
      'order_id': orderId,
      'user_id': uid,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_type': paymentType,
      'proof_url': proofUrl,
    });
  }
}