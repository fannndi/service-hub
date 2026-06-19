import '../../../core/json_helpers.dart';
import '../../../core/domain/order_status.dart' show OrderStatus;

class OrderItem {
  const OrderItem({
    required this.id,
    required this.serviceType,
    required this.complaint,
    this.sparepartId,
    this.sparepartName,
    this.itemPrice = 0,
    this.finalItemPrice,
    this.status = 'pending',
    this.technicianNote,
  });

  final String id;
  final String serviceType;
  final String complaint;
  final String? sparepartId;
  final String? sparepartName;
  final double itemPrice;
  final double? finalItemPrice;
  final String status;
  final String? technicianNote;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: readString(json, 'id'),
        serviceType: readString(json, 'service_type', 'serviceType'),
        complaint: readString(json, 'complaint'),
        sparepartId:
            json['sparepart_id'] as String? ?? json['sparepartId'] as String?,
        sparepartName: json['sparepart_name'] as String? ??
            json['sparepartName'] as String?,
        itemPrice: moneyFromJson(json['item_price'] ?? json['itemPrice']),
        finalItemPrice: json['final_item_price'] == null &&
                json['finalItemPrice'] == null
            ? null
            : moneyFromJson(json['final_item_price'] ?? json['finalItemPrice']),
        status: readString(json, 'status'),
        technicianNote: json['technician_note'] as String? ??
            json['technicianNote'] as String?,
      );
}

class TrackingEntry {
  const TrackingEntry(
      {required this.id,
      required this.status,
      this.note,
      required this.createdAt});
  final String id;
  final OrderStatus status;
  final String? note;
  final DateTime createdAt;

  factory TrackingEntry.fromJson(Map<String, dynamic> json) => TrackingEntry(
        id: readString(json, 'id'),
        status: OrderStatus.fromJson(json['status']),
        note: json['note'] as String?,
        createdAt: dateFromJson(json['created_at'] ?? json['createdAt']) ??
            DateTime.now(),
      );
}

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

class CreateOrderItemInput {
  const CreateOrderItemInput(
      {required this.serviceType,
      required this.complaint,
      this.sparepartId,
      this.itemPrice = 0});
  final String serviceType;
  final String complaint;
  final String? sparepartId;
  final double itemPrice;
  Map<String, dynamic> toJson() => {
        'serviceType': serviceType,
        'complaint': complaint,
        if (sparepartId != null) 'sparepartId': sparepartId,
      };
}

class CreateOrderRequest {
  const CreateOrderRequest({
    required this.storeId,
    required this.fullName,
    required this.phoneNumber,
    required this.deviceType,
    required this.brand,
    required this.deviceModel,
    required this.deliveryMethod,
    this.deliveryAddress,
    this.couponCode,
    required this.items,
  });

  final String storeId;
  final String fullName;
  final String phoneNumber;
  final String deviceType;
  final String brand;
  final String deviceModel;
  final String deliveryMethod;
  final String? deliveryAddress;
  final String? couponCode;
  final List<CreateOrderItemInput> items;

  Map<String, dynamic> toJson() => {
        'storeId': storeId,
        'customerName': fullName,
        'phoneNumber': phoneNumber,
        'deviceType': deviceType,
        'brand': brand,
        'deviceModel': deviceModel,
        'deliveryMethod': deliveryMethod,
        if (deliveryAddress != null && deliveryAddress!.isNotEmpty)
          'deliveryAddress': deliveryAddress,
        if (couponCode != null && couponCode!.isNotEmpty)
          'couponCode': couponCode,
        'items': items.map((item) => item.toJson()).toList(),
      };
}

class CreateOrderResult {
  const CreateOrderResult(
      {required this.id,
      required this.orderNumber,
      required this.status,
      required this.totalEstimasi,
      required this.isNewCustomer,
      required this.message});
  final String id;
  final String orderNumber;
  final OrderStatus status;
  final double totalEstimasi;
  final bool isNewCustomer;
  final String message;
  factory CreateOrderResult.fromJson(Map<String, dynamic> json) =>
      CreateOrderResult(
        id: readString(json, 'id'),
        orderNumber: readString(json, 'order_number', 'orderNumber'),
        status: OrderStatus.fromJson(json['status']),
        totalEstimasi:
            moneyFromJson(json['total_estimasi'] ?? json['totalEstimasi']),
        isNewCustomer: json['is_new_customer'] as bool? ??
            json['isNewCustomer'] as bool? ??
            false,
        message: readString(json, 'message'),
      );
}
