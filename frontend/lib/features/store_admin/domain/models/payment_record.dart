import '../../../../core/json_helpers.dart';
import '../store_admin_enums.dart';

class PaymentRecord {
  const PaymentRecord(
      {required this.id,
      required this.amount,
      required this.method,
      required this.status,
      required this.createdAt,
      this.proofUrl});
  final String id;
  final num amount;
  final String method;
  final PaymentRecordStatus status;
  final DateTime createdAt;
  final String? proofUrl;

  factory PaymentRecord.fromJson(Map<String, dynamic> json) => PaymentRecord(
        id: jsonString(json['id']),
        amount: jsonNum(json['amount']),
        method: jsonString(json['paymentMethod'] ?? json['payment_method'],
            fallback: 'transfer_bank'),
        status: PaymentRecordStatus.fromJson(json['status']),
        createdAt: jsonDate(json['createdAt'] ?? json['created_at']),
        proofUrl: json['proofUrl'] as String? ?? json['proof_url'] as String?,
      );
}
