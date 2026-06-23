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
