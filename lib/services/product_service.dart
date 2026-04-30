import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/models/product/productModel.dart';
import 'package:aurora/models/product/product_deal.dart';
import 'package:aurora/models/product/product_secret.dart';
import 'package:aurora/storage/product_vault_storage.dart';
import 'package:aurora/storage/product_secrets_storage.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final ProductVaultStorage _productVault;
  late final ProductSecretsStorage _secretsStorage;

  ProductService() {
    _init();
  }

  Future<void> _init() async {
    _productVault = await ProductVaultStorage.getInstance();
    _secretsStorage = await ProductSecretsStorage.getInstance();
  }

  Future<List<Product>> getSellerProducts(String sellerId) async {
    try {
      // Check vault first
      await _init();
      final cachedProducts = _productVault.getSellerProducts(sellerId);
      if (cachedProducts.isNotEmpty) return cachedProducts;

      // Fallback to Supabase
      final response = await _supabase
          .from('products')
          .select()
          .eq('seller_id', sellerId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      final products = (response as List).map((json) => Product.fromJson(json)).toList();

      // Cache in vault
      await _productVault.saveSellerProducts(sellerId, products);

      return products;
    } catch (e) {
      debugPrint('[ProductService.getSellerProducts] Error: $e');
      throw Exception('Failed to load products: $e');
    }
  }

  Future<Product> getProductById(String productId) async {
    try {
      // Check vault first
      await _init();
      final cachedProduct = _productVault.getProduct(productId);
      if (cachedProduct != null) return cachedProduct;

      // Fallback to Supabase
      final response = await _supabase
          .from('products')
          .select()
          .eq('id', productId)
          .single();

      final product = Product.fromJson(response);

      // Cache in vault
      await _productVault.saveProduct(productId, product);

      return product;
    } catch (e) {
      debugPrint('[ProductService.getProductById] Error: $e');
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

      return (response as List)
          .map((json) => ProductDeal.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('[ProductService.getProductDeals] Error: $e');
      throw Exception('Failed to load product deals: $e');
    }
  }

  Future<List<ProductSecret>> getProductSecrets(String productId) async {
    try {
      await _init();
      return await _secretsStorage.getAllProductSecrets(productId);
    } catch (e) {
      debugPrint('[ProductService.getProductSecrets] Error: $e');
      throw Exception('Failed to load product secrets: $e');
    }
  }

  Future<void> saveProductSecret({
    required String productId,
    required String secretKey,
    required String secretValue,
  }) async {
    try {
      await _init();
      await _secretsStorage.saveProductSecret(
        productId: productId,
        secretKey: secretKey,
        secretValue: secretValue,
      );
    } catch (e) {
      debugPrint('[ProductService.saveProductSecret] Error: $e');
      throw Exception('Failed to save product secret: $e');
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await _supabase.from('products').delete().eq('id', productId);

      // Remove from vault
      await _init();
      await _productVault.deleteProduct(productId);
      await _secretsStorage.deleteAllProductSecrets(productId);

      return true;
    } catch (e) {
      debugPrint('[ProductService.deleteProduct] Error: $e');
      return false;
    }
  }

  Future<void> refreshVault(String sellerId) async {
    try {
      await _init();
      await _productVault.deleteSellerProducts(sellerId);
      await getSellerProducts(sellerId);
    } catch (e) {
      debugPrint('[ProductService.refreshVault] Error: $e');
    }
  }
}
