import '../../../core/json_helpers.dart';

class Sparepart {
  const Sparepart({
    required this.id,
    required this.brand,
    required this.deviceModel,
    required this.partType,
    required this.partName,
    required this.price,
    required this.qty,
    required this.qtyReserved,
    required this.status,
  });

  final String id;
  final String brand;
  final String deviceModel;
  final String partType;
  final String partName;
  final num price;
  final int qty;
  final int qtyReserved;
  final String status;

  int get availableStock => qty - qtyReserved;
  bool get isLowStock => availableStock <= 2;

  factory Sparepart.fromJson(Map<String, dynamic> json) => Sparepart(
        id: jsonString(json['id']),
        brand: jsonString(json['brand'], fallback: ''),
        deviceModel: jsonString(json['deviceModel'] ?? json['device_model'], fallback: ''),
        partType: jsonString(json['partType'] ?? json['part_type'], fallback: ''),
        partName: jsonString(json['partName'] ?? json['part_name'], fallback: 'Sparepart'),
        price: jsonNum(json['price']),
        qty: jsonInt(json['qty']),
        qtyReserved: jsonInt(json['qtyReserved'] ?? json['qty_reserved']),
        status: jsonString(json['status'], fallback: 'available'),
      );

  static const partTypeLabels = {
    'screen_replacement': 'Layar',
    'battery_replacement': 'Baterai',
    'charging_port': 'Charging Port',
    'camera': 'Kamera',
    'other': 'Lainnya',
  };

  String get partTypeLabel => partTypeLabels[partType] ?? partType;
}

class InventoryQuery {
  const InventoryQuery({this.search, this.brand, this.deviceModel, this.partType, this.page = 1});
  final String? search;
  final String? brand;
  final String? deviceModel;
  final String? partType;
  final int page;

  InventoryQuery copyWith({String? search, String? brand, String? deviceModel, String? partType, int? page}) =>
      InventoryQuery(
        search: search ?? this.search,
        brand: brand ?? this.brand,
        deviceModel: deviceModel ?? this.deviceModel,
        partType: partType ?? this.partType,
        page: page ?? this.page,
      );
}
