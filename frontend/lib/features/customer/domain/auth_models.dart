import 'package:flutter/foundation.dart';

import '../../../core/json_helpers.dart';

@immutable
class CustomerUser {
  const CustomerUser({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.avatarUrl,
    this.address,
    this.isFirstLogin = false,
  });

  final String id;
  final String fullName;
  final String phoneNumber;
  final String? avatarUrl;
  final String? address;
  final bool isFirstLogin;

  factory CustomerUser.fromJson(Map<String, dynamic> json) => CustomerUser(
        id: readString(json, 'id'),
        fullName: readString(json, 'full_name', 'fullName'),
        phoneNumber: readString(json, 'phone_number', 'phoneNumber'),
        avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
        address: json['address'] as String?,
        isFirstLogin: json['is_first_login'] as bool? ?? json['isFirstLogin'] as bool? ?? false,
      );

  CustomerUser copyWith({String? fullName, String? address, String? avatarUrl, bool? isFirstLogin}) => CustomerUser(
        id: id,
        fullName: fullName ?? this.fullName,
        phoneNumber: phoneNumber,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        address: address ?? this.address,
        isFirstLogin: isFirstLogin ?? this.isFirstLogin,
      );
}

class LoginResult {
  const LoginResult({required this.accessToken, required this.refreshToken, required this.user, required this.isFirstLogin});
  final String accessToken;
  final String refreshToken;
  final CustomerUser user;
  final bool isFirstLogin;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final user = rawUser is Map<String, dynamic> ? CustomerUser.fromJson(rawUser) : CustomerUser.fromJson(json);
    final firstLogin = json['is_first_login'] as bool? ?? json['isFirstLogin'] as bool? ?? user.isFirstLogin;
    return LoginResult(
      accessToken: readString(json, 'access_token', 'accessToken'),
      refreshToken: readString(json, 'refresh_token', 'refreshToken'),
      user: user.copyWith(isFirstLogin: firstLogin),
      isFirstLogin: firstLogin,
    );
  }
}
