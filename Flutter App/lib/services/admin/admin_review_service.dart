import '../../core/api_client.dart';

class AdminReviewService {
  AdminReviewService({required this.apiClient});

  final ApiClient apiClient;

  Future<List<AdminReview>> getReviews(String token) async {
    final response = await apiClient.getJson(
      '/reviews/list',
      headers: _headers(token),
    );
    if (response is! List) {
      throw const FormatException('Unexpected reviews response.');
    }
    final reviews = response
        .whereType<Map<String, dynamic>>()
        .map(AdminReview.fromJson)
        .toList(growable: false);
    reviews.sort((a, b) {
      final date = (b.reviewDate ?? b.createdAt ?? DateTime(1970)).compareTo(
        a.reviewDate ?? a.createdAt ?? DateTime(1970),
      );
      return date != 0 ? date : (b.id ?? 0).compareTo(a.id ?? 0);
    });
    return reviews;
  }

  Future<AdminReview> getReview(String token, int id) async {
    final response = await apiClient.getJson(
      '/reviews/$id',
      headers: _headers(token),
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Unexpected review details response.');
    }
    return AdminReview.fromJson(response);
  }

  Future<AdminReview> approveReview(String token, int id) async {
    final response = await apiClient.putJson(
      '/reviews/approve/$id',
      headers: _headers(token),
      body: const <String, dynamic>{},
    );
    return AdminReview.fromJson(response);
  }

  Future<AdminReview> rejectReview(String token, int id) async {
    final response = await apiClient.putJson(
      '/reviews/reject/$id',
      headers: _headers(token),
      body: const <String, dynamic>{},
    );
    return AdminReview.fromJson(response);
  }

  Future<void> deleteReview(String token, int id) async {
    await apiClient.delete('/reviews/delete/$id', headers: _headers(token));
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
  };
}

class AdminReview {
  const AdminReview({
    this.id,
    this.reviewCode,
    this.productId,
    this.productName,
    this.productImageUrl,
    this.orderId,
    this.customerId,
    this.customerName,
    this.customerEmail,
    this.rating,
    this.reviewTitle,
    this.reviewMessage,
    this.reviewStatus,
    this.reviewDate,
    this.replyMessage,
    this.createdAt,
    this.updatedAt,
    this.reviewImageUrls = const [],
  });

  final int? id;
  final String? reviewCode;
  final int? productId;
  final String? productName;
  final String? productImageUrl;
  final int? orderId;
  final int? customerId;
  final String? customerName;
  final String? customerEmail;
  final int? rating;
  final String? reviewTitle;
  final String? reviewMessage;
  final String? reviewStatus;
  final DateTime? reviewDate;
  final String? replyMessage;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> reviewImageUrls;

  String get normalizedStatus {
    final value = reviewStatus?.trim().toLowerCase();
    return value == null || value.isEmpty ? 'pending' : value;
  }

  bool get isPending => normalizedStatus == 'pending';
  bool get isApproved => normalizedStatus == 'approved';
  bool get isRejected => normalizedStatus == 'rejected';

  String get displayTitle {
    final value = reviewTitle?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return 'Review #${id ?? '—'}';
  }

  String get displayProductName {
    final value = productName?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return 'Unnamed product';
  }

  String get displayCustomerName {
    final value = customerName?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return 'Unknown customer';
  }

  String get displayStatus => reviewStatus?.trim().isNotEmpty == true
      ? reviewStatus!.trim()
      : 'Pending';

  String get displayBody {
    final value = reviewMessage?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return 'No review message was provided.';
  }

  String get displayReply {
    final value = replyMessage?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return 'No admin reply yet.';
  }

  static AdminReview fromJson(Map<String, dynamic> json) {
    return AdminReview(
      id: _asInt(json['id']),
      reviewCode: _asString(json['reviewCode']),
      productId: _asInt(json['productId']),
      productName: _asString(json['productName']),
      productImageUrl: _extractProductImageUrl(json),
      orderId: _asInt(json['orderId']),
      customerId: _asInt(json['customerId']),
      customerName: _asString(json['customerName']),
      customerEmail: _asString(json['customerEmail']),
      rating: _asInt(json['rating']) ?? 0,
      reviewTitle: _asString(json['reviewTitle']),
      reviewMessage: _asString(json['reviewMessage']),
      reviewStatus: _asString(json['reviewStatus']),
      reviewDate: _asDate(json['reviewDate']),
      replyMessage: _asString(json['replyMessage']),
      createdAt: _asDate(json['createdAt']),
      updatedAt: _asDate(json['updatedAt']),
      reviewImageUrls: _extractImageUrls(json),
    );
  }

  static List<String> _extractImageUrls(Map<String, dynamic> json) {
    final candidates = [
      json['reviewImageUrls'],
      json['reviewImages'],
      json['reviewImage'],
      json['imageUrls'],
      json['images'],
    ];
    final result = <String>[];
    for (final candidate in candidates) {
      if (candidate is String) {
        final value = candidate.trim();
        if (value.isNotEmpty) {
          result.add(value);
        }
      } else if (candidate is Iterable) {
        for (final item in candidate) {
          final value = item?.toString().trim();
          if (value != null && value.isNotEmpty) {
            result.add(value);
          }
        }
      }
    }
    return result.toSet().toList(growable: false);
  }

  static String? _extractProductImageUrl(Map<String, dynamic> json) {
    return _asString(json['productImageUrl']) ??
        _asString(json['productImage']) ??
        _asString(json['imageUrl']);
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
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

class AdminReviewSummary {
  const AdminReviewSummary({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.averageRating,
  });

  final int total;
  final int pending;
  final int approved;
  final int rejected;
  final double averageRating;

  factory AdminReviewSummary.fromReviews(List<AdminReview> reviews) {
    final total = reviews.length;
    final pending = reviews.where((review) => review.isPending).length;
    final approved = reviews.where((review) => review.isApproved).length;
    final rejected = reviews.where((review) => review.isRejected).length;
    final ratings = reviews
        .map((review) => review.rating ?? 0)
        .where((value) => value > 0);
    final averageRating = ratings.isEmpty
        ? 0
        : ratings.reduce((a, b) => a + b) / ratings.length;
    return AdminReviewSummary(
      total: total,
      pending: pending,
      approved: approved,
      rejected: rejected,
      averageRating: double.parse(averageRating.toStringAsFixed(1)),
    );
  }
}
