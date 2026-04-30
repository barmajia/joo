import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/models/product/productModel.dart';
import 'package:aurora/storage/product_vault_storage.dart';

class ProductsDB {
  final SupabaseClient _client = Supabase.instance.client;
  late final ProductVaultStorage _productVault;

  ProductsDB() {
    _init();
  }

  Future<void> _init() async {
    _productVault = await ProductVaultStorage.getInstance();
  }

  // Get all products for current seller from vault (high speed)
  Future<List<Product>> getProductsFromVault() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      await _init();
      return _productVault.getSellerProducts(userId);
    } catch (e) {
      debugPrint('[ProductsDB.getProductsFromVault] Error: $e');
      return [];
    }
  }

  // Save products to vault (high speed access)
  Future<void> saveProductsToVault(List<Product> products) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _init();
      await _productVault.saveSellerProducts(userId, products);
    } catch (e) {
      debugPrint('[ProductsDB.saveProductsToVault] Error: $e');
    }
  }

  // Update product in Supabase and vault
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

      // Update vault cache
      await _init();
      await _productVault.saveProduct(productId, updatedProduct);

      return updatedProduct;
    } catch (e) {
      debugPrint('[ProductsDB.updateProduct] Error: $e');
      return null;
    }
  }

  // Delete product from Supabase and vault
  Future<bool> deleteProduct(String productId) async {
    try {
      await _client.from('products').delete().eq('id', productId);

      // Update vault cache
      await _init();
      await _productVault.deleteProduct(productId);

      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        final cached = _productVault.getSellerProducts(userId);
        cached.removeWhere((p) => p.id == productId);
        await _productVault.saveSellerProducts(userId, cached);
      }

      return true;
    } catch (e) {
      debugPrint('[ProductsDB.deleteProduct] Error: $e');
      return false;
    }
  }

  // Search products using edge function
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

  // Get single product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      // Check vault first
      await _init();
      final cachedProduct = _productVault.getProduct(productId);
      if (cachedProduct != null) return cachedProduct;

      // Fallback to Supabase
      final response = await _client
          .from('products')
          .select()
          .eq('id', productId)
          .maybeSingle();

      if (response == null) return null;

      final product = Product.fromJson(response);
      await _productVault.saveProduct(productId, product);

      return product;
    } catch (e) {
      debugPrint('[ProductsDB.getProductById] Error: $e');
      return null;
    }
  }

  // Get products by status (for filtering)
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

  // Get low stock products (quantity <= 10)
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

  // Refresh vault with latest data from Supabase
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

      await _init();
      await _productVault.refreshSellerProducts(userId, products);
    } catch (e) {
      debugPrint('[ProductsDB.refreshVault] Error: $e');
    }
  }
}
