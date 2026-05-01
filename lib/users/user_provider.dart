import 'package:flutter/material.dart';
import '../users/users.dart';
import '../storage/userStorage.dart';

class UserProvider extends ChangeNotifier {
  Users? _user;
  bool _isLoading = false;

  Users? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final storage = UserStorage();
      final userData = await storage.getUser();

      if (userData != null) {
        _user = Users.fromJson(userData);
      } else {
        _user = null;
      }
    } catch (e) {
      debugPrint('[UserProvider.loadUser] Error: $e');
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setUser(Users user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }

  Future<void> updateUser(Map<String, dynamic> data) async {
    if (_user == null) return;

    try {
      _user = _user!.copyWith(
        name: data['full_name'] ?? _user!.name,
        email: data['email'] ?? _user!.email,
        metadata: {...?_user!.metadata, ...data},
      );
      notifyListeners();
    } catch (e) {
      debugPrint('[UserProvider.updateUser] Error: $e');
      rethrow;
    }
  }
}
