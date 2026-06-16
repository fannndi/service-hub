import '../../../core/json_helpers.dart';

class StoreAdminSession {
  const StoreAdminSession({
    required this.adminId,
    required this.adminName,
    required this.phoneNumber,
    required this.storeId,
    required this.storeName,
    required this.isFirstLogin,
  });

  final String adminId;
  final String adminName;
  final String phoneNumber;
  final String storeId;
  final String storeName;
  final bool isFirstLogin;

  factory StoreAdminSession.fromJson(Map<String, dynamic> json) {
    final admin = jsonMap(json['store_admin']) ?? json;
    return StoreAdminSession(
      adminId: jsonString(admin['id']),
      adminName: jsonString(admin['full_name'] ?? admin['fullName'] ?? admin['name'], fallback: 'Admin Toko'),
      phoneNumber: jsonString(admin['phone_number'] ?? admin['phoneNumber']),
      storeId: jsonString(admin['store_id'] ?? admin['storeId'] ?? json['storeId']),
      storeName: jsonString(admin['store_name'] ?? admin['storeName'] ?? json['storeName'], fallback: 'Toko Servis'),
      isFirstLogin: jsonBool(admin['is_first_login'] ?? admin['isFirstLogin']),
    );
  }

  Map<String, String> toStorage() => {
        'adminId': adminId,
        'adminName': adminName,
        'phoneNumber': phoneNumber,
        'storeId': storeId,
        'storeName': storeName,
        'isFirstLogin': isFirstLogin.toString(),
      };

  factory StoreAdminSession.fromStorage(Map<String, String?> values) => StoreAdminSession(
        adminId: values['adminId'] ?? '',
        adminName: values['adminName'] ?? 'Admin Toko',
        phoneNumber: values['phoneNumber'] ?? '',
        storeId: values['storeId'] ?? '',
        storeName: values['storeName'] ?? 'Toko Servis',
        isFirstLogin: values['isFirstLogin'] == 'true',
      );

  StoreAdminSession copyWith({bool? isFirstLogin}) => StoreAdminSession(
        adminId: adminId,
        adminName: adminName,
        phoneNumber: phoneNumber,
        storeId: storeId,
        storeName: storeName,
        isFirstLogin: isFirstLogin ?? this.isFirstLogin,
      );
}
