import '../../core/api_client.dart';

class AdminCouponService {
  AdminCouponService({required this.apiClient});

  final ApiClient apiClient;

  Future<List<AdminCoupon>> getCoupons(String token) async {
    final response = await apiClient.getJson(
      '/coupons/list',
      headers: _headers(token),
    );
    if (response is! List) {
      throw const FormatException('Unexpected coupons response.');
    }
    final coupons = response
        .whereType<Map<String, dynamic>>()
        .map(AdminCoupon.fromJson)
        .toList(growable: false);
    coupons.sort(AdminCoupon.newestFirst);
    return coupons;
  }

  Future<AdminCoupon> getCoupon(String token, int id) async {
    final response = await apiClient.getJson(
      '/coupons/$id',
      headers: _headers(token),
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Unexpected coupon response.');
    }
    return AdminCoupon.fromJson(response);
  }

  Future<AdminCoupon> createCoupon(String token, AdminCouponInput input) async {
    final response = await apiClient.postJson(
      '/coupons/create',
      headers: _headers(token),
      body: input.toJson(),
    );
    return AdminCoupon.fromJson(response);
  }

  Future<AdminCoupon> updateCoupon(
    String token,
    int id,
    AdminCouponInput input,
  ) async {
    final response = await apiClient.putJson(
      '/coupons/update/$id',
      headers: _headers(token),
      body: input.toJson(),
    );
    return AdminCoupon.fromJson(response);
  }

  Future<void> deleteCoupon(String token, int id) async {
    await apiClient.delete('/coupons/delete/$id', headers: _headers(token));
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
  };
}

class AdminCoupon {
  const AdminCoupon({
    this.id,
    this.code,
    this.discountType,
    this.discountValue = 0,
    this.minimumOrderAmount = 0,
    this.usageLimit = 0,
    this.usedCount = 0,
    this.startDate,
    this.endDate,
    this.status,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String? code;
  final String? discountType;
  final double discountValue;
  final double minimumOrderAmount;
  final int usageLimit;
  final int usedCount;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? status;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayCode =>
      code?.trim().isNotEmpty == true ? code!.trim() : '—';
  bool get isPercentage =>
      discountType?.toLowerCase().contains('percent') == true;
  String get displayDiscountType => isPercentage ? 'Percentage' : 'Flat';
  String get displayDiscount => isPercentage
      ? '${_compact(discountValue)}%'
      : '৳${discountValue.toStringAsFixed(2)}';
  bool get usageLimited => usageLimit > 0;
  bool get usageExhausted => usageLimited && usedCount >= usageLimit;
  double get usageProgress =>
      !usageLimited ? 0 : (usedCount / usageLimit).clamp(0, 1).toDouble();

  String get effectiveStatus {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalized = status?.trim().toLowerCase() ?? '';
    if (normalized == 'expired' ||
        (endDate != null && endDate!.isBefore(normalizedToday))) {
      return 'Expired';
    }
    if (normalized != 'active' ||
        usageExhausted ||
        (startDate != null && startDate!.isAfter(normalizedToday))) {
      return 'Inactive';
    }
    return 'Active';
  }

  factory AdminCoupon.fromJson(Map<String, dynamic> json) => AdminCoupon(
    id: _asInt(json['id']),
    code: _asString(json['couponCode']),
    discountType: _asString(json['discountType']),
    discountValue: _asDouble(json['discountValue']),
    minimumOrderAmount: _asDouble(json['minimumOrderAmount']),
    usageLimit: _asInt(json['usageLimit']) ?? 0,
    usedCount: _asInt(json['usedCount']) ?? 0,
    startDate: _asDate(json['startDate']),
    endDate: _asDate(json['endDate'] ?? json['expiryDate']),
    status: _asString(json['status']),
    description: _asString(json['description']),
    createdAt: _asDate(json['createdAt']),
    updatedAt: _asDate(json['updatedAt']),
  );

  static int newestFirst(AdminCoupon a, AdminCoupon b) {
    final date = (b.createdAt ?? b.startDate ?? DateTime(1970)).compareTo(
      a.createdAt ?? a.startDate ?? DateTime(1970),
    );
    return date != 0 ? date : (b.id ?? 0).compareTo(a.id ?? 0);
  }
}

class AdminCouponInput {
  const AdminCouponInput({
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minimumOrderAmount,
    required this.startDate,
    required this.endDate,
    required this.usageLimit,
    required this.usedCount,
    required this.status,
    required this.description,
  });

  final String code;
  final String discountType;
  final double discountValue;
  final double minimumOrderAmount;
  final DateTime startDate;
  final DateTime endDate;
  final int usageLimit;
  final int usedCount;
  final String status;
  final String description;

  Map<String, dynamic> toJson() => {
    'couponCode': code.trim().toUpperCase(),
    'discountType': discountType,
    'discountValue': discountValue,
    'minimumOrderAmount': minimumOrderAmount,
    'startDate': _datePayload(startDate),
    'endDate': _datePayload(endDate),
    'usageLimit': usageLimit,
    'usedCount': usedCount,
    'status': status,
    'description': description.trim(),
  };
}

int? _asInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

double _asDouble(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

String? _asString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

DateTime? _asDate(dynamic value) {
  final text = _asString(value);
  return text == null ? null : DateTime.tryParse(text);
}

String _datePayload(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

String _compact(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);
