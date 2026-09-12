import '../core/api_client.dart';
import '../models/customer_auth_response.dart';
import '../models/customer_profile.dart';
import '../models/session_data.dart';

class AuthService {
  AuthService({required this.apiClient});

  final ApiClient apiClient;

  Future<SessionData> login({
    required String email,
    required String password,
  }) async {
    final body = <String, dynamic>{'email': email.trim(), 'password': password};

    try {
      return await _submitAuth(path: '/customers/login', body: body);
    } catch (_) {
      // Admin accounts are authenticated by the backend's separate admin
      // endpoint. Keeping this fallback here preserves the customer contract.
      return _submitAdminAuth(body);
    }
  }

  Future<SessionData> _submitAdminAuth(Map<String, dynamic> body) async {
    final response = await apiClient.postJson('/auth/login', body: body);
    final success = response['success'] == true;
    final token = response['token']?.toString();
    final role = response['role']?.toString();
    final email = (response['adminEmail'] ?? response['email'])?.toString();

    if (!success || token == null || token.isEmpty || role == null) {
      throw const FormatException(
        'Admin authentication response was incomplete.',
      );
    }

    return SessionData(
      token: token,
      role: role,
      customer: CustomerProfile(fullName: 'Administrator', email: email),
    );
  }

  Future<SessionData> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    String? address,
    String? city,
    String? country,
  }) async {
    return _submitAuth(
      path: '/customers/register',
      body: <String, dynamic>{
        'fullName': fullName.trim(),
        'email': email.trim(),
        'password': password,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (address != null && address.trim().isNotEmpty)
          'address': address.trim(),
        if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
        if (country != null && country.trim().isNotEmpty)
          'country': country.trim(),
      },
    );
  }

  Future<SessionData> _submitAuth({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    final responseJson = await apiClient.postJson(path, body: body);
    final authResponse = CustomerAuthResponse.fromJson(responseJson);

    if (!authResponse.success ||
        authResponse.token == null ||
        authResponse.role == null ||
        authResponse.customer == null) {
      throw const FormatException('Authentication response was incomplete.');
    }

    return SessionData(
      token: authResponse.token!,
      role: authResponse.role!,
      customer: authResponse.customer ?? const CustomerProfile(),
    );
  }
}
