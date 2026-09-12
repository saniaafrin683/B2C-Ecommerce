class Category {
  final int? id;
  final String? categoryTitle;
  final String? createdBy;
  final int? stock;
  final String? tagId;
  final String? description;
  final String? imageUrl;

  const Category({
    this.id,
    this.categoryTitle,
    this.createdBy,
    this.stock,
    this.tagId,
    this.description,
    this.imageUrl,
  });

  factory Category.fromJson(
    Map<String, dynamic> json, {
    String? Function(String?)? imageUrlResolver,
  }) {
    final imageUrl = _asString(json['imageUrl']);
    return Category(
      id: _asInt(json['id']),
      categoryTitle: _asString(json['categoryTitle']),
      createdBy: _asString(json['createdBy']),
      stock: _asInt(json['stock']),
      tagId: _asString(json['tagId']),
      description: _asString(json['description']),
      imageUrl: imageUrlResolver?.call(imageUrl) ?? imageUrl,
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
}
