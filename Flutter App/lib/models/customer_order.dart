class CustomerOrder {
  const CustomerOrder({
    this.id,
    this.reference,
    this.createdAt,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.shippingAddress,
    this.billingAddress,
    this.subtotal = 0,
    this.regularSubtotal = 0,
    this.productDiscount = 0,
    this.couponDiscount = 0,
    this.tax = 0,
    this.shippingCost = 0,
    this.total = 0,
    this.couponCode,
    this.paymentMethod,
    this.paymentStatus,
    this.orderStatus,
    this.trackingNumber,
    this.courierName,
    this.shipmentStatus,
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
  final double subtotal;
  final double regularSubtotal;
  final double productDiscount;
  final double couponDiscount;
  final double tax;
  final double shippingCost;
  final double total;
  final String? couponCode;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? orderStatus;
  final String? trackingNumber;
  final String? courierName;
  final String? shipmentStatus;
  final List<CustomerOrderItem> items;

  bool get isDelivered => orderStatus?.toLowerCase() == 'delivered';

  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['orderItems'];
    return CustomerOrder(
      id: _int(json['id'] ?? json['databaseId']),
      reference: _string(json['orderId']),
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}'),
      customerName: _string(json['customerName']),
      customerEmail: _string(json['customerEmail']),
      customerPhone: _string(json['customerPhone']),
      shippingAddress: _string(json['shippingAddress']),
      billingAddress: _string(json['billingAddress']),
      subtotal: _double(
        json['subtotalAfterProductDiscount'] ?? json['subtotal'],
      ),
      regularSubtotal: _double(json['regularSubtotal']),
      productDiscount: _double(json['productDiscountTotal']),
      couponDiscount: _double(json['couponDiscount'] ?? json['discount']),
      tax: _double(json['tax']),
      shippingCost: _double(json['shippingCost']),
      total: _double(
        json['totalAmount'] ?? json['grandTotal'] ?? json['finalTotal'],
      ),
      couponCode: _string(json['couponCode']),
      paymentMethod: _string(json['paymentMethod']),
      paymentStatus: _string(json['paymentStatus']),
      orderStatus: _string(json['orderStatus']),
      trackingNumber: _string(json['trackingNumber']),
      courierName: _string(json['courierName']),
      shipmentStatus: _string(json['shipmentStatus']),
      items: rawItems is List
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map(CustomerOrderItem.fromJson)
                .toList()
          : const [],
    );
  }
}

class CustomerOrderItem {
  const CustomerOrderItem({
    this.productId,
    this.name,
    this.imageUrl,
    this.size,
    this.color,
    this.quantity = 0,
    this.unitPrice = 0,
    this.lineTotal = 0,
  });

  final int? productId;
  final String? name;
  final String? imageUrl;
  final String? size;
  final String? color;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  factory CustomerOrderItem.fromJson(Map<String, dynamic> json) =>
      CustomerOrderItem(
        productId: _int(json['productId']),
        name: _string(json['productName']),
        imageUrl: _string(json['productImage']),
        size: _string(json['size']),
        color: _string(json['color']),
        quantity: _int(json['quantity']) ?? 0,
        unitPrice: _double(json['discountedUnitPrice'] ?? json['unitPrice']),
        lineTotal: _double(json['lineTotal']),
      );
}

int? _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value');
double _double(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
String? _string(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
