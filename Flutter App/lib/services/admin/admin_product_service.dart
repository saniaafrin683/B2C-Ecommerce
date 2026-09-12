import 'dart:typed_data';

import '../../core/api_client.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../models/product_page_response.dart';

class AdminProductService {
  AdminProductService({required this.apiClient});

  final ApiClient apiClient;

  Future<List<Product>> getProducts(String token) async {
    final headers = _headers(token);
    final firstJson = await apiClient.getJson(
      '/products/page',
      queryParameters: const {
        'page': 0,
        'size': 100,
        'sortBy': 'id',
        'sortDir': 'desc',
      },
      headers: headers,
    );
    final first = ProductPageResponse.fromJson(_asMap(firstJson));
    if (first.totalPages <= 1) {
      return first.content;
    }

    final remaining = await Future.wait(
      List.generate(first.totalPages - 1, (index) async {
        final json = await apiClient.getJson(
          '/products/page',
          queryParameters: {
            'page': index + 1,
            'size': 100,
            'sortBy': 'id',
            'sortDir': 'desc',
          },
          headers: headers,
        );
        return ProductPageResponse.fromJson(_asMap(json)).content;
      }),
    );

    return <List<Product>>[
      first.content,
      ...remaining,
    ].expand((page) => page).toList();
  }

  Future<List<String>> getCategories(String token) async {
    final response = await apiClient.getJson(
      '/categories/list',
      headers: _headers(token),
    );
    if (response is! List) return const [];
    final names =
        response
            .whereType<Map<String, dynamic>>()
            .map(Category.fromJson)
            .map((category) => category.categoryTitle?.trim())
            .whereType<String>()
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names;
  }

  Future<Product> createProduct(String token, AdminProductInput input) async {
    final response = await apiClient.sendMultipart(
      '/products/create-upload',
      method: 'POST',
      fields: input.toFields(),
      headers: _headers(token),
      fileBytes: input.imageBytes,
      fileName: input.imageName,
      contentType: _imageContentType(input.imageName),
    );
    return Product.fromJson(response);
  }

  Future<Product> updateProduct(
    String token,
    int id,
    AdminProductInput input,
  ) async {
    final response = await apiClient.sendMultipart(
      '/products/update-upload/$id',
      method: 'PUT',
      fields: input.toFields(),
      headers: _headers(token),
      fileBytes: input.imageBytes,
      fileName: input.imageName,
      contentType: _imageContentType(input.imageName),
    );
    return Product.fromJson(response);
  }

  Future<void> deleteProduct(String token, int id) async {
    await apiClient.delete('/products/delete/$id', headers: _headers(token));
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
  };

  static Map<String, dynamic> _asMap(dynamic value) =>
      value is Map<String, dynamic> ? value : <String, dynamic>{};

  static String? _imageContentType(String? fileName) {
    final extension = fileName?.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => null,
    };
  }
}

class AdminProductInput {
  const AdminProductInput({
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.discount,
    this.brand,
    this.description,
    this.imageUrl,
    this.imageBytes,
    this.imageName,
    this.subCategoryId,
    this.subCategory,
    this.weight,
    this.gender,
    this.tagNumber,
    this.tag,
    this.tax,
  });

  final String name;
  final String category;
  final double price;
  final int stock;
  final double discount;
  final String? brand;
  final String? description;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final String? imageName;
  final int? subCategoryId;
  final String? subCategory;
  final String? weight;
  final String? gender;
  final String? tagNumber;
  final String? tag;
  final double? tax;

  Map<String, String> toFields() => {
    'name': name,
    'category': category,
    'price': price.toString(),
    'stock': stock.toString(),
    'discount': discount.toString(),
    if (_hasText(brand)) 'brand': brand!.trim(),
    if (_hasText(description)) 'description': description!.trim(),
    if (_hasText(imageUrl)) 'imageUrl': imageUrl!.trim(),
    if (subCategoryId != null) 'subCategoryId': '$subCategoryId',
    if (_hasText(subCategory)) 'subCategory': subCategory!.trim(),
    if (_hasText(weight)) 'weight': weight!.trim(),
    if (_hasText(gender)) 'gender': gender!.trim(),
    if (_hasText(tagNumber)) 'tagNumber': tagNumber!.trim(),
    if (_hasText(tag)) 'tag': tag!.trim(),
    if (tax != null) 'tax': '$tax',
  };

  static bool _hasText(String? value) => value?.trim().isNotEmpty == true;
}
