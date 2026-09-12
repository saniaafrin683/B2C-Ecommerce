import '../core/app_constants.dart';

class Product {
  final int? id;
  final String? name;
  final String? category;
  final int? subCategoryId;
  final String? subCategory;
  final String? brand;
  final String? weight;
  final String? gender;
  final String? description;
  final String? tagNumber;
  final int? stock;
  final String? tag;
  final double? price;
  final double? discount;
  final double? tax;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    this.id,
    this.name,
    this.category,
    this.subCategoryId,
    this.subCategory,
    this.brand,
    this.weight,
    this.gender,
    this.description,
    this.tagNumber,
    this.stock,
    this.tag,
    this.price,
    this.discount,
    this.tax,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      category: _asString(json['category']),
      subCategoryId: _asInt(json['subCategoryId']),
      subCategory: _asString(json['subCategory']),
      brand: _asString(json['brand']),
      weight: _asString(json['weight']),
      gender: _asString(json['gender']),
      description: _asString(json['description']),
      tagNumber: _asString(json['tagNumber']),
      stock: _asInt(json['stock']),
      tag: _asString(json['tag']),
      price: _asDouble(json['price']),
      discount: _asDouble(json['discount']),
      tax: _asDouble(json['tax']),
      imageUrl: _asString(json['imageUrl']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  String get resolvedImageUrl {
    final value = imageUrl?.trim();
    if (value == null || value.isEmpty) {
      return '';
    }
    return _normalizeImageUrl(value);
  }

  double get effectivePrice {
    final basePrice = price ?? 0;
    final discountValue = discount ?? 0;
    if (discountValue <= 0) {
      return basePrice;
    }
    if (discountValue >= 100) {
      return 0;
    }
    return double.parse(
      (basePrice * (1 - discountValue / 100)).toStringAsFixed(2),
    );
  }

  double? get discountAmount {
    if (price == null || discount == null || discount! <= 0) {
      return null;
    }
    return double.parse((price! - effectivePrice).toStringAsFixed(2));
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

  static double? _asDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
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

  static String _normalizeImageUrl(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    final normalized = value.replaceAll('\\', '/');
    if (normalized.startsWith('/uploads') ||
        normalized.startsWith('uploads/')) {
      final path = normalized.startsWith('/') ? normalized : '/$normalized';
      return '${AppConstants.baseUrl}$path';
    }

    if (normalized.startsWith('/')) {
      return '${AppConstants.baseUrl}$normalized';
    }

    return normalized;
  }
}
