import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:styleora_flutter/core/api_client.dart';
import 'package:styleora_flutter/core/cart_provider.dart';
import 'package:styleora_flutter/core/wishlist_provider.dart';
import 'package:styleora_flutter/models/cart_item.dart';
import 'package:styleora_flutter/models/customer_order.dart';
import 'package:styleora_flutter/models/product.dart';
import 'package:styleora_flutter/models/customer_profile.dart';
import 'package:styleora_flutter/services/customer_commerce_service.dart';

void main() {
  const product = Product(
    id: 1,
    name: 'Test Product',
    price: 100,
    discount: 10,
    stock: 5,
  );

  test('cart calculates discounts, coupon, delivery, and stock limits', () {
    final cart = CartProvider();

    expect(cart.add(product, quantity: 2), isTrue);
    expect(cart.regularSubtotal, 200);
    expect(cart.subtotal, 180);
    expect(cart.productDiscount, 20);

    cart.applyCoupon(const AppliedCoupon(code: 'SAVE25', discount: 25));
    expect(cart.totalWithShipping(80), 235);

    cart.setQuantity(1, 3);
    expect(cart.coupon, isNull);
    expect(cart.subtotal, 270);

    cart.add(product, quantity: 20);
    expect(cart.items.single.quantity, 5);
  });

  test('wishlist toggles products without duplicates', () {
    final wishlist = WishlistProvider();

    wishlist.toggle(product);
    wishlist.toggle(product);
    expect(wishlist.items, isEmpty);

    wishlist.toggle(product);
    expect(wishlist.itemCount, 1);
  });

  test('customer order maps backend pricing and item payload', () {
    final order = CustomerOrder.fromJson({
      'id': 7,
      'orderId': 'ORD-7',
      'orderStatus': 'Delivered',
      'subtotalAfterProductDiscount': 90,
      'couponDiscount': 10,
      'shippingCost': 20,
      'totalAmount': 100,
      'orderItems': [
        {
          'productId': 1,
          'productName': 'Test Product',
          'quantity': 1,
          'discountedUnitPrice': 90,
          'lineTotal': 90,
        },
      ],
    });

    expect(order.reference, 'ORD-7');
    expect(order.isDelivered, isTrue);
    expect(order.total, 100);
    expect(order.items.single.productId, 1);
    expect(order.items.single.unitPrice, 90);
  });

  test('create order sends a generated reference and order date', () async {
    late Map<String, dynamic> payload;
    final client = MockClient((request) async {
      payload = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({
          'id': 8,
          'orderId': payload['orderId'],
          'createdAt': payload['createdAt'],
          'totalAmount': 170,
          'orderItems': const [],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = CustomerCommerceService(
      apiClient: ApiClient(httpClient: client, baseUrl: 'http://test'),
    );

    final order = await service.createOrder(
      token: 'token',
      customer: const CustomerProfile(
        fullName: 'Test Customer',
        email: 'test@example.com',
      ),
      items: const [CartItem(product: product, quantity: 1)],
      phone: '01700000000',
      shippingAddress: 'Dhaka, Bangladesh',
      paymentMethod: 'Cash on Delivery',
      shippingCost: 80,
    );

    expect(payload['orderId'], startsWith('SO-'));
    expect(payload['createdAt'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    expect(order.reference, payload['orderId']);
  });
}
