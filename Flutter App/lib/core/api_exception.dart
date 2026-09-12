import '../models/api_error_details.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Map<String, String> validationErrors;

  const ApiException({
    this.statusCode,
    required this.message,
    this.validationErrors = const <String, String>{},
  });

  factory ApiException.fromDetails(ApiErrorDetails details) {
    return ApiException(
      statusCode: details.status,
      message: details.message,
      validationErrors: details.validationErrors,
    );
  }

  @override
  String toString() => message;
}
