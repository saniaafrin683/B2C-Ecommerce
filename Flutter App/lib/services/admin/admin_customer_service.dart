import '../../core/api_client.dart';

class AdminCustomerService {
  AdminCustomerService({required this.apiClient});

  final ApiClient apiClient;

  Future<List<AdminCustomer>> getCustomers(String token) async {
    final response = await apiClient.getJson(
      '/customers/list',
      headers: _headers(token),
    );
    if (response is! List) {
      throw const FormatException('Unexpected customers response.');
    }
    final customers = response
        .whereType<Map<String, dynamic>>()
        .map(AdminCustomer.fromJson)
        .toList(growable: false);
    customers.sort((a, b) {
      final date = (b.registeredAt ?? DateTime(1970)).compareTo(
        a.registeredAt ?? DateTime(1970),
      );
      return date != 0 ? date : (b.id ?? 0).compareTo(a.id ?? 0);
    });
    return customers;
  }

  Future<List<AdminCustomer>> getDeletedCustomers(String token) async {
    final response = await apiClient.getJson(
      '/customers/deleted',
      headers: _headers(token),
    );
    if (response is! List) {
      throw const FormatException('Unexpected deleted customers response.');
    }
    return response
        .whereType<Map<String, dynamic>>()
        .map(AdminCustomer.fromJson)
        .toList(growable: false);
  }

  Future<AdminCustomer> getCustomer(String token, int id) async {
    final response = await apiClient.getJson(
      '/customers/$id',
      headers: _headers(token),
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Unexpected customer details response.');
    }
    return AdminCustomer.fromJson(response);
  }

  Future<void> deleteCustomer(String token, int id) async {
    await apiClient.delete('/customers/delete/$id', headers: _headers(token));
  }

  Future<void> restoreCustomer(String token, int id) async {
    await apiClient.putJson(
      '/customers/restore/$id',
      headers: _headers(token),
      body: const <String, dynamic>{},
    );
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
  };
}

class AdminCustomer {
  const AdminCustomer({
    this.id,
    this.customerCode,
    this.fullName,
    this.email,
    this.phone,
    this.gender,
    this.dateOfBirth,
    this.address,
    this.city,
    this.country,
    this.totalOrders,
    this.totalSpend,
    this.status,
    this.registeredAt,
    this.notes,
  });

  final int? id;
  final String? customerCode;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? address;
  final String? city;
  final String? country;
  final int? totalOrders;
  final double? totalSpend;
  final String? status;
  final DateTime? registeredAt;
  final String? notes;

  bool get isDeleted => status?.toLowerCase() == 'deleted';

  factory AdminCustomer.fromJson(Map<String, dynamic> json) {
    return AdminCustomer(
      id: _asInt(json['id']),
      customerCode: _asString(json['customerCode']),
      fullName: _asString(json['fullName']),
      email: _asString(json['email']),
      phone: _asString(json['phone']),
      gender: _asString(json['gender']),
      dateOfBirth: _asDate(json['dateOfBirth']),
      address: _asString(json['address']),
      city: _asString(json['city']),
      country: _asString(json['country']),
      totalOrders: _asInt(json['totalOrders']),
      totalSpend: _asDouble(json['totalSpend']),
      status: _asString(json['status']),
      registeredAt: _asDate(json['registeredAt']),
      notes: _asString(json['notes']),
    );
  }

  String get displayName => fullName ?? 'Unnamed customer';

  String get location {
    final parts = <String?>[city, country].whereType<String>().toList();
    return parts.isEmpty ? '—' : parts.join(', ');
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static String? _asString(dynamic value) {
    final text = value?.toString();
    return text == null || text.trim().isEmpty ? null : text.trim();
  }

  static DateTime? _asDate(dynamic value) {
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) return null;
    return DateTime.tryParse(text.trim());
  }
}
