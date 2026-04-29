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
      return [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}