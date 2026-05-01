// lib/services/app_logger.dart
import 'package:flutter/foundation.dart';

class AppLogger {
  static const String _tag = 'Aurora';

  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      print('[${tag ?? _tag}] (DEBUG): $message');
    }
  }

  static void info(String message, [String? tag]) {
    print('[${tag ?? _tag}] (INFO): $message');
  }

  static void warning(String message, [String? tag]) {
    print('[${tag ?? _tag}] (WARNING): $message');
  }

  static void error(String message, [String? tag, Object? exception, StackTrace? stackTrace]) {
    print('[${tag ?? _tag}] (ERROR): $message');
    if (exception != null) {
      print('Exception: $exception');
    }
    if (stackTrace != null) {
      print('StackTrace: $stackTrace');
    }
  }

  static void success(String message, [String? tag]) {
    print('[${tag ?? _tag}] (SUCCESS): $message');
  }
}
