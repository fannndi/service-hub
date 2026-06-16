import '../../../core/json_helpers.dart';

class Sparepart {
  const Sparepart({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.qty,
    required this.qtyReserved,
    required this.status,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String description;
  final num price;
  final int qty;
  final int qtyReserved;
  final String status;
  final String? imageUrl;
  int get availableStock => qty - qtyReserved;
  bool get isLowStock => availableStock <= 2;

  factory Sparepart.fromJson(Map<String, dynamic> json) => Sparepart(
        id: jsonString(json['id']),
        name: jsonString(json['name'], fallback: 'Sparepart'),
        description: jsonString(json['description']),
        price: jsonNum(json['price']),
        qty: jsonInt(json['qty']),
        qtyReserved: jsonInt(json['qtyReserved'] ?? json['qty_reserved']),
        status: jsonString(json['status'], fallback: 'available'),
        imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
      );
}
