import 'package:dio/dio.dart';

import '../core/api_exception.dart';

DioException mapNetworkError(DioException error) {
  final statusCode = error.response?.statusCode;
  final data = error.response?.data;
  String message;
  if (data is Map<String, dynamic>) {
    final errorBody = data['error'];
    if (errorBody is Map<String, dynamic>) {
      final userMessage = errorBody['user_message'];
      if (userMessage is String && userMessage.isNotEmpty) {
        message = userMessage;
      } else {
        message = data['message']?.toString() ?? error.message ?? 'Network error';
      }
    } else {
      message = data['message']?.toString() ?? error.message ?? 'Network error';
    }
  } else {
    message = error.message ?? 'Network error';
  }
  return error.copyWith(error: ApiException(message, statusCode: statusCode));
}
