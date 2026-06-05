import 'package:flutter/foundation.dart';

double moneyFromJson(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

DateTime? dateFromJson(Object? value) => value is String ? DateTime.tryParse(value)?.toLocal() : null;

String readString(Map<String, dynamic> json, String snake, [String? camel]) =>
    (json[snake] ?? (camel == null ? null : json[camel]) ?? '').toString();

enum OrderStatus {
  waitingDevice('waiting_device', 'Menunggu Perangkat'),
  deviceReceived('device_received', 'Perangkat Diterima'),
  diagnosing('diagnosing', 'Diagnosa'),
  waitingApproval('waiting_approval', 'Menunggu Persetujuan'),
  waitingSparepart('waiting_sparepart', 'Menunggu Sparepart'),
  repairing('repairing', 'Diperbaiki'),
  qualityCheck('quality_check', 'Quality Check'),
  waitingPayment('waiting_payment', 'Menunggu Pembayaran'),
  completed('completed', 'Selesai'),
  cancelled('cancelled', 'Dibatalkan'),
  disputed('disputed', 'Klaim Garansi');

  const OrderStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;
  bool get isActive => this != completed && this != cancelled;

  static OrderStatus parse(Object? value) => OrderStatus.values.firstWhere(
        (status) => status.apiValue == value,
        orElse: () => waitingDevice,
      );
}

@immutable
class CustomerUser {
  const CustomerUser({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.avatarUrl,
    this.address,
    this.isFirstLogin = false,
  });

  final String id;
  final String fullName;
  final String phoneNumber;
  final String? avatarUrl;
  final String? address;
  final bool isFirstLogin;

  factory CustomerUser.fromJson(Map<String, dynamic> json) => CustomerUser(
        id: readString(json, 'id'),
        fullName: readString(json, 'full_name', 'fullName'),
        phoneNumber: readString(json, 'phone_number', 'phoneNumber'),
        avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
        address: json['address'] as String?,
        isFirstLogin: json['is_first_login'] as bool? ?? json['isFirstLogin'] as bool? ?? false,
      );

  CustomerUser copyWith({String? fullName, String? address, String? avatarUrl, bool? isFirstLogin}) => CustomerUser(
        id: id,
        fullName: fullName ?? this.fullName,
        phoneNumber: phoneNumber,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        address: address ?? this.address,
        isFirstLogin: isFirstLogin ?? this.isFirstLogin,
      );
}

class LoginResult {
  const LoginResult({required this.accessToken, required this.refreshToken, required this.user, required this.isFirstLogin});
  final String accessToken;
  final String refreshToken;
  final CustomerUser user;
  final bool isFirstLogin;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final user = rawUser is Map<String, dynamic> ? CustomerUser.fromJson(rawUser) : CustomerUser.fromJson(json);
    final firstLogin = json['is_first_login'] as bool? ?? json['isFirstLogin'] as bool? ?? user.isFirstLogin;
    return LoginResult(
      accessToken: readString(json, 'access_token', 'accessToken'),
      refreshToken: readString(json, 'refresh_token', 'refreshToken'),
      user: user.copyWith(isFirstLogin: firstLogin),
      isFirstLogin: firstLogin,
    );
  }
}

class HomeSummary {
  const HomeSummary({this.activeOrders = 0, this.activeCoupons = 0, this.activeWarranties = 0});
  final int activeOrders;
  final int activeCoupons;
  final int activeWarranties;
  factory HomeSummary.fromJson(Map<String, dynamic> json) => HomeSummary(
        activeOrders: json['active_orders'] as int? ?? json['activeOrders'] as int? ?? 0,
        activeCoupons: json['active_coupons'] as int? ?? json['activeCoupons'] as int? ?? 0,
        activeWarranties: json['active_warranties'] as int? ?? json['activeWarranties'] as int? ?? 0,
      );
}

class ServiceStore {
  const ServiceStore({
    required this.id,
    required this.storeName,
    required this.address,
    required this.phoneNumber,
    this.ratingAvg = 0,
    this.reviewCount = 0,
    this.verifiedAt,
    this.operationalHours = const {},
    this.reviews = const [],
  });

  final String id;
  final String storeName;
  final String address;
  final String phoneNumber;
  final double ratingAvg;
  final int reviewCount;
  final DateTime? verifiedAt;
  final Map<String, dynamic> operationalHours;
  final List<ReviewItem> reviews;

