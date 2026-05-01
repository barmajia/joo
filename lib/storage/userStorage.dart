import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/users/users.dart';
import 'package:aurora/users/account_type.dart';
import 'package:aurora/storage/storage.dart';
import 'package:aurora/services/vault_service.dart';

class UserStorage extends ChangeNotifier {
  static const String _vaultUserIdKey = 'auth_user_id';
  static const String _vaultAccountTypeKey = 'auth_account_type';
  static const String _vaultCurrentProfileKey = 'auth_current_profile';

  Users? _currentUser;
  AccountType? _accountType;
  bool _isLoading = false;
  String? _error;

  Users? get currentUser => _currentUser;
  AccountType? get accountType => _accountType;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null && _currentUser!.id.isNotEmpty;
  bool get isSeller => _accountType == AccountType.seller;
  bool get isFactory => _accountType == AccountType.factory;

  static String _profileKey(AccountType type, String userId) {
    return 'auth_profile_${type.name}_$userId';
  }

  Future<void> setAccountType(AccountType type) async {
    _accountType = type;
    notifyListeners();
  }

  Future<void> loadUser(AccountType accountType) async {
    _isLoading = true;
    _accountType = accountType;
    _error = null;
    notifyListeners();

    try {
      final supabase = Supabase.instance.client;
      final authUser = supabase.auth.currentUser;

      if (authUser == null) {
        _currentUser = Users.zero();
        throw Exception('Not authenticated');
      }

      final tableName = accountType == AccountType.factory
          ? 'factories'
          : 'sellers';
      final response = await supabase
          .from(tableName)
          .select()
          .eq('user_id', authUser.id)
          .maybeSingle();

      if (response == null) {
        throw Exception(
          'No ${accountType.name} profile found for this account UUID.',
        );
      }

      final profileUserId = response['user_id']?.toString() ?? '';
      if (profileUserId.isEmpty || profileUserId != authUser.id) {
        throw Exception('Profile UUID does not match the signed-in account.');
      }

      final profileAccountType = response['account_type']
          ?.toString()
          .trim()
          .toLowerCase();
      if (profileAccountType != null &&
          profileAccountType.isNotEmpty &&
          profileAccountType != accountType.name) {
        throw Exception(
          'This account is registered as "$profileAccountType", not "${accountType.name}".',
        );
      }

      _currentUser = _mapToUser(response, accountType);
      await _saveAuthenticatedProfile(
        authUser.id,
        accountType,
        response,
        _currentUser!,
      );
    } catch (e) {
      _error = e.toString();
      _currentUser = Users.zero();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> hasValidVaultSession() async {
    try {
      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser == null) return false;

      final vault = await VaultStorage.getInstance();
      final vaultUserId = vault.getString(_vaultUserIdKey);
      final accountTypeName = vault.getString(_vaultAccountTypeKey);
      if (vaultUserId != authUser.id ||
          accountTypeName == null ||
          accountTypeName.isEmpty) {
        return false;
      }

      final accountType = _parseAccountType(accountTypeName);
      if (accountType == null) return false;

      final profile = vault.getMap(_profileKey(accountType, authUser.id));
      if (profile == null) return false;

      final profileUserId = profile['user_id']?.toString();
      final profileType = profile['account_type']?.toString();
      return profileUserId == authUser.id &&
          (profileType == null ||
              profileType.isEmpty ||
              profileType == accountType.name);
    } catch (e) {
      debugPrint('[UserStorage.hasValidVaultSession] Error: $e');
      return false;
    }
  }

  Future<AccountType?> getStoredAccountTypeForCurrentUser() async {
    try {
      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser == null) return null;

      final vault = await VaultStorage.getInstance();
      final vaultUserId = vault.getString(_vaultUserIdKey);
      final vaultAccountType = _parseAccountType(
        vault.getString(_vaultAccountTypeKey),
      );
      if (vaultUserId == authUser.id && vaultAccountType != null) {
        return vaultAccountType;
      }

      final storedUserId = await Storage.getUserId();
      final storedAccountType = _parseAccountType(
        await Storage.getAccountType(),
      );
      if (storedUserId == authUser.id && storedAccountType != null) {
        return storedAccountType;
      }
    } catch (e) {
      debugPrint('[UserStorage.getStoredAccountTypeForCurrentUser] Error: $e');
    }
    return null;
  }

  Future<AccountType?> fetchAccountTypeForCurrentUser() async {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) return null;

    final supabase = Supabase.instance.client;

    final seller = await supabase
        .from('sellers')
        .select('user_id, account_type')
        .eq('user_id', authUser.id)
        .maybeSingle();
    if (seller != null) return AccountType.seller;

    final factory = await supabase
        .from('factories')
        .select('user_id, account_type')
        .eq('user_id', authUser.id)
        .maybeSingle();
    if (factory != null) return AccountType.factory;

