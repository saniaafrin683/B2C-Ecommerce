import 'dart:typed_data';

import '../core/api_client.dart';
import '../models/cart_item.dart';
import '../models/customer_order.dart';
import '../models/customer_profile.dart';

class CustomerCommerceService {
  CustomerCommerceService({required this.apiClient});

  final ApiClient apiClient;

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
  };

  Future<AppliedCoupon> applyCoupon(
    String token,
    String code,
    List<CartItem> items,
  ) async {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
    final json = await apiClient.postJson(
      '/coupons/apply',
      headers: _headers(token),
      body: {
        'couponCode': code.trim(),
        'subtotal': subtotal,
        'orderItems': items.map(_itemPayload).toList(),
      },
    );
    return AppliedCoupon(
      code: (json['couponCode'] ?? code).toString(),
      discount: _double(json['couponDiscount'] ?? json['discountAmount']),
      message: json['message']?.toString(),
    );
  }

  Future<CustomerOrder> createOrder({
    required String token,
    required CustomerProfile customer,
    required List<CartItem> items,
    required String phone,
    required String shippingAddress,
    required String paymentMethod,
    required double shippingCost,
    String? couponCode,
  }) async {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
    final regular = items.fold<double>(
      0,
      (sum, item) => sum + item.regularTotal,
    );
    final now = DateTime.now();
    final reference = 'SO-${now.millisecondsSinceEpoch}';
    final orderDate =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final json = await apiClient.postJson(
      '/orders/create',
      headers: _headers(token),
      body: {
        'orderId': reference,
        'createdAt': orderDate,
        'customerName': customer.fullName,
        'customerEmail': customer.email,
        'customerPhone': phone.trim(),
        'shippingAddress': shippingAddress.trim(),
        'billingAddress': shippingAddress.trim(),
        'regularSubtotal': regular,
        'subtotal': subtotal,
        'subtotalAfterProductDiscount': subtotal,
        'productDiscountTotal': regular - subtotal,
        'shippingCost': shippingCost,
        'couponCode': couponCode,
        'paymentMethod': paymentMethod,
        'orderStatus': 'Pending',
        'orderItems': items.map(_itemPayload).toList(),
      },
    );
    return CustomerOrder.fromJson(json);
  }

  Future<List<CustomerOrder>> getMyOrders(String token) async {
    final response = await apiClient.getJson(
      '/orders/my',
      headers: _headers(token),
    );
    if (response is! List) {
      throw const FormatException('Unexpected orders response.');
    }
    return response
        .whereType<Map<String, dynamic>>()
        .map(CustomerOrder.fromJson)
        .toList();
  }

  Future<CustomerOrder> getMyOrder(String token, int id) async {
    final response = await apiClient.getJson(
      '/orders/my/$id',
      headers: _headers(token),
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Unexpected order response.');
    }
    return CustomerOrder.fromJson(response);
  }

  Future<Uint8List> getInvoice(String token, int orderId) => apiClient.getBytes(
    '/orders/my/$orderId/invoice',
    headers: _headers(token),
  );

  Future<String> initiatePayment(String token, int orderId) async {
    final json = await apiClient.postJson(
      '/payments/initiate',
      headers: _headers(token),
      body: {'orderId': orderId},
    );
    final url = json['paymentUrl']?.toString();
    if (url == null || url.isEmpty) {
      throw const FormatException('Payment URL was not returned.');
    }
    return url;
  }

  Future<List<Map<String, dynamic>>> getReviewsForOrder(
    String token,
    int orderId,
  ) async {
    final response = await apiClient.getJson(
      '/reviews/my/order/$orderId',
      headers: _headers(token),
    );
    return response is List
        ? response.whereType<Map<String, dynamic>>().toList()
        : const [];
  }

  Future<void> submitReview(
    String token,
    int orderId,
    int productId,
    int rating,
    String comment,
  ) async {
    await apiClient.postJson(
      '/reviews/submit',
      headers: _headers(token),
      body: {
        'orderId': orderId,
        'productId': productId,
        'rating': rating,
        'comment': comment.trim(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getReturns(
    String token,
    int customerId,
  ) async {
    final response = await apiClient.getJson(
      '/returns/customer/$customerId',
      headers: _headers(token),
    );
    return response is List
        ? response.whereType<Map<String, dynamic>>().toList()
        : const [];
  }

  Future<void> requestReturn(
    String token,
    int orderId,
    int customerId,
    int productId,
    String reason,
    String note,
  ) async {
    await apiClient.postJson(
      '/returns/request',
      headers: _headers(token),
      body: {
        'orderId': orderId,
        'customerId': customerId,
        'productId': productId,
        'reason': reason.trim(),
        'note': note.trim(),
      },
    );
  }

  Future<CustomerProfile> getProfile(String token) async {
    final response = await apiClient.getJson(
      '/customers/profile',
      headers: _headers(token),
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Unexpected profile response.');
    }
    return CustomerProfile.fromJson(response);
  }

  Map<String, dynamic> _itemPayload(CartItem item) => {
    'productId': item.product.id,
    'productName': item.product.name,
    'productImage': item.product.imageUrl,
    'quantity': item.quantity,
    'unitPrice': item.product.effectivePrice,
    'lineTotal': item.total,
  };
}

double _double(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
