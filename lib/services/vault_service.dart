import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VaultStorage {
  static VaultStorage? _instance;
  SharedPreferences? _prefs;
  static const String _encryptionKey = 'aurora_vault_key_2024';

  VaultStorage._();

  static Future<VaultStorage> getInstance() async {
    _instance ??= VaultStorage._();
    await _instance!._init();
    return _instance!;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Simple XOR encryption for basic obfuscation
  // In production, use flutter_secure_storage or similar
  String _encrypt(String value) {
    final bytes = utf8.encode(value);
    final keyBytes = utf8.encode(_encryptionKey);
    final encrypted = Uint8List(bytes.length);

    for (int i = 0; i < bytes.length; i++) {
      encrypted[i] = bytes[i] ^ keyBytes[i % keyBytes.length];
    }

    return base64Encode(encrypted);
  }

  String _decrypt(String encryptedValue) {
    final encryptedBytes = base64Decode(encryptedValue);
    final keyBytes = utf8.encode(_encryptionKey);
    final decrypted = Uint8List(encryptedBytes.length);

    for (int i = 0; i < encryptedBytes.length; i++) {
      decrypted[i] = encryptedBytes[i] ^ keyBytes[i % keyBytes.length];
    }

    return utf8.decode(decrypted);
  }

  Future<void> saveString(String key, String value) async {
    try {
      final encrypted = _encrypt(value);
      await _prefs?.setString(key, encrypted);
    } catch (e) {
      debugPrint('[VaultStorage.saveString] Error: $e');
    }
  }

  String? getString(String key) {
    try {
      final encrypted = _prefs?.getString(key);
      if (encrypted == null) return null;
      return _decrypt(encrypted);
    } catch (e) {
      debugPrint('[VaultStorage.getString] Error: $e');
      return null;
    }
  }

  Future<void> saveMap(String key, Map<String, dynamic> value) async {
    try {
      final jsonString = jsonEncode(value);
      await saveString(key, jsonString);
    } catch (e) {
      debugPrint('[VaultStorage.saveMap] Error: $e');
    }
  }

  Map<String, dynamic>? getMap(String key) {
    try {
      final jsonString = getString(key);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[VaultStorage.getMap] Error: $e');
      return null;
    }
  }

  Future<void> saveList(String key, List<dynamic> value) async {
    try {
      final jsonString = jsonEncode(value);
      await saveString(key, jsonString);
    } catch (e) {
      debugPrint('[VaultStorage.saveList] Error: $e');
    }
  }

  List<dynamic>? getList(String key) {
    try {
      final jsonString = getString(key);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as List<dynamic>;
    } catch (e) {
      debugPrint('[VaultStorage.getList] Error: $e');
      return null;
    }
  }

  Future<void> remove(String key) async {
    try {
      await _prefs?.remove(key);
    } catch (e) {
      debugPrint('[VaultStorage.remove] Error: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      await _prefs?.clear();
    } catch (e) {
      debugPrint('[VaultStorage.clearAll] Error: $e');
    }
  }

  Future<List<String>> getAllKeys() async {
    return _prefs?.getKeys().toList() ?? [];
  }

  Future<bool> containsKey(String key) async {
    return _prefs?.containsKey(key) ?? false;
  }
}
