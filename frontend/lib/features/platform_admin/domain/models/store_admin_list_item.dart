import '../../../../core/json_helpers.dart';

class StoreAdminListItem {
  const StoreAdminListItem({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.isActive,
    required this.isFirstLogin,
    required this.storeName,
    required this.storeId,
  });
  final String id;
  final String fullName;
  final String phoneNumber;
  final bool isActive;
  final bool isFirstLogin;
  final String storeName;
  final String storeId;

  factory StoreAdminListItem.fromJson(Map<String, dynamic> json) {
    final store = json['store'] as Map<String, dynamic>? ?? {};
    return StoreAdminListItem(
      id: readString(json, 'id'),
      fullName: readString(json, 'full_name', 'fullName'),
      phoneNumber: readString(json, 'phone_number', 'phoneNumber'),
      isActive: (json['is_active'] ?? json['isActive']) as bool? ?? true,
      isFirstLogin: (json['is_first_login'] ?? json['isFirstLogin']) as bool? ?? false,
      storeName: readString(store, 'store_name', 'storeName'),
      storeId: readString(store, 'id'),
    );
  }
}