    return null;
  }

  Future<void> restoreFromVault() async {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) throw Exception('Not authenticated');

    final vault = await VaultStorage.getInstance();
    final accountTypeName = vault.getString(_vaultAccountTypeKey);
    final accountType = _parseAccountType(accountTypeName);
    if (accountType == null) {
      throw Exception('Missing account type in vault storage.');
    }

    final profile = vault.getMap(_profileKey(accountType, authUser.id));
    if (profile == null) {
      throw Exception('Missing profile data in vault storage.');
    }

    _accountType = accountType;
    _currentUser = _mapToUser(profile, accountType);
    notifyListeners();
  }

  Future<void> clearAuthenticatedVault() async {
    final authUser = Supabase.instance.client.auth.currentUser;
    final vault = await VaultStorage.getInstance();
    final accountTypeName = vault.getString(_vaultAccountTypeKey);
    final accountType = _parseAccountType(accountTypeName);

    await vault.remove(_vaultUserIdKey);
    await vault.remove(_vaultAccountTypeKey);
    await vault.remove(_vaultCurrentProfileKey);
    if (authUser != null && accountType != null) {
      await vault.remove(_profileKey(accountType, authUser.id));
    }
    await Storage.clearUserData();
    await Storage.clearUser();
  }

  Future<void> saveSeller(
    Users user, {
    String? firstname,
    String? secondName,
    String? thirdName,
    String? fourthName,
    String? location,
    String? phone,
    double? latitude,
    double? longitude,
    String? productCategoryId,
    String? productCategoryName,
    bool? isFactory,
    String? factoryLicenseUrl,
    int? minOrderQuantity,
    double? wholesaleDiscount,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final supabase = Supabase.instance.client;
      final authUser = supabase.auth.currentUser;

      if (authUser == null) {
        throw Exception('Not authenticated');
      }

      final data = {
        'user_id': authUser.id,
        'email': user.email,
        'full_name': user.name,
        'firstname': firstname,
        'second_name': secondName,
        'thirdname': thirdName,
        'fourth_name': fourthName,
        'phone': phone ?? user.phonenumber.toString(),
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'product_category_id': productCategoryId,
        'product_category_name': productCategoryName,
        'specialization': productCategoryName,
        'is_factory': isFactory ?? false,
        'factory_license_url': factoryLicenseUrl,
        'min_order_quantity': minOrderQuantity ?? 1,
        'wholesale_discount': wholesaleDiscount ?? 0,
        'account_type': 'seller',
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase.from('sellers').upsert(data);

      _currentUser = user;
      _accountType = AccountType.seller;
      await _saveAuthenticatedProfile(
        authUser.id,
        AccountType.seller,
        data,
        user,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveFactory(
    Users user, {
    String? companyName,
    String? phone,
    String? location,
    String? locationText,
    double? latitude,
    double? longitude,
    int? productionCapacity,
    String? productCategoryId,
    String? productCategoryName,
    String? specialization,
    String? websiteUrl,
    String? businessLicenseUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final supabase = Supabase.instance.client;
      final authUser = supabase.auth.currentUser;

      if (authUser == null) {
        throw Exception('Not authenticated');
      }

      final data = {
        'user_id': authUser.id,
        'email': user.email,
        'full_name': user.name,
        'company_name': companyName,
        'phone': phone ?? user.phonenumber.toString(),
        'location': location,
        'location_text': locationText,
        'latitude': latitude,
        'longitude': longitude,
        'production_capacity': productionCapacity,
        'product_category_id': productCategoryId,
        'product_category_name': productCategoryName,
        'specialization': specialization ?? productCategoryName,
        'website_url': websiteUrl,
        'business_license_url': businessLicenseUrl,
        'account_type': 'factory',
        'is_factory': true,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase.from('factories').upsert(data);

      _currentUser = user;
      _accountType = AccountType.factory;
      await _saveAuthenticatedProfile(
        authUser.id,
        AccountType.factory,
        data,
        user,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Users?> getSellerById(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('sellers')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return _mapToUser(response, AccountType.seller);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Users?> getFactoryById(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('factories')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return _mapToUser(response, AccountType.factory);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Users>> getAllSellers({int limit = 50}) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('sellers')
          .select()
          .eq('is_verified', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((e) => _mapToUser(e, AccountType.seller)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Users>> getAllFactories({int limit = 50}) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('factories')
          .select()
          .eq('is_verified', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((e) => _mapToUser(e, AccountType.factory)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> logout() async {
    _currentUser = Users.zero();
    _accountType = null;
    await clearAuthenticatedVault();
    await Storage.clearUser();
    notifyListeners();
  }

  Future<void> _saveAuthenticatedProfile(
    String authUserId,
    AccountType accountType,
    Map<String, dynamic> profileData,
    Users user,
  ) async {
    final normalizedProfile = Map<String, dynamic>.from(profileData);
    normalizedProfile['user_id'] = authUserId;
    normalizedProfile['account_type'] = accountType.name;

    final vault = await VaultStorage.getInstance();
    await vault.saveString(_vaultUserIdKey, authUserId);
    await vault.saveString(_vaultAccountTypeKey, accountType.name);
    await vault.saveMap(_vaultCurrentProfileKey, normalizedProfile);
    await vault.saveMap(
      _profileKey(accountType, authUserId),
      normalizedProfile,
    );

    await Storage.saveUserId(authUserId);
    await Storage.saveAccountType(accountType.name);
    await Storage.saveUser(user.toJson());
    if (accountType == AccountType.factory) {
      await Storage.saveFactoryData(jsonEncode(normalizedProfile));
    } else {
      await Storage.saveSellerData(jsonEncode(normalizedProfile));
    }
  }

  AccountType? _parseAccountType(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final type in AccountType.values) {
      if (type.name == value) return type;
    }
    return null;
  }

  Users _mapToUser(Map<String, dynamic> data, AccountType accountType) {
    return Users(
      id: data['user_id']?.toString() ?? '',
      email: data['email'] ?? '',
      name: data['full_name'] ?? data['name'] ?? '',
      password: '',
      accountType: accountType,
      phonenumber: int.tryParse(data['phone']?.toString() ?? '0') ?? 0,
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'])
          : DateTime.now(),
      lastLoginAt: data['updated_at'] != null
          ? DateTime.tryParse(data['updated_at'])
          : null,
      isactive: data['is_verified'] ?? true,
      metadata: data,
    );
  }
}
