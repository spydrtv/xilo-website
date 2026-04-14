import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.length;

  double get total => _items.fold(0.0, (sum, item) => sum + item.price);

  String get totalLabel => '\$${total.toStringAsFixed(2)}';

  bool contains(String sourceId, LicenseType licenseType) =>
      _items.any((i) => i.sourceId == sourceId && i.licenseType == licenseType);

  void addItem(CartItem item) {
    if (!contains(item.sourceId, item.licenseType)) {
      _items.add(item);
      notifyListeners();
    }
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
