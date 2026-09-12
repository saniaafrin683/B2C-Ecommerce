import 'customer_profile.dart';

class SessionData {
  final String token;
  final String role;
  final CustomerProfile customer;

  const SessionData({
    required this.token,
    required this.role,
    required this.customer,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'token': token,
      'role': role,
      'customer': customer.toJson(),
    };
  }

  factory SessionData.fromJson(Map<String, dynamic> json) {
    final customerJson = json['customer'];
    return SessionData(
      token: json['token'].toString(),
      role: json['role'].toString(),
      customer: customerJson is Map<String, dynamic>
          ? CustomerProfile.fromJson(customerJson)
          : const CustomerProfile(),
    );
  }
}
