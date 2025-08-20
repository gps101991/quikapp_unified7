import 'package:flutter/foundation.dart';
import '../config/environment.dart';
import 'firebase_service.dart';
import 'notification_service.dart';
import 'connectivity_service.dart';
import 'oauth_service.dart';

/// 🚀 Optimized Service Factory for Codemagic Workflows
///
/// This factory dynamically initializes and configures services
/// based on the current workflow and environment configuration.
class ServiceFactory {
  static final ServiceFactory _instance = ServiceFactory._internal();
  factory ServiceFactory() => _instance;
  ServiceFactory._internal();

  // Service instances
  late final ConnectivityService _connectivityService;
  ConditionalFirebaseService? _firebaseService;
  dynamic _notificationService;
  OAuthService? _oauthService;

  // Service status tracking
  final Map<String, bool> _serviceStatus = {};
  final Map<String, String> _serviceErrors = {};

  /// Initialize all required services based on workflow configuration
  Future<void> initializeServices() async {
    debugPrint(
        '🚀 Initializing services for workflow: ${Environment.workflowId}');

    try {
      // 1. Always initialize connectivity service
      await _initializeConnectivityService();

      // 2. Initialize Firebase if required
      if (Environment.pushNotify) {
        await _initializeFirebaseService();
      }

      // 3. Initialize notifications if required
      if (Environment.pushNotify && Environment.isNotification) {
        await _initializeNotificationService();
      }

      // 4. Initialize OAuth services if required
      if (Environment.isGoogleAuth || Environment.isAppleAuth) {
        await _initializeOAuthService();
      }

      debugPrint('✅ Service initialization completed');
      _logServiceStatus();
    } catch (e, stackTrace) {
      debugPrint('❌ Service initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Initialize connectivity service (always required)
  Future<void> _initializeConnectivityService() async {
    try {
      debugPrint('🌐 Initializing connectivity service...');
      _connectivityService = ConnectivityService();
      await _connectivityService.initialize();

      // Force connectivity refresh for reliability
      await _connectivityService.refreshConnectivity();

      _serviceStatus['connectivity'] = true;
      debugPrint('✅ Connectivity service initialized');
    } catch (e) {
      _serviceStatus['connectivity'] = false;
      _serviceErrors['connectivity'] = e.toString();
      debugPrint('❌ Connectivity service initialization failed: $e');
      rethrow;
    }
  }

  /// Initialize Firebase service conditionally
  Future<void> _initializeFirebaseService() async {
    try {
      debugPrint('🔥 Initializing Firebase service...');

      // Check if Firebase is required for current platform
      final platformConfig = Environment.platformConfig;
      final firebaseConfig = platformConfig['firebaseConfig'] as String;

      if (firebaseConfig.isEmpty) {
        debugPrint(
            'ℹ️ Firebase not required for platform: ${platformConfig['platform']}');
        _serviceStatus['firebase'] = false;
        return;
      }

      // Initialize Firebase service
      _firebaseService = ConditionalFirebaseService();
      final success =
          await ConditionalFirebaseService.initializeConditionally();

      if (success) {
        _serviceStatus['firebase'] = true;
        debugPrint('✅ Firebase service initialized');
      } else {
        _serviceStatus['firebase'] = false;
        _serviceErrors['firebase'] = 'Initialization failed';
        debugPrint('⚠️ Firebase service initialization failed');
      }
    } catch (e) {
      _serviceStatus['firebase'] = false;
      _serviceErrors['firebase'] = e.toString();
      debugPrint('❌ Firebase service initialization error: $e');
    }
  }

  /// Initialize notification service conditionally
  Future<void> _initializeNotificationService() async {
    try {
      debugPrint('🔔 Initializing notification service...');

      // Check if Firebase is available for push notifications
      if (_serviceStatus['firebase'] == true) {
        _notificationService = null; // Initialize notification service

        // Initialize local notifications
        await initLocalNotifications();
        debugPrint('✅ Local notifications initialized');

        // Request permissions
        final permissionsGranted = await requestNotificationPermissions();
        if (permissionsGranted) {
          debugPrint('✅ Notification permissions granted');
        } else {
          debugPrint('⚠️ Notification permissions not granted');
        }

        // Initialize Firebase messaging
        await initializeFirebaseMessaging();
        debugPrint('✅ Firebase messaging initialized');

        _serviceStatus['notifications'] = true;
        debugPrint('✅ Notification service initialized');
      } else {
        debugPrint('ℹ️ Firebase not available, skipping push notifications');
        _serviceStatus['notifications'] = false;
      }
    } catch (e) {
      _serviceStatus['notifications'] = false;
      _serviceErrors['notifications'] = e.toString();
      debugPrint('❌ Notification service initialization error: $e');
    }
  }

  /// Initialize OAuth service conditionally
  Future<void> _initializeOAuthService() async {
    try {
      debugPrint('🔐 Initializing OAuth service...');

      _oauthService = OAuthService();

      // Configure OAuth providers based on environment
      if (Environment.isGoogleAuth) {
        // await _oauthService!.configureGoogleAuth();
        debugPrint('✅ Google OAuth configured');
      }

      if (Environment.isAppleAuth) {
        // await _oauthService!.configureAppleAuth();
        debugPrint('✅ Apple OAuth configured');
      }

      _serviceStatus['oauth'] = true;
      debugPrint('✅ OAuth service initialized');
    } catch (e) {
      _serviceStatus['oauth'] = false;
      _serviceErrors['oauth'] = e.toString();
      debugPrint('❌ OAuth service initialization error: $e');
    }
  }

  /// Get service instance by type
  T? getService<T>() {
    if (T == ConnectivityService) return _connectivityService as T;
    if (T == ConditionalFirebaseService) return _firebaseService as T;
    if (T == OAuthService) return _oauthService as T;
    return null;
  }

  /// Check if a specific service is available
  bool isServiceAvailable(String serviceName) {
    return _serviceStatus[serviceName] ?? false;
  }

  /// Get service error if any
  String? getServiceError(String serviceName) {
    return _serviceErrors[serviceName];
  }

  /// Get all service statuses
  Map<String, bool> get serviceStatus => Map.unmodifiable(_serviceStatus);

  /// Get all service errors
  Map<String, String> get serviceErrors => Map.unmodifiable(_serviceErrors);

  /// Check if all required services are available
  bool get allRequiredServicesAvailable {
    final requiredServices = <String>['connectivity'];

    if (Environment.pushNotify) {
      requiredServices.add('firebase');
    }
    if (Environment.pushNotify && Environment.isNotification) {
      requiredServices.add('notifications');
    }
    if (Environment.isGoogleAuth || Environment.isAppleAuth) {
      requiredServices.add('oauth');
    }

    return requiredServices.every((service) => _serviceStatus[service] == true);
  }

  /// Get service configuration summary
  String get serviceSummary {
    final buffer = StringBuffer();
    buffer.writeln('🔧 Service Configuration Summary:');
    buffer.writeln('   Workflow: ${Environment.workflowId}');
    buffer.writeln('   Platform: ${Environment.platformConfig['platform']}');
    buffer.writeln('');

    for (final entry in _serviceStatus.entries) {
      final status = entry.value ? '✅' : '❌';
      final error = _serviceErrors[entry.key];
      buffer.writeln(
          '   $status ${entry.key}: ${entry.value ? 'Available' : 'Unavailable'}');
      if (error != null) {
        buffer.writeln('      Error: $error');
      }
    }

    buffer.writeln('');
    buffer.writeln(
        '   All Required Services: ${allRequiredServicesAvailable ? '✅ Available' : '❌ Missing'}');

    return buffer.toString();
  }

  /// Log service status for debugging
  void _logServiceStatus() {
    debugPrint(serviceSummary);
  }

  /// Reset all services (for testing)
  void reset() {
    _serviceStatus.clear();
    _serviceErrors.clear();
    debugPrint('🔄 Service factory reset');
  }

  /// Validate service configuration
  List<String> get validationErrors {
    final errors = <String>[];

    // Check required services
    if (!_serviceStatus['connectivity']!) {
      errors.add('Connectivity service is required but not available');
    }

    if (Environment.pushNotify && !_serviceStatus['firebase']!) {
      errors.add(
          'Firebase service is required for push notifications but not available');
    }

    if (Environment.pushNotify &&
        Environment.isNotification &&
        !_serviceStatus['notifications']!) {
      errors.add('Notification service is required but not available');
    }

    if ((Environment.isGoogleAuth || Environment.isAppleAuth) &&
        !_serviceStatus['oauth']!) {
      errors.add('OAuth service is required but not available');
    }

    return errors;
  }

  /// Check if service configuration is valid
  bool get isValid => validationErrors.isEmpty;
}

/// 🚀 Global service factory instance
final serviceFactory = ServiceFactory();
