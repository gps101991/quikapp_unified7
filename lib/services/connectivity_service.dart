import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectivityStream => _connectivityController.stream;
  bool _isConnected = true;

  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    try {
      debugPrint('🌐 Initializing connectivity service...');

      // First, try to check actual internet connectivity
      bool hasInternet = await _checkActualInternetConnectivity();
      debugPrint('🌐 Actual internet connectivity: $hasInternet');

      // Set initial state based on actual internet check
      _isConnected = hasInternet;
      _connectivityController.add(_isConnected);

      // Also check platform connectivity as backup
      final result = await _connectivity.checkConnectivity();
      debugPrint('🌐 Platform connectivity result: $result');

      // Listen to connectivity changes
      _connectivity.onConnectivityChanged
          .listen((List<ConnectivityResult> results) async {
        debugPrint('🌐 Platform connectivity changed: $results');

        // When platform connectivity changes, recheck actual internet
        bool hasInternet = await _checkActualInternetConnectivity();
        debugPrint('🌐 Rechecked internet connectivity: $hasInternet');

        _isConnected = hasInternet;
        _connectivityController.add(_isConnected);
        debugPrint(
            '🌐 Connectivity changed: ${_isConnected ? 'Connected' : 'Disconnected'}');
      });

      debugPrint('✅ Connectivity service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing connectivity service: $e');
      // Default to connected if there's an error
      _isConnected = true;
      _connectivityController.add(true);
    }
  }

  /// Check actual internet connectivity by making a real HTTP request
  Future<bool> _checkActualInternetConnectivity() async {
    try {
      // Try to connect to a reliable host
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
        debugPrint('✅ Internet connectivity confirmed via DNS lookup');
        return true;
      }
    } catch (e) {
      debugPrint('❌ DNS lookup failed: $e');
    }

    try {
      // Fallback: try to connect to a simple HTTP endpoint
      final socket =
          await Socket.connect('8.8.8.8', 53, timeout: Duration(seconds: 5));
      await socket.close();
      debugPrint('✅ Internet connectivity confirmed via socket test');
      return true;
    } catch (e) {
      debugPrint('❌ Socket test failed: $e');
    }

    // If all tests fail, assume we're connected (better UX)
    debugPrint(
        '⚠️ All connectivity tests failed, assuming connected for better UX');
    return true;
  }

  Future<bool> checkConnectivity() async {
    try {
      bool hasInternet = await _checkActualInternetConnectivity();
      _isConnected = hasInternet;
      return _isConnected;
    } catch (e) {
      debugPrint('❌ Error checking connectivity: $e');
      // Default to connected if there's an error
      _isConnected = true;
      return true;
    }
  }

  /// Force refresh connectivity status
  Future<void> refreshConnectivity() async {
    debugPrint('🔄 Refreshing connectivity status...');
    bool hasInternet = await _checkActualInternetConnectivity();
    _isConnected = hasInternet;
    _connectivityController.add(_isConnected);
    debugPrint(
        '🔄 Connectivity refreshed: ${_isConnected ? 'Connected' : 'Disconnected'}');
  }

  void dispose() {
    _connectivityController.close();
  }
}
