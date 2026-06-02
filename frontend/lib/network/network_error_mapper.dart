import 'package:dio/dio.dart';

import '../core/api_exception.dart';

DioException mapNetworkError(DioException error) {
  final statusCode = error.response?.statusCode;
  final data = error.response?.data;
  final message = data is Map<String, dynamic> && data['message'] is String ? data['message'] as String : error.message ?? 'Network error';
  return error.copyWith(error: ApiException(message, statusCode: statusCode));
}
