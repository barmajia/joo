import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/services/vault_service.dart';
import 'package:aurora/models/product/product_secret.dart';

class ProductSecretsStorage {
  final SupabaseClient _client = Supabase.instance.client;
  late final VaultStorage _vault;

  static ProductSecretsStorage? _instance;
  static bool _initialized = false;

  ProductSecretsStorage._();

  static Future<ProductSecretsStorage> getInstance() async {
    if (_instance == null || !_initialized) {
      _instance = ProductSecretsStorage._();
      _instance!._vault = await VaultStorage.getInstance();
      _initialized = true;
    }
    return _instance!;
  }

  Future<void> saveProductSecret({
    required String productId,
    required String secretKey,
    required String secretValue,
  }) async {
    try {
      final encryptedValue = _encryptSecretValue(secretValue);

      await _client.from('product_secrets').insert({
        'product_id': productId,
        'secret_key': secretKey,
        'encrypted_value': encryptedValue,
        'is_encrypted': true,
      });

      await _vault.saveString(
        'product_secret_local_$productId',
        jsonEncode({
          secretKey: encryptedValue,
        }),
      );
    } catch (e) {
      debugPrint('[ProductSecretsStorage.saveProductSecret] Error: $e');
      rethrow;
    }
  }

  Future<ProductSecret?> getProductSecret({
    required String productId,
    required String secretKey,
  }) async {
    try {
      final response = await _client
          .from('product_secrets')
          .select()
          .eq('product_id', productId)
          .eq('secret_key', secretKey)
          .maybeSingle();

      if (response == null) return null;

      return ProductSecret.fromJson(response);
    } catch (e) {
      debugPrint('[ProductSecretsStorage.getProductSecret] Error: $e');
      return null;
    }
  }

  Future<List<ProductSecret>> getAllProductSecrets(String productId) async {
    try {
      final response = await _client
          .from('product_secrets')
          .select()
          .eq('product_id', productId);

      return response
          .map((e) => ProductSecret.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[ProductSecretsStorage.getAllProductSecrets] Error: $e');
      return [];
    }
  }

  Future<void> deleteProductSecret({
    required String productId,
    required String secretKey,
  }) async {
    try {
      await _client
          .from('product_secrets')
          .delete()
          .eq('product_id', productId)
          .eq('secret_key', secretKey);

      final localData = _vault.getString('product_secret_local_$productId');
      if (localData != null) {
        final decoded = jsonDecode(localData) as Map<String, dynamic>;
        decoded.remove(secretKey);
        await _vault.saveString(
          'product_secret_local_$productId',
          jsonEncode(decoded),
        );
      }
    } catch (e) {
      debugPrint('[ProductSecretsStorage.deleteProductSecret] Error: $e');
      rethrow;
    }
  }

  Future<void> deleteAllProductSecrets(String productId) async {
    try {
      await _client
          .from('product_secrets')
          .delete()
          .eq('product_id', productId);

      await _vault.remove('product_secret_local_$productId');
    } catch (e) {
      debugPrint('[ProductSecretsStorage.deleteAllProductSecrets] Error: $e');
      rethrow;
    }
  }

  String _encryptSecretValue(String value) {
    final bytes = utf8.encode(value);
    final keyBytes = utf8.encode('aurora_secret_encryption_2024');
    final encrypted = List<int>.generate(bytes.length, (i) {
      return bytes[i] ^ keyBytes[i % keyBytes.length];
    });
    return base64Encode(encrypted);
  }

  String decryptSecretValue(String encryptedValue) {
    final encryptedBytes = base64Decode(encryptedValue);
    final keyBytes = utf8.encode('aurora_secret_encryption_2024');
    final decrypted = List<int>.generate(encryptedBytes.length, (i) {
      return encryptedBytes[i] ^ keyBytes[i % keyBytes.length];
    });
    return utf8.decode(decrypted);
  }

  Future<Map<String, String>> getCachedSecrets(String productId) async {
    try {
      final localData = _vault.getString('product_secret_local_$productId');
      if (localData == null) return {};

      final decoded = jsonDecode(localData) as Map<String, dynamic>;
      final secrets = <String, String>{};

      decoded.forEach((key, value) {
        secrets[key] = decryptSecretValue(value.toString());
      });

      return secrets;
    } catch (e) {
      debugPrint('[ProductSecretsStorage.getCachedSecrets] Error: $e');
      return {};
    }
  }
}
