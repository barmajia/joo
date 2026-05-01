import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static BiometricService? _instance;
  static const String _biometricEnabledKey = 'biometric_enabled';

  final LocalAuthentication _auth = LocalAuthentication();

  factory BiometricService() => _instance ??= BiometricService._internal();
  BiometricService._internal();

  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _auth.isDeviceSupported();
      if (!isAvailable) return false;

      final canCheck = await _auth.canCheckBiometrics;
      return canCheck;
    } catch (e) {
      debugPrint('[BiometricService.isBiometricAvailable] Error: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('[BiometricService.getAvailableBiometrics] Error: $e');
      return [];
    }
  }

  Future<bool> authenticate({String? reason}) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      final result = await _auth.authenticate(
        localizedReason: reason ?? 'Authenticate to access the app',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      return result;
    } catch (e) {
      debugPrint('[BiometricService.authenticate] Error: $e');
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      debugPrint('[BiometricService.isBiometricEnabled] Error: $e');
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, enabled);
      debugPrint(
        '[BiometricService] Biometric ${enabled ? 'enabled' : 'disabled'}',
      );
    } catch (e) {
      debugPrint('[BiometricService.setBiometricEnabled] Error: $e');
      rethrow;
    }
  }

  Future<bool> checkAndAuthenticate({String? reason}) async {
    final isEnabled = await isBiometricEnabled();
    if (!isEnabled) return true;

    return await authenticate(reason: reason);
  }

  String getBiometricTypeString(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (types.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (types.contains(BiometricType.iris)) {
      return 'Iris';
    } else {
      return 'Biometric';
    }
  }
}
