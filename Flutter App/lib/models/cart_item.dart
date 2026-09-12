import 'product.dart';

class CartItem {
  const CartItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get regularTotal => (product.price ?? 0) * quantity;
  double get total => product.effectivePrice * quantity;

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);
}

class AppliedCoupon {
  const AppliedCoupon({
    required this.code,
    required this.discount,
    this.message,
  });

  final String code;
  final double discount;
  final String? message;
}
