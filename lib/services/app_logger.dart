import 'package:flutter/foundation.dart';

class AppLogger {
  static const String _tag = 'Aurora';

  static void info(String message, {String? context}) {
    _log('INFO', message, context: context);
  }

  static void debug(String message, {String? context}) {
    _log('DEBUG', message, context: context);
  }

  static void warning(String message, {String? context}) {
    _log('WARNING', message, context: context);
  }

  static void error(String message, {String? context, Object? error, StackTrace? stackTrace}) {
    _log('ERROR', message, context: context, error: error, stackTrace: stackTrace);
  }

  static void _log(
    String level,
    String message, {
    String? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? ' [$context]' : '';
    
    if (kDebugMode) {
      debugPrint('[$timestamp] $level$contextStr: $message');
      
      if (error != null) {
        debugPrint('  Error: $error');
      }
      
      if (stackTrace != null) {
        debugPrint('  StackTrace: $stackTrace');
      }
    }
  }

  static void logAppStart() {
    info('Aurora App Started', context: 'App');
  }

  static void logLogin(String userId, String accountType) {
    info('User logged in: $userId, type: $accountType', context: 'Auth');
  }

  static void logLogout(String userId) {
    info('User logged out: $userId', context: 'Auth');
  }

  static void logNavigation(String from, String to) {
    debug('Navigation: $from -> $to', context: 'Navigation');
  }

  static void logApiCall(String endpoint, {String? method}) {
    debug('API Call: ${method ?? 'GET'} $endpoint', context: 'API');
  }

  static void logApiError(String endpoint, Object err) {
    error('API Error: $endpoint', context: 'API', error: err);
  }

  static void logCartAction(String action, {String? productId, int? quantity}) {
    final details = [
      if (productId != null) 'product: $productId',
      if (quantity != null) 'qty: $quantity',
    ].join(', ');
    info('Cart: $action${details.isNotEmpty ? ' ($details)' : ''}', context: 'Cart');
  }

  static void logCheckout(String userId, double total) {
    info('Checkout initiated by $userId, total: \$$total', context: 'Checkout');
  }

  static void logCustomerAction(String action, {String? customerId}) {
    info('Customer action: $action${customerId != null ? ' (customer: $customerId)' : ''}', context: 'Customer');
  }

  static void logPageView(String pageName) {
    debug('Page viewed: $pageName', context: 'Analytics');
  }
}