import 'product.dart';

class ProductPageResponse {
  final List<Product> content;
  final int totalElements;
  final int totalPages;
  final int page;
  final int size;
  final String? sortBy;
  final String? sortDir;

  const ProductPageResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.page,
    required this.size,
    this.sortBy,
    this.sortDir,
  });

  factory ProductPageResponse.fromJson(Map<String, dynamic> json) {
    final items = json['content'];
    return ProductPageResponse(
      content: items is List
          ? items
                .whereType<Map<String, dynamic>>()
                .map(Product.fromJson)
                .toList(growable: false)
          : const <Product>[],
      totalElements: _asInt(json['totalElements']),
      totalPages: _asInt(json['totalPages']),
      page: _asInt(json['page']),
      size: _asInt(json['size']),
      sortBy: json['sortBy']?.toString(),
      sortDir: json['sortDir']?.toString(),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