  factory ServiceStore.fromJson(Map<String, dynamic> json) => ServiceStore(
        id: readString(json, 'id'),
        storeName: readString(json, 'store_name', 'storeName'),
        address: readString(json, 'address'),
        phoneNumber: readString(json, 'phone_number', 'phoneNumber'),
        ratingAvg: moneyFromJson(json['rating_avg'] ?? json['ratingAvg']),
        reviewCount: json['review_count'] as int? ?? json['reviewCount'] as int? ?? json['totalReviews'] as int? ?? 0,
        verifiedAt: dateFromJson(json['verified_at'] ?? json['verifiedAt']),
        operationalHours: json['operational_hours'] is Map<String, dynamic>
            ? json['operational_hours'] as Map<String, dynamic>
            : json['operationalHours'] is Map<String, dynamic>
                ? json['operationalHours'] as Map<String, dynamic>
                : const {},
        reviews: (json['reviews'] as List? ?? const []).whereType<Map<String, dynamic>>().map(ReviewItem.fromJson).toList(),
      );
}

class SparePart {
  const SparePart({
    required this.id,
    required this.storeId,
    required this.brand,
    required this.deviceModel,
    required this.partType,
    required this.partName,
    required this.price,
    this.qty = 0,
    this.qtyReserved = 0,
  });

  final String id;
  final String storeId;
  final String brand;
  final String deviceModel;
  final String partType;
  final String partName;
  final double price;
  final int qty;
  final int qtyReserved;
  int get availableQty => qty - qtyReserved;

  factory SparePart.fromJson(Map<String, dynamic> json) => SparePart(
        id: readString(json, 'id'),
        storeId: readString(json, 'store_id', 'storeId'),
        brand: readString(json, 'brand'),
        deviceModel: readString(json, 'device_model', 'deviceModel'),
        partType: readString(json, 'part_type', 'partType'),
        partName: readString(json, 'part_name', 'partName'),
        price: moneyFromJson(json['price']),
        qty: json['qty'] as int? ?? 0,
        qtyReserved: json['qty_reserved'] as int? ?? json['qtyReserved'] as int? ?? 0,
      );
}

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
        sparepartId: json['sparepart_id'] as String? ?? json['sparepartId'] as String?,
        sparepartName: json['sparepart_name'] as String? ?? json['sparepartName'] as String?,
        itemPrice: moneyFromJson(json['item_price'] ?? json['itemPrice']),
        finalItemPrice: json['final_item_price'] == null && json['finalItemPrice'] == null
            ? null
            : moneyFromJson(json['final_item_price'] ?? json['finalItemPrice']),
        status: readString(json, 'status'),
        technicianNote: json['technician_note'] as String? ?? json['technicianNote'] as String?,
      );
}

class TrackingEntry {
  const TrackingEntry({required this.id, required this.status, this.note, required this.createdAt});
  final String id;
  final OrderStatus status;
  final String? note;
  final DateTime createdAt;

  factory TrackingEntry.fromJson(Map<String, dynamic> json) => TrackingEntry(
        id: readString(json, 'id'),
        status: OrderStatus.parse(json['status']),
        note: json['note'] as String?,
        createdAt: dateFromJson(json['created_at'] ?? json['createdAt']) ?? DateTime.now(),
      );
}

class PaymentRecord {
  const PaymentRecord({required this.id, required this.amount, required this.paymentMethod, required this.paymentType, required this.status, this.proofUrl, required this.createdAt});
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
        createdAt: dateFromJson(json['created_at'] ?? json['createdAt']) ?? DateTime.now(),
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
    final store = json['store'] is Map<String, dynamic> ? json['store'] as Map<String, dynamic> : <String, dynamic>{};
    final storeName = readString(store, 'store_name', 'storeName');
    return CustomerOrder(
      id: readString(json, 'id'),
      orderNumber: readString(json, 'order_number', 'orderNumber'),
      status: OrderStatus.parse(json['status']),
      brand: readString(json, 'brand'),
      deviceModel: readString(json, 'device_model', 'deviceModel'),
      deviceType: readString(json, 'device_type', 'deviceType'),
      deliveryMethod: readString(json, 'delivery_method', 'deliveryMethod'),
      deliveryAddress: json['delivery_address'] as String? ?? json['deliveryAddress'] as String?,
      storeName: storeName.isEmpty ? json['storeName'] as String? : storeName,
      storeAddress: store['address'] as String? ?? json['storeAddress'] as String?,
      storePhone: store['phone_number'] as String? ?? store['phoneNumber'] as String? ?? json['storePhone'] as String?,
      totalEstimasi: moneyFromJson(json['total_estimasi'] ?? json['totalEstimasi']),
      discountAmount: moneyFromJson(json['discount_amount'] ?? json['discountAmount']),
      finalPrice: json['final_price'] == null && json['finalPrice'] == null ? null : moneyFromJson(json['final_price'] ?? json['finalPrice']),
      serviceFee: json['service_fee'] == null && json['serviceFee'] == null ? null : moneyFromJson(json['service_fee'] ?? json['serviceFee']),
      diagnosisNote: json['diagnosis_note'] as String? ?? json['diagnosisNote'] as String?,
      paymentStatus: readString(json, 'payment_status', 'paymentStatus'),
      warrantyExpiredAt: dateFromJson(json['warranty_expired_at'] ?? json['warrantyExpiredAt']),
      slaDeadline: dateFromJson(json['sla_deadline'] ?? json['slaDeadline']),
      createdAt: dateFromJson(json['created_at'] ?? json['createdAt']),
      items: (json['items'] as List? ?? const []).whereType<Map<String, dynamic>>().map(OrderItem.fromJson).toList(),
      tracking: (json['tracking'] as List? ?? const []).whereType<Map<String, dynamic>>().map(TrackingEntry.fromJson).toList(),
      payments: (json['payments'] as List? ?? const []).whereType<Map<String, dynamic>>().map(PaymentRecord.fromJson).toList(),
      reviewed: json['reviewed'] as bool? ?? json['hasReview'] as bool? ?? json['review'] != null,
    );
  }
}

