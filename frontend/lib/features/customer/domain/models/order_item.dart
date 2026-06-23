import '../../../../core/json_helpers.dart';

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
