import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/models/product/productModel.dart';
import 'package:aurora/models/product/product_deal.dart';
import 'package:aurora/models/product/product_secret.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Product>> getSellerProducts(String sellerId) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('seller_id', sellerId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  Future<Product> getProductById(String productId) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('id', productId)
          .single();

      return Product.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load product: $e');
    }
  }

  Future<List<ProductDeal>> getProductDeals(String productId) async {
    try {
      final response = await _supabase
          .from('product_deals')
          .select()
          .eq('product_id', productId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List).map((json) => ProductDeal.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load product deals: $e');
    }
  }

  Future<List<ProductSecret>> getProductSecrets(String productId) async {
    try {
      final response = await _supabase
          .from('vault.product_secrets')
          .select()
          .eq('product_id', productId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => ProductSecret.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load product secrets: $e');
    }
  }
}
