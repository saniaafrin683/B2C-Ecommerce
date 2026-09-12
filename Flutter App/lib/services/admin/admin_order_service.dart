import '../../core/api_client.dart';

class AdminOrderService {
  AdminOrderService({required this.apiClient});

  final ApiClient apiClient;

  Future<List<AdminOrder>> getOrders(String token) async {
    final response = await apiClient.getJson(
      '/orders/list',
      headers: _headers(token),
    );
    if (response is! List) {
      throw const FormatException('Unexpected orders response.');
    }
    final orders = response
        .whereType<Map<String, dynamic>>()
        .map(AdminOrder.fromJson)
        .toList();
    orders.sort((a, b) {
      final dateComparison = (b.createdAt ?? DateTime(1970)).compareTo(
        a.createdAt ?? DateTime(1970),
      );
      return dateComparison != 0
          ? dateComparison
          : (b.id ?? 0).compareTo(a.id ?? 0);
    });
    return orders;
  }

  Future<AdminOrder> getOrder(String token, int id) async {
    final response = await apiClient.getJson(
      '/orders/$id',
      headers: _headers(token),
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Unexpected order details response.');
    }
    return AdminOrder.fromJson(response);
  }

  Future<void> updateStatus(String token, int id, String status) async {
    await apiClient.putJson(
      '/orders/status/$id',
      headers: _headers(token),
      body: {'status': status},
    );
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
  };
}

class AdminOrder {
  const AdminOrder({
    this.id,
    this.reference,
    this.createdAt,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.shippingAddress,
    this.billingAddress,
    this.priority,
    this.regularSubtotal = 0,
    this.subtotal = 0,
    this.productDiscountTotal = 0,
    this.couponDiscount = 0,
    this.tax = 0,
    this.shippingCost = 0,
    this.totalAmount = 0,
    this.couponCode,
    this.paymentMethod,
    this.paymentStatus,
    this.orderStatus,
    this.deliveryNumber,
    this.trackingNumber,
    this.courierName,
    this.shipmentStatus,
    this.shippedDate,
    this.estimatedDeliveryDate,
    this.deliveredDate,
    this.items = const [],
  });

  final int? id;
  final String? reference;
  final DateTime? createdAt;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? shippingAddress;
  final String? billingAddress;
  final String? priority;
  final double regularSubtotal;
  final double subtotal;
  final double productDiscountTotal;
  final double couponDiscount;
  final double tax;
  final double shippingCost;
  final double totalAmount;
  final String? couponCode;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? orderStatus;
  final String? deliveryNumber;
  final String? trackingNumber;
  final String? courierName;
  final String? shipmentStatus;
  final DateTime? shippedDate;
  final DateTime? estimatedDeliveryDate;
  final DateTime? deliveredDate;
  final List<AdminOrderItem> items;

  factory AdminOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['orderItems'];
    return AdminOrder(
      id: _asInt(json['id'] ?? json['databaseId']),
      reference: _asString(json['orderId']),
      createdAt: _asDate(json['createdAt']),
      customerName: _asString(json['customerName']),
      customerEmail: _asString(json['customerEmail']),
      customerPhone: _asString(json['customerPhone']),
      shippingAddress: _asString(json['shippingAddress']),
      billingAddress: _asString(json['billingAddress']),
      priority: _asString(json['priority']),
      regularSubtotal: _asDouble(json['regularSubtotal']),
      subtotal: _asDouble(
        json['subtotalAfterProductDiscount'] ?? json['subtotal'],
      ),
      productDiscountTotal: _asDouble(json['productDiscountTotal']),
      couponDiscount: _asDouble(json['couponDiscount'] ?? json['discount']),
      tax: _asDouble(json['tax']),
      shippingCost: _asDouble(json['shippingCost']),
      totalAmount: _asDouble(
        json['totalAmount'] ?? json['grandTotal'] ?? json['finalTotal'],
      ),
      couponCode: _asString(json['couponCode']),
      paymentMethod: _asString(json['paymentMethod']),
      paymentStatus: _asString(json['paymentStatus']),
      orderStatus: _asString(json['orderStatus']),
      deliveryNumber: _asString(json['deliveryNumber']),
      trackingNumber: _asString(json['trackingNumber']),
      courierName: _asString(json['courierName']),
      shipmentStatus: _asString(json['shipmentStatus']),
      shippedDate: _asDate(json['shippedDate']),
      estimatedDeliveryDate: _asDate(json['estimatedDeliveryDate']),
      deliveredDate: _asDate(json['deliveredDate']),
      items: rawItems is List
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map(AdminOrderItem.fromJson)
                .toList(growable: false)
          : const [],
    );
  }
}

class AdminOrderItem {
  const AdminOrderItem({
    this.productId,
    this.name,
    this.imageUrl,
    this.size,
    this.color,
    this.quantity = 0,
    this.unitPrice = 0,
    this.originalUnitPrice = 0,
    this.discountRate = 0,
    this.lineTotal = 0,
  });

  final int? productId;
  final String? name;
  final String? imageUrl;
  final String? size;
  final String? color;
  final int quantity;
  final double unitPrice;
  final double originalUnitPrice;
  final double discountRate;
  final double lineTotal;

  factory AdminOrderItem.fromJson(Map<String, dynamic> json) => AdminOrderItem(
    productId: _asInt(json['productId']),
    name: _asString(json['productName']),
    imageUrl: _asString(json['productImage']),
    size: _asString(json['size']),
    color: _asString(json['color']),
    quantity: _asInt(json['quantity']) ?? 0,
    unitPrice: _asDouble(json['discountedUnitPrice'] ?? json['unitPrice']),
    originalUnitPrice: _asDouble(
      json['originalUnitPrice'] ?? json['unitPrice'],
    ),
    discountRate: _asDouble(json['productDiscountRate']),
    lineTotal: _asDouble(json['lineTotal']),
  );
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
