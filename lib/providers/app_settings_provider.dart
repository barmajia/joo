import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../storage/storage.dart';

class AppSettingsProvider extends ChangeNotifier {
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _reduceAnimations = false;
  bool _biometricLock = false;
  bool _passwordLock = false;
  String? _appPassword;
  bool _isUnlocked = false;

  bool get reduceAnimations => _reduceAnimations;
  bool get biometricLock => _biometricLock;
  bool get passwordLock => _passwordLock;
  bool get isUnlocked => _isUnlocked;
  bool get isSecurityEnabled => _biometricLock || _passwordLock;

  Future<void> init() async {
    _reduceAnimations = await Storage.getBool('reduce_animations');
    _biometricLock = await Storage.getBool('biometric_lock');
    _passwordLock = await Storage.getBool('password_lock');
    _appPassword = await Storage.getString('app_password');
    notifyListeners();
  }

  Future<void> setReduceAnimations(bool value) async {
    await Storage.saveBool('reduce_animations', value);
    _reduceAnimations = value;
    notifyListeners();
  }

  Future<void> setBiometricLock(bool value) async {
    if (value) {
      final available = await _localAuth.canCheckBiometrics;
      if (!available) return;
    }
    await Storage.saveBool('biometric_lock', value);
    _biometricLock = value;
    if (value) _isUnlocked = true;
    notifyListeners();
  }

  Future<void> setAppPassword(String password) async {
    await Storage.saveBool('password_lock', password.isNotEmpty);
    await Storage.saveString('app_password', password);
    _passwordLock = password.isNotEmpty;
    _appPassword = password;
    if (password.isNotEmpty) _isUnlocked = true;
    notifyListeners();
  }

  Future<bool> authenticateBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Aurora',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticatePassword(String password) async {
    if (_appPassword == null || _appPassword!.isEmpty) return true;
    final isValid = password == _appPassword;
    if (isValid) _isUnlocked = true;
    return isValid;
  }

  void setUnlocked() {
    _isUnlocked = true;
    notifyListeners();
  }

  void lockApp() {
    _isUnlocked = false;
    notifyListeners();
  }
}
