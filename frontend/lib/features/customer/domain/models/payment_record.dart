import '../../../../core/json_helpers.dart';

class PaymentRecord {
  const PaymentRecord(
      {required this.id,
      required this.amount,
      required this.paymentMethod,
      required this.paymentType,
      required this.status,
      this.proofUrl,
      required this.createdAt});
  final String id;
  final double amount;
  final String paymentMethod;
  final String paymentType;
  final String status;
  final String? proofUrl;
  final DateTime createdAt;

  factory PaymentRecord.fromJson(Map<String, dynamic> json) => PaymentRecord(
        id: readString(json, 'id'),
        amount: moneyFromJson(json['amount']),
        paymentMethod: readString(json, 'payment_method', 'paymentMethod'),
        paymentType: readString(json, 'payment_type', 'paymentType'),
        status: readString(json, 'status'),
        proofUrl: json['proof_url'] as String? ?? json['proofUrl'] as String?,
        createdAt: dateFromJson(json['created_at'] ?? json['createdAt']) ??
            DateTime.now(),
      );
}
