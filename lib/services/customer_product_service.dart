// lib/services/customer_product_service.dart
import 'package:flutter/foundation.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stockQuantity;
  final String categoryId;
  final String? imageUrl;
  final bool isAvailable;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stockQuantity,
    required this.categoryId,
    this.imageUrl,
    this.isAvailable = true,
    required this.createdAt,
  });
}

class CustomerProductService extends ChangeNotifier {
  final List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement actual API call to fetch products
      await Future.delayed(const Duration(milliseconds: 500));
      
      _products.clear();
      // Sample data for now
      _products.add(Product(
        id: '1',
        name: 'Sample Product',
        description: 'A sample product description',
        price: 99.99,
        stockQuantity: 100,
        categoryId: 'cat1',
        isAvailable: true,
        createdAt: DateTime.now(),
      ));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchProducts(String query) async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement actual search functionality
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> filterByCategory(String categoryId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement category filtering
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Product? getProductById(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }
}
