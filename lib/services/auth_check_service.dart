import 'package:aurora/storage/storage.dart';
import 'package:aurora/users/account_type.dart';
import 'package:aurora/services/app_logger.dart';

class AuthCheckResult {
  final bool isValid;
  final String? uuid;
  final AccountType? accountType;
  final String? errorMessage;

  AuthCheckResult({
    required this.isValid,
    this.uuid,
    this.accountType,
    this.errorMessage,
  });

  factory AuthCheckResult.valid({required String uuid, required AccountType accountType}) {
    return AuthCheckResult(
      isValid: true,
      uuid: uuid,
      accountType: accountType,
    );
  }

  factory AuthCheckResult.invalid({String? errorMessage}) {
    return AuthCheckResult(
      isValid: false,
      errorMessage: errorMessage ?? 'Invalid credentials',
    );
  }
}

class AuthCheckService {
  static const String _keyUuid = 'auth_uuid';
  static const String _keyAccountType = 'auth_account_type';

  Future<AuthCheckResult> checkAuth() async {
    try {
      AppLogger.info('Checking authentication status', context: 'AuthCheck');

      final storedUuid = await Storage.getString(_keyUuid);
      final storedAccountType = await Storage.getString(_keyAccountType);

      AppLogger.debug('Stored UUID: ${storedUuid != null ? "exists" : "null"}', context: 'AuthCheck');
      AppLogger.debug('Stored AccountType: $storedAccountType', context: 'AuthCheck');

      if (storedUuid == null || storedUuid.isEmpty) {
        AppLogger.info('No stored UUID found', context: 'AuthCheck');
        return AuthCheckResult.invalid(errorMessage: 'No stored credentials');
      }

      if (storedAccountType == null || storedAccountType.isEmpty) {
        AppLogger.info('No stored account type found', context: 'AuthCheck');
        return AuthCheckResult.invalid(errorMessage: 'No account type');
      }

      final accountType = _parseAccountType(storedAccountType);
      if (accountType == null) {
        AppLogger.warning('Invalid account type: $storedAccountType', context: 'AuthCheck');
        return AuthCheckResult.invalid(errorMessage: 'Invalid account type');
      }

      AppLogger.info('Auth check passed for UUID: ${storedUuid.substring(0, 8)}...', context: 'AuthCheck');
      return AuthCheckResult.valid(uuid: storedUuid, accountType: accountType);

    } catch (e, stack) {
      AppLogger.error('Auth check failed: $e', context: 'AuthCheck', error: e, stackTrace: stack);
      return AuthCheckResult.invalid(errorMessage: e.toString());
    }
  }

  Future<void> saveAuth({
    required String uuid,
    required AccountType accountType,
  }) async {
    try {
      AppLogger.info('Saving authentication data', context: 'AuthCheck');
      
      await Storage.saveString(_keyUuid, uuid);
      await Storage.saveString(_keyAccountType, accountType.name);
      
      AppLogger.info('Authentication data saved successfully', context: 'AuthCheck');
    } catch (e, stack) {
      AppLogger.error('Failed to save auth data: $e', context: 'AuthCheck', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> clearAuth() async {
    try {
      AppLogger.info('Clearing authentication data', context: 'AuthCheck');
      
      await Storage.removeData(_keyUuid);
      await Storage.removeData(_keyAccountType);
      
      AppLogger.info('Authentication data cleared', context: 'AuthCheck');
    } catch (e, stack) {
      AppLogger.error('Failed to clear auth data: $e', context: 'AuthCheck', error: e, stackTrace: stack);
      rethrow;
    }
  }

  AccountType? _parseAccountType(String type) {
    switch (type.toLowerCase()) {
      case 'seller':
        return AccountType.seller;
      case 'factory':
        return AccountType.factory;
      case 'customer':
      case 'customser':
        return AccountType.customser;
      case 'middleman':
        return AccountType.middleman;
      default:
        return null;
    }
  }
}