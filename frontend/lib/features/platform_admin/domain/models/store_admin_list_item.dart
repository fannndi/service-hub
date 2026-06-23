import '../../../../core/json_helpers.dart';

class StoreAdminListItem {
  const StoreAdminListItem({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.isActive,
    required this.isFirstLogin,
    required this.plainPassword,
    required this.storeName,
    required this.storeId,
  });
  final String id;
  final String fullName;
  final String phoneNumber;
  final bool isActive;
  final bool isFirstLogin;
  final String? plainPassword;
  final String storeName;
  final String storeId;

  factory StoreAdminListItem.fromJson(Map<String, dynamic> json) {
    final store = json['store'] as Map<String, dynamic>? ?? {};
    return StoreAdminListItem(
      id: readString(json, 'id'),
      fullName: readString(json, 'fullName'),
      phoneNumber: readString(json, 'phoneNumber'),
      isActive: json['isActive'] as bool? ?? true,
      isFirstLogin: json['isFirstLogin'] as bool? ?? false,
      plainPassword: json['plainPassword'] as String?,
      storeName: readString(store, 'storeName'),
      storeId: readString(store, 'id'),
    );
  }
}
