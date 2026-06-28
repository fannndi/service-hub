import '../../../../core/json_helpers.dart';

class UserListItem {
  const UserListItem({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    required this.accountStatus,
    required this.isFirstLogin,
    required this.isCredentialSent,
    required this.createdAt,
  });
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? address;
  final String accountStatus;
  final bool isFirstLogin;
  final bool isCredentialSent;
  final String createdAt;

  factory UserListItem.fromJson(Map<String, dynamic> json) => UserListItem(
        id: readString(json, 'id'),
        fullName: readString(json, 'full_name', 'fullName'),
        phoneNumber: readString(json, 'phone_number', 'phoneNumber'),
        address: json['address'] as String?,
        accountStatus: readString(json, 'account_status', 'accountStatus'),
        isFirstLogin: (json['isFirstLogin'] ?? json['is_first_login'] ?? false) as bool,
        isCredentialSent: (json['isCredentialSent'] ?? json['is_credential_sent'] ?? false) as bool,
        createdAt: readString(json, 'created_at', 'createdAt'),
      );
}
