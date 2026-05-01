import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/models/seller_profile.dart';
import 'package:aurora/models/factory_profile.dart';
import 'package:aurora/storage/storage.dart';

class ApiService extends ChangeNotifier {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  bool _isLoading = false;
  String? _error;
  SellerProfile? _sellerProfile;
  FactoryProfile? _factoryProfile;

  bool get isLoading => _isLoading;
  String? get error => _error;
  SellerProfile? get sellerProfile => _sellerProfile;
  FactoryProfile? get factoryProfile => _factoryProfile;
  bool get hasSeller => _sellerProfile != null;
  bool get hasFactory => _factoryProfile != null;

  Future<void> fetchSellerProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _error = 'Not authenticated';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await Supabase.instance.client
          .from('sellers')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        _sellerProfile = SellerProfile.fromMap(response);
        await Storage.saveSellerData(jsonEncode(response));
      } else {
        _sellerProfile = null;
      }
    } catch (e) {
      debugPrint('[ApiService.fetchSellerProfile] Error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFactoryProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _error = 'Not authenticated';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await Supabase.instance.client
          .from('factories')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        _factoryProfile = FactoryProfile.fromMap(response);
        await Storage.saveFactoryData(jsonEncode(response));
      } else {
        _factoryProfile = null;
      }
    } catch (e) {
      debugPrint('[ApiService.fetchFactoryProfile] Error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBothProfiles() async {
    await Future.wait([
      fetchSellerProfile(),
      fetchFactoryProfile(),
    ]);
  }

  Future<SellerProfile?> getSellerById(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('sellers')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return SellerProfile.fromMap(response);
      }
      return null;
    } catch (e) {
      debugPrint('[ApiService.getSellerById] Error: $e');
      return null;
    }
  }

  Future<FactoryProfile?> getFactoryById(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('factories')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return FactoryProfile.fromMap(response);
      }
      return null;
    } catch (e) {
      debugPrint('[ApiService.getFactoryById] Error: $e');
      return null;
    }
  }

  Future<List<SellerProfile>> getAllSellers({int limit = 50}) async {
    try {
      final response = await Supabase.instance.client
          .from('sellers')
          .select()
          .eq('is_verified', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((e) => SellerProfile.fromMap(e)).toList();
    } catch (e) {
      debugPrint('[ApiService.getAllSellers] Error: $e');
      return [];
    }
  }

  Future<List<FactoryProfile>> getAllFactories({int limit = 50}) async {
    try {
      final response = await Supabase.instance.client
          .from('factories')
          .select()
          .eq('is_verified', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((e) => FactoryProfile.fromMap(e)).toList();
    } catch (e) {
      debugPrint('[ApiService.getAllFactories] Error: $e');
      return [];
    }
  }

  // Authentication methods
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      final response = await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);
      
      if (response.user != null) {
        return {'user': response.user!.toJson(), 'session': response.session?.toJson()};
      }
      return {'error': 'Invalid credentials'};
    } catch (e) {
      debugPrint('[ApiService.signIn] Error: $e');
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> signUp(
    String email, 
    String password, {
    String? fullName,
    String? phone,
    String accountType = 'customer',
  }) async {
    try {
      final response = await Supabase.instance.client.auth
          .signUp(email: email, password: password);
      
      if (response.user != null) {
        // Update user metadata with additional info
        if (fullName != null || phone != null) {
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(
              data: {
                'full_name': fullName,
                'phone': phone,
                'account_type': accountType,
              },
            ),
          );
        }
        return {'user': response.user!.toJson()};
      }
      return {'error': 'Signup failed'};
    } catch (e) {
      debugPrint('[ApiService.signUp] Error: $e');
      return {'error': e.toString()};
    }
  }

  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint('[ApiService.signOut] Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('[ApiService.getUserProfile] Error: $e');
      return null;
    }
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await Supabase.instance.client
          .from('users')
          .update(data)
          .eq('id', userId);
    } catch (e) {
      debugPrint('[ApiService.updateUserProfile] Error: $e');
      rethrow;
    }
  }

  // Customer profile methods
  Future<Map<String, dynamic>> createCustomerProfile(Map<String, dynamic> data) async {
    try {
      final response = await Supabase.instance.client
          .from('customers')
          .insert(data)
          .select()
          .single();
      return {'success': true, 'customer': response};
    } catch (e) {
      debugPrint('[ApiService.createCustomerProfile] Error: $e');
      return {'error': e.toString()};
    }
  }

  Future<List<dynamic>?> getCustomerOrders(String customerId) async {
    try {
      final response = await Supabase.instance.client
          .from('orders')
          .select('''
            id,
            status,
            total_amount,
            created_at,
            seller_id,
            delivery_address,
            payment_method,
            sellers!inner(full_name)
          ''')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);
      
      // Transform response to include seller_name and items_count
      return response.map((order) {
        return {
          ...order,
          'seller_name': order['sellers']?['full_name'] ?? 'Unknown',
          'items_count': 1, // Should be calculated from order_items table
        };
      }).toList();
    } catch (e) {
      debugPrint('[ApiService.getCustomerOrders] Error: $e');
      return null;
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await Supabase.instance.client
          .from('orders')
          .update({'status': status})
          .eq('id', orderId);
    } catch (e) {
      debugPrint('[ApiService.updateOrderStatus] Error: $e');
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}