class CreateOrderItemInput {
  const CreateOrderItemInput({required this.serviceType, required this.complaint, this.sparepartId, this.price = 0});
  final String serviceType;
  final String complaint;
  final String? sparepartId;
  final double price;
  Map<String, dynamic> toJson() => {'serviceType': serviceType, 'complaint': complaint, if (sparepartId != null) 'sparepartId': sparepartId};
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
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'deviceType': deviceType,
        'brand': brand,
        'deviceModel': deviceModel,
        'deliveryMethod': deliveryMethod,
        if (deliveryAddress != null && deliveryAddress!.isNotEmpty) 'deliveryAddress': deliveryAddress,
        if (couponCode != null && couponCode!.isNotEmpty) 'couponCode': couponCode,
        'items': items.map((item) => item.toJson()).toList(),
      };
}

class CreateOrderResult {
  const CreateOrderResult({required this.id, required this.orderNumber, required this.status, required this.totalEstimasi, required this.isNewCustomer, required this.message});
  final String id;
  final String orderNumber;
  final OrderStatus status;
  final double totalEstimasi;
  final bool isNewCustomer;
  final String message;
  factory CreateOrderResult.fromJson(Map<String, dynamic> json) => CreateOrderResult(
        id: readString(json, 'id'),
        orderNumber: readString(json, 'order_number', 'orderNumber'),
        status: OrderStatus.parse(json['status']),
        totalEstimasi: moneyFromJson(json['total_estimasi'] ?? json['totalEstimasi']),
        isNewCustomer: json['is_new_customer'] as bool? ?? json['isNewCustomer'] as bool? ?? false,
        message: readString(json, 'message'),
      );
}

class ReviewItem {
  const ReviewItem({required this.id, required this.rating, this.comment, this.customerName, required this.createdAt});
  final String id;
  final int rating;
  final String? comment;
  final String? customerName;
  final DateTime createdAt;
  factory ReviewItem.fromJson(Map<String, dynamic> json) => ReviewItem(
        id: readString(json, 'id'),
        rating: json['rating'] as int? ?? 0,
        comment: json['comment'] as String?,
        customerName: json['customer_name'] as String? ?? json['customerName'] as String?,
        createdAt: dateFromJson(json['created_at'] ?? json['createdAt']) ?? DateTime.now(),
      );
}

class CouponReward {
  const CouponReward({required this.code, required this.amount, required this.expiredAt});
  final String code;
  final double amount;
  final DateTime expiredAt;
  factory CouponReward.fromJson(Map<String, dynamic> json) => CouponReward(
        code: readString(json, 'code'),
        amount: moneyFromJson(json['amount']),
        expiredAt: dateFromJson(json['expired_at'] ?? json['expiredAt']) ?? DateTime.now(),
      );
}

class ReviewResult {
  const ReviewResult({required this.review, this.coupon});
  final ReviewItem review;
  final CouponReward? coupon;
  factory ReviewResult.fromJson(Map<String, dynamic> json) => ReviewResult(
        review: ReviewItem.fromJson(json['review'] as Map<String, dynamic>),
        coupon: json['coupon'] is Map<String, dynamic> ? CouponReward.fromJson(json['coupon'] as Map<String, dynamic>) : null,
      );
}

class NotificationItem {
  const NotificationItem({required this.id, required this.title, required this.message, required this.createdAt, this.isRead = false});
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
        id: readString(json, 'id'),
        title: readString(json, 'title'),
        message: readString(json, 'message'),
        createdAt: dateFromJson(json['created_at'] ?? json['createdAt']) ?? DateTime.now(),
        isRead: json['is_read'] as bool? ?? json['isRead'] as bool? ?? false,
      );
}
