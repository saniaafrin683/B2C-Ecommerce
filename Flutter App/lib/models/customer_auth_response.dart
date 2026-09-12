import 'customer_profile.dart';

class CustomerAuthResponse {
  final bool success;
  final String? message;
  final String? token;
  final String? role;
  final CustomerProfile? customer;

  const CustomerAuthResponse({
    required this.success,
    this.message,
    this.token,
    this.role,
    this.customer,
  });

  factory CustomerAuthResponse.fromJson(Map<String, dynamic> json) {
    final customerJson = json['customer'];
    return CustomerAuthResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      token: json['token']?.toString(),
      role: json['role']?.toString(),
      customer: customerJson is Map<String, dynamic>
          ? CustomerProfile.fromJson(customerJson)
          : null,
    );
  }
}
