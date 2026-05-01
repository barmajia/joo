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
  bool _biometricAvailable = false;
  String _biometricStatus = '';

  bool get reduceAnimations => _reduceAnimations;
  bool get biometricLock => _biometricLock;
  bool get passwordLock => _passwordLock;
  bool get isUnlocked => _isUnlocked;
  bool get isSecurityEnabled => _biometricLock || _passwordLock;
  bool get biometricAvailable => _biometricAvailable;
  String get biometricStatus => _biometricStatus;

  Future<void> init() async {
    _reduceAnimations = await Storage.getBool('reduce_animations');
    _biometricLock = await Storage.getBool('biometric_lock');
    _passwordLock = await Storage.getBool('password_lock');
    _appPassword = await Storage.getString('app_password');
    await _checkBiometricAvailability();
    notifyListeners();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      // Check if device supports biometrics
      final isSupported = await _localAuth.isDeviceSupported();
      debugPrint('[Biometric] isDeviceSupported: $isSupported');
      
      if (!isSupported) {
        _biometricAvailable = false;
        _biometricStatus = 'Device not supported';
        return;
      }

      // Try to get available biometrics
      try {
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        debugPrint('[Biometric] Available biometrics: $availableBiometrics');
        
        if (availableBiometrics.isNotEmpty) {
          _biometricAvailable = true;
          _biometricStatus = 'Available (${availableBiometrics.length} methods)';
          return;
        }
      } catch (e) {
        debugPrint('[Biometric] getAvailableBiometrics error: $e');
      }

      // If getAvailableBiometrics failed, try canCheckBiometrics as fallback
      try {
        final canCheck = await _localAuth.canCheckBiometrics;
        debugPrint('[Biometric] canCheckBiometrics: $canCheck');
        
        if (canCheck) {
          _biometricAvailable = true;
          _biometricStatus = 'Available (finger/face)';
          return;
        }
      } catch (e) {
        debugPrint('[Biometric] canCheckBiometrics error: $e');
      }

      // If still not available, assume it's available and let auth try
      // Some devices don't report correctly but still work
      _biometricAvailable = true;
      _biometricStatus = 'Available (try enabling)';
      
    } catch (e) {
      debugPrint('[Biometric] Overall error: $e');
      // Assume available - let user try to authenticate
      _biometricAvailable = true;
      _biometricStatus = 'Available';
    }
  }

  Future<void> setReduceAnimations(bool value) async {
    await Storage.saveBool('reduce_animations', value);
    _reduceAnimations = value;
    notifyListeners();
  }

  Future<bool> setBiometricLock(bool value) async {
    if (value) {
      await _checkBiometricAvailability();
      // Even if check says unavailable, let user try - some devices report incorrectly
    }
    await Storage.saveBool('biometric_lock', value);
    _biometricLock = value;
    if (value) _isUnlocked = true;
    notifyListeners();
    return true;
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
    if (_isUnlocked) return;
    _isUnlocked = true;
    notifyListeners();
  }

  void lockApp() {
    if (!_isUnlocked) return;
    _isUnlocked = false;
    notifyListeners();
  }
}
