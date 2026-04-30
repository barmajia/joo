// lib/utils/connectivity_helper.dart

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Network connectivity status
enum ConnectivityStatus {
  connected, // Has internet access
  disconnected, // No network connection
  unknown, // Status couldn't be determined
}

/// Utility class for checking and monitoring internet connectivity
class ConnectivityHelper {
  static final Connectivity _connectivity = Connectivity();
  static ConnectivityStatus? _lastKnownStatus;
  static final _controller = StreamController<ConnectivityStatus>.broadcast();

  /// Private constructor - this class should not be instantiated
  ConnectivityHelper._();

  /// Stream of connectivity status changes
  ///
  /// Listen to this to react when user goes online/offline:
  /// ```dart
  /// ConnectivityHelper.onConnectivityChanged.listen((status) {
  ///   if (status == ConnectivityStatus.connected) {
  ///     // Sync pending items
  ///   }
  /// });
  /// ```
  static Stream<ConnectivityStatus> get onConnectivityChanged =>
      _controller.stream;

  /// Check current connectivity status (one-time check)
  ///
  /// Returns [ConnectivityStatus.connected] if device has internet access.
  ///
  /// Note: This checks for network interface availability, not necessarily
  /// actual internet reachability. For critical operations, consider
  /// pinging a reliable endpoint.
  static Future<ConnectivityStatus> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();

      // Check if ANY connection type is available
      final hasConnection = results.any(
        (result) => result != ConnectivityResult.none,
      );

      if (!hasConnection) {
        _lastKnownStatus = ConnectivityStatus.disconnected;
        return ConnectivityStatus.disconnected;
      }

      // Optional: Verify actual internet reachability
      // (Uncomment for stricter checking - adds ~100-500ms latency)
      /*
      final hasInternet = await _verifyInternetReachability();
      if (!hasInternet) {
        _lastKnownStatus = ConnectivityStatus.disconnected;
        return ConnectivityStatus.disconnected;
      }
      */

      _lastKnownStatus = ConnectivityStatus.connected;
      return ConnectivityStatus.connected;
    } catch (e) {
      debugPrint('[ConnectivityHelper] Error checking connectivity: $e');
      _lastKnownStatus = ConnectivityStatus.unknown;
      return ConnectivityStatus.unknown;
    }
  }

  /// Convenience getter for boolean check
  ///
  /// ```dart
  /// if (await ConnectivityHelper.hasInternet) {
  ///   // Make API call
  /// }
  /// ```
  static Future<bool> get hasInternet async {
    final status = await checkConnectivity();
    return status == ConnectivityStatus.connected;
  }

  /// Get last known status without making a new check
  ///
  /// Useful for UI that doesn't need real-time accuracy.
  static ConnectivityStatus? get lastKnownStatus => _lastKnownStatus;

  /// Check if connected via WiFi (vs mobile data)
  static Future<bool> get isOnWifi async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.wifi);
    } catch (e) {
      debugPrint('[ConnectivityHelper] Error checking WiFi: $e');
      return false;
    }
  }

  /// Check if connected via mobile data
  static Future<bool> get isOnMobileData async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.mobile);
    } catch (e) {
      debugPrint('[ConnectivityHelper] Error checking mobile data: $e');
      return false;
    }
  }

  /// Start listening for connectivity changes
  ///
  /// Call this once at app startup to begin monitoring.
  /// Returns a [StreamSubscription] that should be cancelled on dispose.
  // In connectivity_helper.dart

  /// Start listening for connectivity changes
  static StreamSubscription<List<ConnectivityResult>> startListening() {
    return _connectivity.onConnectivityChanged.listen((results) {
      // results is List<ConnectivityResult>
      final status = _mapResultsToStatus(results);

      if (status != _lastKnownStatus) {
        _lastKnownStatus = status;
        _controller.add(status);
        debugPrint('[ConnectivityHelper] Status: $status');
      }
    });
  }

  /// Map the list of results to our simplified status
  static ConnectivityStatus _mapResultsToStatus(
    List<ConnectivityResult> results,
  ) {
    if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
      return ConnectivityStatus.disconnected;
    }
    return ConnectivityStatus.connected;
  }

  /// Map connectivity_plus results to our simplified status

  /// Verify actual internet reachability by pinging a reliable endpoint
  ///
  /// This is more accurate than just checking network interfaces,
  /// but adds latency. Use only when necessary.
  // Option A: Simple reachability check using http package

  static Future<bool> _verifyInternetReachability() async {
    try {
      final response = await http
          .get(Uri.parse('https://clients3.google.com/generate_204'))
          .timeout(const Duration(seconds: 3));

      return response.statusCode == 204; // Google's endpoint returns 204
    } catch (_) {
      return false;
    }
  }

  // Option B: Skip reachability check entirely (faster, less accurate)

  /// Clean up resources
  static Future<void> dispose() async {
    await _controller.close();
    // Note: Don't close _connectivity - it's a singleton managed by the plugin
  }
}
