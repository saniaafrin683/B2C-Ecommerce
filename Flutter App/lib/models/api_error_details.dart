class ApiErrorDetails {
  final int? status;
  final String? error;
  final String message;
  final Map<String, String> validationErrors;

  const ApiErrorDetails({
    this.status,
    this.error,
    required this.message,
    this.validationErrors = const <String, String>{},
  });
}
