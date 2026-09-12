import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final Map<int, CartItem> _items = {};
  AppliedCoupon? _coupon;

  List<CartItem> get items => List.unmodifiable(_items.values);
  AppliedCoupon? get coupon => _coupon;
  int get itemCount =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => _items.isEmpty;
  double get regularSubtotal =>
      _items.values.fold(0, (sum, item) => sum + item.regularTotal);
  double get subtotal => _items.values.fold(0, (sum, item) => sum + item.total);
  double get productDiscount => regularSubtotal - subtotal;
  double get couponDiscount => _coupon?.discount ?? 0;
  double totalWithShipping(double shipping) =>
      (subtotal - couponDiscount + shipping).clamp(0, double.infinity);

  bool add(Product product, {int quantity = 1}) {
    final id = product.id;
    final stock = product.stock ?? 0;
    if (id == null || stock <= 0) return false;
    final current = _items[id]?.quantity ?? 0;
    final next = (current + quantity).clamp(1, stock);
    _items[id] = CartItem(product: product, quantity: next);
    _coupon = null;
    notifyListeners();
    return true;
  }

  void setQuantity(int productId, int quantity) {
    final item = _items[productId];
    if (item == null) return;
    if (quantity <= 0) {
      remove(productId);
      return;
    }
    final stock = item.product.stock ?? quantity;
    _items[productId] = item.copyWith(quantity: quantity.clamp(1, stock));
    _coupon = null;
    notifyListeners();
  }

  void remove(int productId) {
    if (_items.remove(productId) == null) return;
    _coupon = null;
    notifyListeners();
  }

  void applyCoupon(AppliedCoupon coupon) {
    _coupon = coupon;
    notifyListeners();
  }

  void removeCoupon() {
    if (_coupon == null) return;
    _coupon = null;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _coupon = null;
    notifyListeners();
  }
}
