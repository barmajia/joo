import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/models/product/productModel.dart';
import 'package:aurora/models/product/product_deal.dart';
import 'package:aurora/storage/product_vault_storage.dart';
import 'package:aurora/storage/product_secrets_storage.dart';
import 'package:aurora/models/product/product_secret.dart';

class ProductService {
  ProductVaultStorage? _productVault;
  ProductSecretsStorage? _secretsStorage;

  final _supabase = Supabase.instance.client;

  Future<ProductVaultStorage> get _vault async {
    _productVault ??= await ProductVaultStorage.getInstance();
    return _productVault!;
  }

  Future<ProductSecretsStorage> get _secrets async {
    _secretsStorage ??= await ProductSecretsStorage.getInstance();
    return _secretsStorage!;
  }

  ProductService();

  Future<List<Product>> getSellerProducts(String sellerId) async {
    try {
      final vault = await _vault;
      final cached = vault.getSellerProducts(sellerId);
      if (cached.isNotEmpty) {
        debugPrint(
          '[ProductService] Loaded ${cached.length} products from cache',
        );
        return cached;
      }

      debugPrint(
        '[ProductService] Fetching products from Supabase for $sellerId',
      );
      final response = await _supabase
          .from('products')
          .select()
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);

      final products = response.map((json) => Product.fromJson(json)).toList();

      await vault.saveSellerProducts(sellerId, products);
      debugPrint('[ProductService] Cached ${products.length} products');

      return products;
    } catch (e, stack) {
      debugPrint('[ProductService.getSellerProducts] Error: $e\n$stack');
      throw Exception('Failed to load products: $e');
    }
  }

  Future<Product?> getProductById(String productId) async {
    try {
      final vault = await _vault;
      final cached = vault.getProduct(productId);
      if (cached != null) return cached;

      final response = await _supabase
          .from('products')
          .select()
          .eq('id', productId)
          .maybeSingle();

      if (response == null) return null;

      final product = Product.fromJson(response);
      await vault.saveProduct(productId, product);
      return product;
    } catch (e) {
      debugPrint('[ProductService.getProductById] Error: $e');
      return null;
    }
  }

  Future<Product?> createProduct(Map<String, dynamic> productData) async {
    try {
      final response = await _supabase
          .from('products')
          .insert(productData)
          .select()
          .single();

      final product = Product.fromJson(response);

      final vault = await _vault;
      await vault.saveProduct(product.id!, product);

      final sellerProducts = vault.getSellerProducts(product.sellerId);
      sellerProducts.add(product);
      await vault.saveSellerProducts(product.sellerId, sellerProducts);

      return product;
    } catch (e) {
      debugPrint('[ProductService.createProduct] Error: $e');
      rethrow;
    }
  }

  Future<Product?> updateProduct(
    String productId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _supabase
          .from('products')
          .update(updates)
          .eq('id', productId)
          .select()
          .single();

      final product = Product.fromJson(response);

      final vault = await _vault;
      await vault.saveProduct(productId, product);
      final sellerProducts = vault.getSellerProducts(product.sellerId);
      final index = sellerProducts.indexWhere((p) => p.id == productId);
      if (index != -1) {
        sellerProducts[index] = product;
        await vault.saveSellerProducts(product.sellerId, sellerProducts);
      }

      return product;
    } catch (e) {
      debugPrint('[ProductService.updateProduct] Error: $e');
      rethrow;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    if (productId.isEmpty) return false;

    try {
      await _supabase.from('products').delete().eq('id', productId);

      final vault = await _vault;
      await vault.deleteProduct(productId);

      return true;
    } catch (e) {
      debugPrint('[ProductService.deleteProduct] Error: $e');
      return false;
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

      return response.map((json) => ProductDeal.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[ProductService.getProductDeals] Error: $e');
      return [];
    }
  }

  Future<ProductDeal?> createDeal(Map<String, dynamic> dealData) async {
    try {
      final response = await _supabase
          .from('product_deals')
          .insert(dealData)
          .select()
          .single();

      return ProductDeal.fromJson(response);
    } catch (e) {
      debugPrint('[ProductService.createDeal] Error: $e');
      return null;
    }
  }

  Future<bool> updateDeal(String dealId, Map<String, dynamic> updates) async {
    try {
      await _supabase.from('product_deals').update(updates).eq('id', dealId);
      return true;
    } catch (e) {
      debugPrint('[ProductService.updateDeal] Error: $e');
      return false;
    }
  }

  Future<bool> deleteDeal(String dealId) async {
    try {
      await _supabase.from('product_deals').delete().eq('id', dealId);
      return true;
    } catch (e) {
      debugPrint('[ProductService.deleteDeal] Error: $e');
      return false;
    }
  }

  Future<List<ProductSecret>> getProductSecrets(String productId) async {
    try {
      final secrets = await _secrets;
      return await secrets.getAllProductSecrets(productId);
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
      final secrets = await _secrets;
      await secrets.saveProductSecret(
        productId: productId,
        secretKey: secretKey,
        secretValue: secretValue,
      );
    } catch (e) {
      debugPrint('[ProductService.saveProductSecret] Error: $e');
      throw Exception('Failed to save product secret: $e');
    }
  }

  Future<void> refreshVault(String sellerId) async {
    try {
      final vault = await _vault;
      await vault.deleteSellerProducts(sellerId);
      await getSellerProducts(sellerId);
    } catch (e) {
      debugPrint('[ProductService.refreshVault] Error: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      final vault = await _vault;
      await vault.clearAllCachedProducts();
      _productVault = null;
    } catch (e) {
      debugPrint('[ProductService.clearCache] Error: $e');
    }
  }

  Future<void> deductQuantity(
    String productId,
    int quantityDeducted,
    String sellerId,
  ) async {
    try {
      final vault = await _vault;
      Product? product = vault.getProduct(productId);

      if (product == null) {
        final sellerProducts = vault.getSellerProducts(sellerId);
        product = sellerProducts.firstWhere((p) => p.id == productId);
      }

      final newQuantity = product.quantity - quantityDeducted;

      if (newQuantity < 0) {
        throw Exception(
          'Insufficient stock for "${product.title}". Available: ${product.quantity}',
        );
      }

      final updated = product.copyWith(quantity: newQuantity);

      // Always update vault cache first
      final sellerProducts = vault.getSellerProducts(sellerId);
      final index = sellerProducts.indexWhere((p) => p.id == productId);
      if (index != -1) {
        sellerProducts[index] = updated;
        await vault.saveSellerProducts(sellerId, sellerProducts);
      }

      await vault.saveProduct(productId, updated);

      // Try Supabase, but don't fail if it rejects
      try {
        if (newQuantity == 0) {
          debugPrint(
            '[ProductService.deductQuantity] Product ${product.title} out of stock, deleting',
          );
          await _supabase.from('products').delete().eq('id', productId);
          await vault.deleteProduct(productId);

          final updatedList = vault
              .getSellerProducts(sellerId)
              .where((p) => p.id != productId)
              .toList();
          await vault.saveSellerProducts(sellerId, updatedList);
        } else {
          await _supabase
              .from('products')
              .update({'quantity': newQuantity})
              .eq('id', productId);
        }
      } catch (supabaseError) {
        debugPrint(
          '[ProductService.deductQuantity] Supabase RLS error, vault updated: $supabaseError',
        );
      }
    } catch (e) {
      debugPrint('[ProductService.deductQuantity] Error: $e');
      rethrow;
    }
  }

  Future<void> restoreQuantity(
    String productId,
    int quantityToRestore,
    String sellerId,
  ) async {
    try {
      final vault = await _vault;
      Product? product = vault.getProduct(productId);

      if (product == null) {
        final sellerProducts = vault.getSellerProducts(sellerId);
        product = sellerProducts.firstWhere((p) => p.id == productId);
      }

      final newQuantity = product.quantity + quantityToRestore;
      final updated = product.copyWith(quantity: newQuantity);

      // Update vault cache first
      final sellerProducts = vault.getSellerProducts(sellerId);
      final index = sellerProducts.indexWhere((p) => p.id == productId);
      if (index != -1) {
        sellerProducts[index] = updated;
        await vault.saveSellerProducts(sellerId, sellerProducts);
      } else {
        sellerProducts.add(updated);
        await vault.saveSellerProducts(sellerId, sellerProducts);
      }

      await vault.saveProduct(productId, updated);

      // Try Supabase
      try {
        await _supabase
            .from('products')
            .update({'quantity': newQuantity})
            .eq('id', productId);
      } catch (supabaseError) {
        debugPrint(
          '[ProductService.restoreQuantity] Supabase error, vault updated: $supabaseError',
        );
      }
    } catch (e) {
      debugPrint('[ProductService.restoreQuantity] Error: $e');
      rethrow;
    }
  }

  Map<String, dynamic> getCacheStatus() {
    return {
      'vaultInitialized': _productVault != null,
      'secretsInitialized': _secretsStorage != null,
    };
  }
}
