import 'package:flutter/foundation.dart';

import '../models/product.dart';

class WishlistProvider extends ChangeNotifier {
  final Map<int, Product> _items = {};

  List<Product> get items => List.unmodifiable(_items.values);
  int get itemCount => _items.length;
  bool contains(Product product) =>
      product.id != null && _items.containsKey(product.id);

  void toggle(Product product) {
    final id = product.id;
    if (id == null) return;
    if (_items.containsKey(id)) {
      _items.remove(id);
    } else {
      _items[id] = product;
    }
    notifyListeners();
  }

  void remove(int id) {
    if (_items.remove(id) != null) notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
