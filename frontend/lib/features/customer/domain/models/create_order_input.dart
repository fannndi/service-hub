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
        'service_type': serviceType,
        'complaint': complaint,
        if (sparepartId != null) 'sparepart_id': sparepartId,
        if (itemPrice > 0) 'item_price': itemPrice,
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
        'store_id': storeId,
        'customer_name': fullName,
        'phone_number': phoneNumber,
        'device_type': deviceType,
        'brand': brand,
        'device_model': deviceModel,
        'delivery_method': deliveryMethod,
        if (deliveryAddress != null && deliveryAddress!.isNotEmpty)
          'delivery_address': deliveryAddress,
        if (couponCode != null && couponCode!.isNotEmpty)
          'coupon_code': couponCode,
        'items': items.map((item) => item.toJson()).toList(),
      };
}
