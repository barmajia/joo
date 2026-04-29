import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/users/users.dart';
import 'package:aurora/users/account_type.dart';
import 'package:aurora/storage/storage.dart';

class UserStorage extends ChangeNotifier {
  Users? _currentUser;
  bool _isLoading = false;
  String? _error;

  Users? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null && _currentUser!.id.isNotEmpty;

  Future<void> loadUser(AccountType accountType) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final supabase = Supabase.instance.client;
      final authUser = supabase.auth.currentUser;

      if (authUser == null) {
        _currentUser = Users.zero();
        _isLoading = false;
        notifyListeners();
        return;
      }

      final tableName = accountType == AccountType.factory ? 'factories' : 'sellers';
      final response = await supabase
          .from(tableName)
          .select()
          .eq('user_id', authUser.id)
          .maybeSingle();

      if (response != null) {
        _currentUser = _mapToUser(response, accountType);
      } else {
        final localUser = await Storage.getUser();
        _currentUser = localUser ?? Users.zero();
      }

      await Storage.saveUser(_currentUser!.toJson());
    } catch (e) {
      _error = e.toString();
      final localUser = await Storage.getUser();
      _currentUser = localUser ?? Users.zero();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveSeller(Users user, {
    String? firstname,
    String? secondName,
    String? thirdName,
    String? fourthName,
    String? location,
    String? phone,
    double? latitude,
    double? longitude,
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
        'is_factory': isFactory ?? false,
        'factory_license_url': factoryLicenseUrl,
        'min_order_quantity': minOrderQuantity ?? 1,
        'wholesale_discount': wholesaleDiscount ?? 0,
        'account_type': 'seller',
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase.from('sellers').upsert(data);

      _currentUser = user;
      await Storage.saveUser(user.toJson());
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveFactory(Users user, {
    String? companyName,
    String? phone,
    String? location,
    String? locationText,
    double? latitude,
    double? longitude,
    int? productionCapacity,
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
        'latitude': latitude != null ? latitude.toInt() : null,
        'longitude': longitude != null ? longitude.toInt() : null,
        'production_capacity': productionCapacity,
        'specialization': specialization,
        'website_url': websiteUrl,
        'business_license_url': businessLicenseUrl,
        'account_type': 'factory',
        'is_factory': true,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase.from('factories').upsert(data);

      _currentUser = user;
      await Storage.saveUser(user.toJson());
    } catch (e) {
      _error = e.toString();
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
    await Storage.clearUser();
    notifyListeners();
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