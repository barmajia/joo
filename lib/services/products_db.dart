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

      return response.map((e) => Product.fromJson(e)).toList();
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

      return response.map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[ProductsDB.getLowStockProducts] Error: $e');
      return [];
    }
  }

  /** this will be the way that i  could fine the place of what will be there and i could find the place that i could find the way that i could find the way that i could find it 
 * 
 * from the way tha i will find the way tha  i could find the real way that i could find the awy tha ti could make there then i will have the way hta ti could make there and i will have the way that i will get deal with the aw
 * 
 * from the way that make you you will find the way that i could make this and you will get deal with the way that i will help you then you coudl
 * 
 * from this way then i could find the real way there and i will be able to find the place that i could make there and you will find the place that i then you will have the way thatyou will find from this somethings like what will be thee and you will make this for the way taht help you in e
 * then i could find the place of what will be then you will find this as well then you could make this as you wil lfind 
 * 
 * from the way that help you then you will find the poweer of you while you could find the way that help you in the place that will get you in the place that help you in and you will have the power that heelp you in the place here then you could 
 * then you will have the way that help you in the place that you could find the place that help you in the place that you couldd find these things like who you are and the place of what will be there and you could make these like who you are and the place of what will be then you could find these things like everthing you could make here as well then you will have the way that get you get you out from this way then you could find t
 * i don't know about the way but we should think of it like what we will make there then we will have the way that help you and you could find the place that get you out there then you could make these things like all of these things we could make it then i need you to focust only on the end of all of this and you will have the way to break this prison and you could find the place that help you and you could find the place that help you by makiing these things 
 * from the place that you could find the real way that help you in the place that you could find the place that get you out from this way then you will have the way that you could find this thing like what you will make there and you will find these things like who you are and the place of what will be here 
 * 
 * then you could find the place that help you there and you will you will find this and you will have the way that i could find this and you will find 
 * then you will have the way that help you in and you could find the place that help you in the place that get you out from the way that you will have the way that help you in the place that you coudld find the place that get you out from the way that help you out then i could find the way taht help
 * then you will have the way that help you in the way that help you there then i could have the way that i could find the waythat help you in the best place that get you out from all of this 
 * then you could then you could find the way that help you get the place that help you in then you could find the place that make you there and you will have the way that help you in and you will have the way that make you have the way that make you have the best tthin
 * then you could find the place that help who you are then you will be then there is the way that help you in the place that get you out from the way that help you in the place of what will be ther then you could find 
 * then you will have 
 */
  Future<void> refreshVault() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _client
          .from('products')
          .select()
          .eq('seller_id', userId)
          .order('created_at', ascending: false);

      final products = response.map((e) => Product.fromJson(e)).toList();

      final vault = await _vault;
      await vault.refreshSellerProducts(userId, products);
    } catch (e) {
      debugPrint('[ProductsDB.refreshVault] Error: $e');
    }
  }
}
