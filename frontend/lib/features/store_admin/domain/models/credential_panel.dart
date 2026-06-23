import '../../../../core/json_helpers.dart';

class CredentialPanel {
  const CredentialPanel(
      {required this.isNewCustomer,
      required this.phoneNumber,
      required this.password,
      this.expiresAt,
      this.sentAt});
  final bool isNewCustomer;
  final String phoneNumber;
  final String? password;
  final DateTime? expiresAt;
  final DateTime? sentAt;
  bool get hasCredential => password != null && password!.isNotEmpty;

  factory CredentialPanel.fromJson(Map<String, dynamic> json) =>
      CredentialPanel(
        isNewCustomer:
            jsonBool(json['isNewCustomer'] ?? json['is_new_customer']),
        phoneNumber: jsonString(json['phoneNumber'] ?? json['phone_number']),
        password: json['password'] as String? ?? json['credential'] as String?,
        expiresAt: jsonDateOrNull(json['expiresAt'] ?? json['expires_at']),
        sentAt: jsonDateOrNull(json['sentAt'] ?? json['sent_at']),
      );
}
