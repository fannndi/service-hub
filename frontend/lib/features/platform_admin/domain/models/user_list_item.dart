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
