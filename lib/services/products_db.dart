import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/storage/storage.dart';
import 'package:aurora/models/product/product.dart';

class ProductsDB {
  final SupabaseClient _client = Supabase.instance.client;

  // Get all products for current seller from vault (high speed)
  Future<List<AuroraProduct>> getProductsFromVault() async {
    try {
      final data = await Storage.getSellerData();
      if (data == null || data.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(data);
      return decoded
          .map((e) => AuroraProduct.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[ProductsDB.getProductsFromVault] Error: $e');
      return [];
    }
  }

  // Save products to vault (high speed access)
  Future<void> saveProductsToVault(List<AuroraProduct> products) async {
    try {
      final jsonStr = jsonEncode(products.map((e) => e.toJson()).toList());
      await Storage.saveSellerData(jsonStr);
    } catch (e) {
      debugPrint('[ProductsDB.updateProduct] Error: $e');
      return null;
    }
  }

  // Update product in Supabase and vault
  Future<AuroraProduct?> updateProduct(
    String asin,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _client
          .from('products')
          .update(updates)
          .eq('asin', asin)
          .select()
          .single();

      final updatedProduct = AuroraProduct.fromJson(response);

      // Update vault cache
      final cached = await getProductsFromVault();
      final index = cached.indexWhere((p) => p.asin == asin);
      if (index != -1) {
        cached[index] = updatedProduct;
        await saveProductsToVault(cached);
      }

      return updatedProduct;
    } catch (e) {
      return null;
    }
  }

  // Delete product from Supabase and vault
  Future<bool> deleteProduct(String asin) async {
    try {
      await _client.from('products').delete().eq('asin', asin);

      // Update vault cache
      final cached = await getProductsFromVault();
      cached.removeWhere((p) => p.asin == asin);
      await saveProductsToVault(cached);

      return true;
    } catch (e) {
      debugPrint('[ProductsDB.deleteProduct] Error: $e');
      return false;
    }
  }

  // Search products using edge function
  Future<List<AuroraProduct>> searchProducts({
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
          .map((e) => AuroraProduct.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[ProductsDB.searchProducts] Error: $e');
      return [];
    }
  }

  // Get single product by ASIN
  Future<AuroraProduct?> getProductByAsin(String asin) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('asin', asin)
          .maybeSingle();

      if (response == null) return null;
      return AuroraProduct.fromJson(response);
    } catch (e) {
      debugPrint('[ProductsDB.getProductByAsin] Error: $e');
      return null;
    }
  }

  // Get products by status (for filtering)
  Future<List<AuroraProduct>> getProductsByStatus(String status) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('status', status)
          .order('created_at', ascending: false);

      return response
          .map((e) => AuroraProduct.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[ProductsDB.getProductsByStatus] Error: $e');
      return [];
    }
  }

  // Get low stock products (quantity <= 10)
  Future<List<AuroraProduct>> getLowStockProducts(String sellerId) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('seller_id', sellerId)
          .lte('quantity', 10)
          .order('quantity', ascending: true);

      return response
          .map((e) => AuroraProduct.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[ProductsDB.getLowStockProducts] Error: $e');
      return [];
    }
  }
}
