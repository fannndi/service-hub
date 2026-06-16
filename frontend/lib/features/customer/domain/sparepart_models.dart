import '../../../core/json_helpers.dart';

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
