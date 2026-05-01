// lib/services/biometric_service.dart
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available on the device
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get list of available biometric types on the device
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final List<BiometricType> availableBiometrics =
          await _localAuth.getAvailableBiometrics();
      return availableBiometrics;
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate user using biometrics
  Future<bool> authenticate({
    String reason = 'Please authenticate to continue',
    String? localizedReason,
  }) async {
    try {
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        print('Biometric authentication is not available');
        return false;
      }

      final List<BiometricType> availableBiometrics =
          await getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        print('No biometric types available');
        return false;
      }

      final bool authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason ?? reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      return authenticated;
    } catch (e) {
      print('Authentication error: $e');
      return false;
    }
  }

  /// Check if user has enrolled biometrics
  Future<bool> hasEnrolledBiometrics() async {
    try {
      return await _localAuth.isDeviceSupported() &&
          await _localAuth.canCheckBiometrics;
    } catch (e) {
      print('Error checking enrolled biometrics: $e');
      return false;
    }
  }

  /// Get the preferred biometric type for authentication
  Future<BiometricType?> getPreferredBiometricType() async {
    try {
      final List<BiometricType> availableBiometrics =
          await getAvailableBiometrics();

      if (availableBiometrics.isEmpty) {
        return null;
      }

      // Prefer face recognition, then fingerprint, then iris
      if (availableBiometrics.contains(BiometricType.face)) {
        return BiometricType.face;
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        return BiometricType.fingerprint;
      } else if (availableBiometrics.contains(BiometricType.iris)) {
        return BiometricType.iris;
      } else if (availableBiometrics.contains(BiometricType.strong)) {
        return BiometricType.strong;
      } else if (availableBiometrics.contains(BiometricType.weak)) {
        return BiometricType.weak;
      }

      return availableBiometrics.first;
    } catch (e) {
      print('Error getting preferred biometric type: $e');
      return null;
    }
  }

  /// Cancel any ongoing biometric authentication
  Future<void> cancelAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      print('Error cancelling authentication: $e');
    }
  }
}
