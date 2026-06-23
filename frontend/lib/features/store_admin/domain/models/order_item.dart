import '../../../../core/json_helpers.dart';

class OrderItem {
  const OrderItem(
      {required this.id,
      required this.serviceType,
      required this.complaint,
      required this.sparepartName,
      required this.price,
      required this.status});
  final String id;
  final String serviceType;
  final String complaint;
  final String sparepartName;
  final num price;
  final String status;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: jsonString(json['id']),
        serviceType: jsonString(json['serviceType'] ?? json['service_type'],
            fallback: 'Service'),
        complaint: jsonString(json['complaint'] ?? json['description']),
        sparepartName: jsonString(
            json['sparepartName'] ?? json['sparepart_name'],
            fallback: '-'),
        price:
            jsonNum(json['itemPrice'] ?? json['item_price'] ?? json['price']),
        status: jsonString(json['status'], fallback: 'pending'),
      );
}
