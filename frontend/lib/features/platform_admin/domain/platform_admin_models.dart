import '../../../core/json_helpers.dart';

class AdminSession {
  const AdminSession(
      {required this.id, required this.username, required this.fullName});
  final String id;
  final String username;
  final String fullName;

  factory AdminSession.fromJson(Map<String, dynamic> json) => AdminSession(
        id: readString(json, 'id'),
        username: readString(json, 'username'),
        fullName: readString(json, 'fullName'),
      );
}

class AdminLoginResult {
  const AdminLoginResult(
      {required this.accessToken, this.refreshToken, required this.admin});
  final String accessToken;
  final String? refreshToken;
  final AdminSession admin;

  factory AdminLoginResult.fromJson(Map<String, dynamic> json) =>
      AdminLoginResult(
        accessToken: readString(json, 'accessToken'),
        refreshToken: json['refreshToken'] as String?,
        admin: AdminSession.fromJson(
            (json['admin'] as Map<String, dynamic>?) ?? {}),
      );
}

class StoreListItem {
  const StoreListItem({
    required this.id,
    required this.storeName,
    required this.address,
    required this.phoneNumber,
    this.deviceTypes,
    required this.ratingAvg,
    required this.totalCompleted,
    required this.createdAt,
    required this.admins,
  });
  final String id;
  final String storeName;
  final String address;
  final String phoneNumber;
  final Map<String, dynamic>? deviceTypes;
  final double ratingAvg;
  final int totalCompleted;
  final String createdAt;
  final List<Map<String, dynamic>> admins;

  factory StoreListItem.fromJson(Map<String, dynamic> json) {
    final config = json['config'] as Map<String, dynamic>?;
    return StoreListItem(
      id: readString(json, 'id'),
      storeName: readString(json, 'storeName'),
      address: readString(json, 'address'),
      phoneNumber: readString(json, 'phoneNumber'),
      deviceTypes: config?['device_types'] as Map<String, dynamic>?,
      ratingAvg: moneyFromJson(json['ratingAvg']),
      totalCompleted: json['totalCompleted'] as int? ?? 0,
      createdAt: readString(json, 'createdAt'),
      admins: (json['admins'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList(),
    );
  }
}

class UserListItem {
  const UserListItem({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    required this.accountStatus,
    required this.isFirstLogin,
    required this.isCredentialSent,
    required this.plainPassword,
    required this.createdAt,
  });
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? address;
  final String accountStatus;
  final bool isFirstLogin;
  final bool isCredentialSent;
  final String? plainPassword;
  final String createdAt;

  factory UserListItem.fromJson(Map<String, dynamic> json) => UserListItem(
        id: readString(json, 'id'),
        fullName: readString(json, 'fullName'),
        phoneNumber: readString(json, 'phoneNumber'),
        address: json['address'] as String?,
        accountStatus: readString(json, 'accountStatus'),
        isFirstLogin: json['isFirstLogin'] as bool? ?? false,
        isCredentialSent: json['isCredentialSent'] as bool? ?? false,
        plainPassword: json['plainPassword'] as String?,
        createdAt: readString(json, 'createdAt'),
      );
}

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
