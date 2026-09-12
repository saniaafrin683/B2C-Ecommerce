import 'dart:convert';

import '../models/api_error_details.dart';

class ApiErrorParser {
  const ApiErrorParser._();

  static ApiErrorDetails parse({required String body, int? statusCode}) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return ApiErrorDetails(
        status: statusCode,
        message: _defaultMessage(statusCode),
      );
    }

    try {
      final dynamic decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final validationErrors = _extractValidationErrors(
          decoded['validationErrors'],
        );
        final message = _extractMessage(decoded, validationErrors);
        return ApiErrorDetails(
          status: _asInt(decoded['status']) ?? statusCode,
          error: decoded['error']?.toString(),
          message: message,
          validationErrors: validationErrors,
        );
      }
    } catch (_) {
      // Fall through to plain text handling.
    }

    return ApiErrorDetails(status: statusCode, message: trimmed);
  }

  static Map<String, String> _extractValidationErrors(dynamic value) {
    if (value is Map) {
      return value.map<String, String>((dynamic key, dynamic val) {
        return MapEntry(key.toString(), val?.toString() ?? '');
      });
    }
    return <String, String>{};
  }

  static String _extractMessage(
    Map<String, dynamic> json,
    Map<String, String> validationErrors,
  ) {
    final message = json['message']?.toString().trim();
    if (message != null && message.isNotEmpty) {
      return validationErrors.isEmpty
          ? message
          : '$message ${validationErrors.entries.map((e) => '${e.key}: ${e.value}').join(', ')}';
    }

    final error = json['error']?.toString().trim();
    if (error != null && error.isNotEmpty) {
      return error;
    }

    if (validationErrors.isNotEmpty) {
      return validationErrors.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
    }

    return _defaultMessage(_asInt(json['status']));
  }

  static int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  static String _defaultMessage(int? statusCode) {
    if (statusCode == 401) {
      return 'Authentication required.';
    }
    if (statusCode == 403) {
      return 'You do not have permission to access this resource.';
    }
    if (statusCode == 404) {
      return 'Requested resource was not found.';
    }
    return 'Request failed.';
  }
}
