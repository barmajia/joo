import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aurora/users/users.dart';

class Storage {
  static late final SharedPreferences _prefs;
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
  }

  static Future<void> _saveString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  static Future<String?> _getString(String key) async {
    try {
      return _prefs.getString(key);
    } catch (e) {
      final value = _prefs.get(key);
      if (value is int) return value.toString();
      if (value is double) return value.toString();
      if (value is bool) return value.toString();
      return null;
    }
  }

  static Future<void> saveThemeIndex(int index) async {
    await _saveString('theme_index', index.toString());
  }

  static Future<int> getThemeIndex() async {
    final value = await _getString('theme_index');
    if (value == null) return 0;
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
    try {
      return value as int;
    } catch (e) {
      return 0;
    }
  }

  static Future<void> saveLanguageCode(String code) async {
    await _saveString('language_code', code);
  }

  static Future<String> getLanguageCode() async {
    return await _getString('language_code') ?? 'en';
  }

  static Future<void> saveSellerData(String data) async {
    await _saveString('seller_data', data);
  }

  static Future<String?> getSellerData() async {
    return await _getString('seller_data');
  }

  static Future<void> saveFactoryData(String data) async {
    await _saveString('factory_data', data);
  }

  static Future<String?> getFactoryData() async {
    return await _getString('factory_data');
  }

  static Future<void> saveUserId(String userId) async {
    await _saveString('user_id', userId);
  }

  static Future<String?> getUserId() async {
    return await _getString('user_id');
  }

  static Future<void> saveAccountType(String type) async {
    await _saveString('account_type', type);
  }

  static Future<String> getAccountType() async {
    return await _getString('account_type') ?? '';
  }

  static Future<bool> getBool(String key) async {
    final value = await _getString(key);
    return value == 'true' || value == '1' || value == 'true';
  }

  static Future<void> saveBool(String key, bool value) async {
    await _saveString(key, value.toString());
  }

  static Future<double> getBrightness() async {
    final value = await _getString('brightness_level');
    if (value == null) return 1.0;
    final parsed = double.tryParse(value);
    if (parsed != null) return parsed;
    try {
      return value as double;
    } catch (e) {
      return 1.0;
    }
  }

  static Future<void> saveBrightness(double value) async {
    await _saveString('brightness_level', value.toString());
  }

  static Future<void> clearAll() async {
    await _prefs.clear();
  }

  static Future<void> clearUserData() async {
    await _prefs.remove('seller_data');
    await _prefs.remove('factory_data');
    await _prefs.remove('user_id');
    await _prefs.remove('account_type');
  }

  static Future<void> saveUser(Map<String, dynamic> userData) async {
    await _saveString('user_data', jsonEncode(userData));
  }

  static Future<Users?> getUser() async {
    final value = await _getString('user_data');
    if (value == null || value.isEmpty) return null;
    try {
      final json = jsonDecode(value) as Map<String, dynamic>;
      return Users.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearUser() async {
    await _prefs.remove('user_data');
  }
}