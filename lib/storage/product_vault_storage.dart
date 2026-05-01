import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:aurora/services/vault_service.dart';
import 'package:aurora/models/product/productModel.dart';

class ProductVaultStorage {
  static ProductVaultStorage? _instance;
  late final VaultStorage _vault;
  static bool _initialized = false;

  ProductVaultStorage._();

  static Future<ProductVaultStorage> getInstance() async {
    if (_instance == null || !_initialized) {
      _instance = ProductVaultStorage._();
      _instance!._vault = await VaultStorage.getInstance();
      _initialized = true;
    }
    return _instance!;
  }

  Future<void> saveProduct(String productId, Product product) async {
    try {
      final productJson = product.toJson();
      await _vault.saveMap('product_$productId', productJson);
    } catch (e) {
      debugPrint('[ProductVaultStorage.saveProduct] Error: $e');
      rethrow;
    }
  }

  Product? getProduct(String productId) {
    try {
      final productJson = _vault.getMap('product_$productId');
      if (productJson == null) return null;
      return Product.fromJson(productJson);
    } catch (e) {
      debugPrint('[ProductVaultStorage.getProduct] Error: $e');
      return null;
    }
  }

  Future<void> saveSellerProducts(String sellerId, List<Product> products) async {
    try {
      final productsJson = products.map((p) => p.toJson()).toList();
      await _vault.saveList('seller_products_$sellerId', productsJson);
    } catch (e) {
      debugPrint('[ProductVaultStorage.saveSellerProducts] Error: $e');
      rethrow;
    }
  }

  List<Product> getSellerProducts(String sellerId) {
    try {
      final productsJson = _vault.getList('seller_products_$sellerId');
      if (productsJson == null) return [];

      return productsJson
          .map((p) => Product.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[ProductVaultStorage.getSellerProducts] Error: $e');
      return [];
    }
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> updates) async {
    try {
      final existing = _vault.getMap('product_$productId');
      if (existing != null) {
        existing.addAll(updates);
        await _vault.saveMap('product_$productId', existing);
      }
    } catch (e) {
      debugPrint('[ProductVaultStorage.updateProduct] Error: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _vault.remove('product_$productId');
    } catch (e) {
      debugPrint('[ProductVaultStorage.deleteProduct] Error: $e');
      rethrow;
    }
  }

  Future<void> deleteSellerProducts(String sellerId) async {
    try {
      await _vault.remove('seller_products_$sellerId');
    } catch (e) {
      debugPrint('[ProductVaultStorage.deleteSellerProducts] Error: $e');
      rethrow;
    }
  }

  Future<void> refreshSellerProducts(String sellerId, List<Product> products) async {
    try {
      await deleteSellerProducts(sellerId);
      await saveSellerProducts(sellerId, products);

      for (final product in products) {
        if (product.id != null) {
          await saveProduct(product.id!, product);
        }
      }
    } catch (e) {
      debugPrint('[ProductVaultStorage.refreshSellerProducts] Error: $e');
      rethrow;
    }
  }

  Future<bool> hasProduct(String productId) async {
    try {
      return _vault.getMap('product_$productId') != null;
    } catch (e) {
      debugPrint('[ProductVaultStorage.hasProduct] Error: $e');
      return false;
    }
  }

  Future<List<String>> getAllCachedProductIds() async {
    try {
      final keys = await _vault.getAllKeys();
      return keys
          .where((k) => k.startsWith('product_') && !k.startsWith('seller_products_'))
          .map((k) => k.replaceFirst('product_', ''))
          .toList();
    } catch (e) {
      debugPrint('[ProductVaultStorage.getAllCachedProductIds] Error: $e');
      return [];
    }
  }

  Future<void> clearAllCachedProducts() async {
    try {
      final keys = await _vault.getAllKeys();
      for (final key in keys) {
        if (key.startsWith('product_') || key.startsWith('seller_products_')) {
          await _vault.remove(key);
        }
      }
    } catch (e) {
      debugPrint('[ProductVaultStorage.clearAllCachedProducts] Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getVaultStats() async {
    try {
      final keys = await _vault.getAllKeys();
      final productKeys = keys.where((k) => k.startsWith('product_')).toList();
      final sellerKeys = keys.where((k) => k.startsWith('seller_products_')).toList();

      return {
        'total_products': productKeys.length,
        'total_seller_caches': sellerKeys.length,
        'product_ids': productKeys.map((k) => k.replaceFirst('product_', '')).toList(),
        'seller_ids': sellerKeys.map((k) => k.replaceFirst('seller_products_', '')).toList(),
      };
    } catch (e) {
      debugPrint('[ProductVaultStorage.getVaultStats] Error: $e');
      return {};
    }
  }
}
