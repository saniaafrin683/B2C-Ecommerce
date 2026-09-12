class CustomerProfile {
  final int? id;
  final String? customerCode;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? country;
  final String? status;
  final DateTime? registeredAt;

  const CustomerProfile({
    this.id,
    this.customerCode,
    this.fullName,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.country,
    this.status,
    this.registeredAt,
  });

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      id: _asInt(json['id']),
      customerCode: _asString(json['customerCode']),
      fullName: _asString(json['fullName']),
      email: _asString(json['email']),
      phone: _asString(json['phone']),
      address: _asString(json['address']),
      city: _asString(json['city']),
      country: _asString(json['country']),
      status: _asString(json['status']),
      registeredAt: _parseDate(json['registeredAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'customerCode': customerCode,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'country': country,
      'status': status,
      'registeredAt': registeredAt?.toIso8601String(),
    };
  }

  CustomerProfile copyWith({
    int? id,
    String? customerCode,
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? country,
    String? status,
    DateTime? registeredAt,
  }) {
    return CustomerProfile(
      id: id ?? this.id,
      customerCode: customerCode ?? this.customerCode,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      status: status ?? this.status,
      registeredAt: registeredAt ?? this.registeredAt,
    );
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

  static String? _asString(dynamic value) {
    final text = value?.toString();
    return text == null || text.trim().isEmpty ? null : text.trim();
  }

  static DateTime? _parseDate(dynamic value) {
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(text.trim());
  }
}
