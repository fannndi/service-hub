import '../../../../core/json_helpers.dart';
import '../../../../core/domain/order_status.dart' show OrderStatus;
import 'order_item.dart';
import 'tracking_entry.dart';
import 'payment_record.dart';

class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.brand,
    required this.deviceModel,
    required this.deviceType,
    required this.deliveryMethod,
    this.deliveryAddress,
    this.storeName,
    this.storeAddress,
    this.storePhone,
    this.totalEstimasi = 0,
    this.discountAmount = 0,
    this.finalPrice,
    this.serviceFee,
    this.diagnosisNote,
    this.paymentStatus = 'unpaid',
    this.warrantyExpiredAt,
    this.slaDeadline,
    this.createdAt,
    this.items = const [],
    this.tracking = const [],
    this.payments = const [],
    this.reviewed = false,
  });

  final String id;
  final String orderNumber;
  final OrderStatus status;
  final String brand;
  final String deviceModel;
  final String deviceType;
  final String deliveryMethod;
  final String? deliveryAddress;
  final String? storeName;
  final String? storeAddress;
  final String? storePhone;
  final double totalEstimasi;
  final double discountAmount;
  final double? finalPrice;
  final double? serviceFee;
  final String? diagnosisNote;
  final String paymentStatus;
  final DateTime? warrantyExpiredAt;
  final DateTime? slaDeadline;
  final DateTime? createdAt;
  final List<OrderItem> items;
  final List<TrackingEntry> tracking;
  final List<PaymentRecord> payments;
  final bool reviewed;

  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    final store = json['store'] is Map<String, dynamic>
        ? json['store'] as Map<String, dynamic>
        : <String, dynamic>{};
    final storeName = readString(store, 'store_name', 'storeName');
    return CustomerOrder(
      id: readString(json, 'id'),
      orderNumber: readString(json, 'order_number', 'orderNumber'),
      status: OrderStatus.fromJson(json['status']),
      brand: readString(json, 'brand'),
      deviceModel: readString(json, 'device_model', 'deviceModel'),
      deviceType: readString(json, 'device_type', 'deviceType'),
      deliveryMethod: readString(json, 'delivery_method', 'deliveryMethod'),
      deliveryAddress: json['delivery_address'] as String? ??
          json['deliveryAddress'] as String?,
      storeName: storeName.isEmpty ? json['storeName'] as String? : storeName,
      storeAddress:
          store['address'] as String? ?? json['storeAddress'] as String?,
      storePhone: store['phone_number'] as String? ??
          store['phoneNumber'] as String? ??
          json['storePhone'] as String?,
      totalEstimasi:
          moneyFromJson(json['total_estimasi'] ?? json['totalEstimasi']),
      discountAmount:
          moneyFromJson(json['discount_amount'] ?? json['discountAmount']),
      finalPrice: json['final_price'] == null && json['finalPrice'] == null
          ? null
          : moneyFromJson(json['final_price'] ?? json['finalPrice']),
      serviceFee: json['service_fee'] == null && json['serviceFee'] == null
          ? null
          : moneyFromJson(json['service_fee'] ?? json['serviceFee']),
      diagnosisNote:
          json['diagnosis_note'] as String? ?? json['diagnosisNote'] as String?,
      paymentStatus: readString(json, 'payment_status', 'paymentStatus'),
      warrantyExpiredAt: dateFromJson(
          json['warranty_expired_at'] ?? json['warrantyExpiredAt']),
      slaDeadline: dateFromJson(json['sla_deadline'] ?? json['slaDeadline']),
      createdAt: dateFromJson(json['created_at'] ?? json['createdAt']),
      items: (json['items'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(OrderItem.fromJson)
          .toList(),
      tracking: (json['tracking'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(TrackingEntry.fromJson)
          .toList(),
      payments: (json['payments'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PaymentRecord.fromJson)
          .toList(),
      reviewed: json['reviewed'] as bool? ??
          json['hasReview'] as bool? ??
          json['review'] != null,
    );
  }
}
