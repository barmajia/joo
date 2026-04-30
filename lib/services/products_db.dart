import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/models/product/productModel.dart';
import 'package:aurora/storage/product_vault_storage.dart';

class ProductsDB {
  final SupabaseClient _client = Supabase.instance.client;
  ProductVaultStorage? _productVault;

  ProductsDB();

  Future<ProductVaultStorage> get _vault async {
    _productVault ??= await ProductVaultStorage.getInstance();
    return _productVault!;
  }

  Future<List<Product>> getProductsFromVault() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final vault = await _vault;
      return vault.getSellerProducts(userId);
    } catch (e) {
      debugPrint('[ProductsDB.getProductsFromVault] Error: $e');
      return [];
    }
  }

  Future<void> saveProductsToVault(List<Product> products) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final vault = await _vault;
      await vault.saveSellerProducts(userId, products);
    } catch (e) {
      debugPrint('[ProductsDB.saveProductsToVault] Error: $e');
    }
  }

  Future<Product?> updateProduct(
    String productId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _client
          .from('products')
          .update(updates)
          .eq('id', productId)
          .select()
          .single();

      final updatedProduct = Product.fromJson(response);

      final vault = await _vault;
      await vault.saveProduct(productId, updatedProduct);

      return updatedProduct;
    } catch (e) {
      debugPrint('[ProductsDB.updateProduct] Error: $e');
      return null;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await _client.from('products').delete().eq('id', productId);

      final vault = await _vault;
      await vault.deleteProduct(productId);

      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        final cached = vault.getSellerProducts(userId);
        cached.removeWhere((p) => p.id == productId);
        await vault.saveSellerProducts(userId, cached);
      }

      return true;
    } catch (e) {
      debugPrint('[ProductsDB.deleteProduct] Error: $e');
      return false;
    }
  }

  Future<List<Product>> searchProducts({
    String query = '',
    String? status,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'search-products',
        body: {
          'query': query,
          'status': status,
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.status != 200) return [];

      final data = jsonDecode(response.data as String) as List;
      return data
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[ProductsDB.searchProducts] Error: $e');
      return [];
    }
  }

  Future<Product?> getProductById(String productId) async {
    try {
      final vault = await _vault;
      final cachedProduct = vault.getProduct(productId);
      if (cachedProduct != null) return cachedProduct;

      final response = await _client
          .from('products')
          .select()
          .eq('id', productId)
          .maybeSingle();

      if (response == null) return null;

      final product = Product.fromJson(response);
      await vault.saveProduct(productId, product);

      return product;
    } catch (e) {
      debugPrint('[ProductsDB.getProductById] Error: $e');
      return null;
    }
  }

  Future<List<Product>> getProductsByStatus(String status) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('status', status)
          .order('created_at', ascending: false);

      return response
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[ProductsDB.getProductsByStatus] Error: $e');
      return [];
    }
  }

  Future<List<Product>> getLowStockProducts(String sellerId) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('seller_id', sellerId)
          .lte('quantity', 10)
          .order('quantity', ascending: true);

      return response
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[ProductsDB.getLowStockProducts] Error: $e');
      return [];
    }
  }

  Future<void> refreshVault() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _client
          .from('products')
          .select()
          .eq('seller_id', userId)
          .order('created_at', ascending: false);

      final products = response
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();

      final vault = await _vault;
      await vault.refreshSellerProducts(userId, products);
    } catch (e) {
      debugPrint('[ProductsDB.refreshVault] Error: $e');
    }
  }
}
