import 'dart:typed_data';

import '../../core/api_client.dart';
import '../../models/category.dart';

class AdminCategoryService {
  AdminCategoryService({required this.apiClient});

  final ApiClient apiClient;

  Future<List<Category>> getCategories(String token) async {
    final response = await apiClient.getJson(
      '/categories/list',
      headers: _headers(token),
    );
    if (response is! List) {
      throw const FormatException('Unexpected categories response.');
    }
    return response
        .whereType<Map<String, dynamic>>()
        .map(Category.fromJson)
        .toList(growable: false);
  }

  Future<Category> createCategory(
    String token,
    AdminCategoryInput input,
  ) async {
    final response = await apiClient.sendMultipart(
      '/categories/create-upload',
      method: 'POST',
      headers: _headers(token),
      fields: input.toFields(),
      fileBytes: input.imageBytes,
      fileName: input.imageName,
      contentType: _imageContentType(input.imageName),
    );
    return Category.fromJson(response);
  }

  Future<Category> updateCategory(
    String token,
    int id,
    AdminCategoryInput input,
  ) async {
    final response = await apiClient.sendMultipart(
      '/categories/update-upload/$id',
      method: 'PUT',
      headers: _headers(token),
      fields: input.toFields(),
      fileBytes: input.imageBytes,
      fileName: input.imageName,
      contentType: _imageContentType(input.imageName),
    );
    return Category.fromJson(response);
  }

  Future<void> deleteCategory(String token, int id) async {
    await apiClient.delete('/categories/delete/$id', headers: _headers(token));
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
  };

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

class AdminCategoryInput {
  const AdminCategoryInput({
    required this.name,
    this.description,
    this.imageUrl,
    this.imageBytes,
    this.imageName,
    this.createdBy,
    this.stock,
    this.tagId,
  });

  final String name;
  final String? description;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final String? imageName;
  final String? createdBy;
  final int? stock;
  final String? tagId;

  Map<String, String> toFields() => {
    'categoryTitle': name.trim(),
    'description': ?_trimOrNull(description),
    'imageUrl': ?_trimOrNull(imageUrl),
    'createdBy': ?_trimOrNull(createdBy),
    if (stock != null) 'stock': '$stock',
    'tagId': ?_trimOrNull(tagId),
  };

  static String? _trimOrNull(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
