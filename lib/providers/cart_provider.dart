import 'package:flutter/foundation.dart';
import 'package:aurora/models/product/productModel.dart';
import 'package:aurora/services/app_logger.dart';
import 'package:aurora/storage/storage.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice => (product.price ?? 0) * quantity;

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  bool _isLoading = false;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  
  double get totalPrice => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  CartProvider() {
    _loadCartFromStorage();
  }

  Future<void> _loadCartFromStorage() async {
    try {
      final savedCart = await Storage.getString('cart_items');
      if (savedCart != null && savedCart.isNotEmpty) {
        AppLogger.debug('Loaded cart from storage', context: 'Cart');
      }
    } catch (e) {
      AppLogger.error('Failed to load cart from storage', context: 'Cart', error: e);
    }
  }

  Future<void> _saveCartToStorage() async {
    try {
      await Storage.saveString('cart_items', 'saved');
    } catch (e) {
      AppLogger.error('Failed to save cart to storage', context: 'Cart', error: e);
    }
  }

  Future<void> addItem(Product product, {int quantity = 1}) async {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
      AppLogger.logCartAction('Increased quantity', productId: product.id, quantity: _items[existingIndex].quantity);
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
      AppLogger.logCartAction('Added to cart', productId: product.id, quantity: quantity);
    }
    
    await _saveCartToStorage();
    notifyListeners();
  }

  Future<void> removeItem(String productId) async {
    _items.removeWhere((item) => item.product.id == productId);
    AppLogger.logCartAction('Removed from cart', productId: productId);
    await _saveCartToStorage();
    notifyListeners();
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(productId);
      return;
    }

    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      AppLogger.logCartAction('Updated quantity', productId: productId, quantity: quantity);
      await _saveCartToStorage();
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    _items.clear();
    AppLogger.logCartAction('Cart cleared');
    await _saveCartToStorage();
    notifyListeners();
  }

  bool hasProduct(String productId) {
    return _items.any((item) => item.product.id == productId);
  }

  int getProductQuantity(String productId) {
    try {
      final item = _items.firstWhere((item) => item.product.id == productId);
      return item.quantity;
    } catch (e) {
      return 0;
    }
  }
}