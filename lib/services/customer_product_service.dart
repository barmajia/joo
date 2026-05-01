import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/models/product/productModel.dart';
import 'package:aurora/services/app_logger.dart';

class CustomerProductService {
  final _supabase = Supabase.instance.client;

  Future<List<Product>> getAllProducts({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      AppLogger.info('Fetching products (limit: $limit, offset: $offset)', context: 'CustomerProducts');

      final response = await _supabase
          .from('products')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      AppLogger.info('Fetched ${response.length} products', context: 'CustomerProducts');

      return response.map((json) => Product.fromJson(json)).toList();
    } catch (e, stack) {
      AppLogger.error('Failed to fetch products: $e', context: 'CustomerProducts', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final response = await _supabase
          .from('products')
          .select('category');

      final categories = response
          .map((e) => e['category'] as String?)
          .where((c) => c != null && c.isNotEmpty)
          .toSet()
          .toList();
      
      categories.sort();
      return categories;
    } catch (e) {
      AppLogger.error('Failed to get categories: $e', context: 'CustomerProducts', error: e);
      return [];
    }
  }
}