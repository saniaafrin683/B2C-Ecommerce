import '../core/api_client.dart';
import '../models/category.dart';
import '../models/product_page_response.dart';
import '../models/product.dart';

class CatalogService {
  CatalogService({required this.apiClient});

  final ApiClient apiClient;

  Future<ProductPageResponse> getProductsPage({
    int page = 0,
    int size = 12,
    String sortBy = 'id',
    String sortDir = 'desc',
  }) async {
    final json = await apiClient.getJson(
      '/products/page',
      queryParameters: <String, dynamic>{
        'page': page,
        'size': size,
        'sortBy': sortBy,
        'sortDir': sortDir,
      },
    );
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Unexpected product page response.');
    }
    return ProductPageResponse.fromJson(json);
  }

  Future<ProductPageResponse> searchProducts({
    String? query,
    String? category,
    String? brand,
    String? gender,
    String? tag,
    double? minPrice,
    double? maxPrice,
    int page = 0,
    int size = 12,
    String sortBy = 'id',
    String sortDir = 'desc',
  }) async {
    final queryParameters = <String, dynamic>{
      'query': query?.trim(),
      'category': category?.trim(),
      'brand': brand?.trim(),
      'gender': gender?.trim(),
      'tag': tag?.trim(),
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'page': page,
      'size': size,
      'sortBy': sortBy,
      'sortDir': sortDir,
    };
    queryParameters.removeWhere((_, value) {
      if (value == null) {
        return true;
      }
      if (value is String && value.trim().isEmpty) {
        return true;
      }
      return false;
    });

    final json = await apiClient.getJson(
      '/products/search',
      queryParameters: queryParameters,
    );
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Unexpected product search response.');
    }
    return ProductPageResponse.fromJson(json);
  }

  Future<ProductPageResponse> searchByCategory({
    required String category,
    int page = 0,
    int size = 12,
    String sortBy = 'id',
    String sortDir = 'desc',
  }) async {
    return searchProducts(
      category: category,
      page: page,
      size: size,
      sortBy: sortBy,
      sortDir: sortDir,
    );
  }

  Future<List<Category>> getCategories() async {
    final json = await apiClient.getJson('/categories/list');
    if (json is! List) {
      throw const FormatException('Unexpected categories response.');
    }

    return json
        .whereType<Map<String, dynamic>>()
        .map(
          (value) => Category.fromJson(
            value,
            imageUrlResolver: _resolveCategoryImageUrl,
          ),
        )
        .toList(growable: false);
  }

  String? _resolveCategoryImageUrl(String? imageUrl) {
    final value = imageUrl?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.toLowerCase().startsWith('data:image/')) return value;
    return apiClient.normalizeImageUrl(value);
  }

  Future<Product> getProduct(int id) async {
    final json = await apiClient.getJson('/products/$id');
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Unexpected product response.');
    }
    return Product.fromJson(json);
  }
}
