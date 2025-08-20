import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_service.dart';
import 'services/connectivity_service.dart';
import 'services/notification_service.dart';
import 'config/environment.dart';
import 'module/myapp.dart';

/// 🚀 Optimized Main Entry Point for Codemagic Workflows
///
/// This main function is optimized for:
/// - Dynamic environment configuration from Codemagic
/// - Platform-specific initialization
/// - Graceful fallback handling
/// - Comprehensive error logging
void main() {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Log environment configuration
  debugPrint(Environment.configSummary);

  // Validate configuration
  if (!Environment.isValid) {
    debugPrint('❌ Configuration validation failed:');
    for (final error in Environment.validationErrors) {
      debugPrint('   - $error');
    }
    // Continue with defaults for development
    if (Environment.isDevelopment) {
      debugPrint('🔄 Continuing in development mode with defaults...');
    } else {
      debugPrint('❌ Exiting due to invalid configuration in production');
      exit(1);
    }
  }

  // Initialize the app
  initializeApp();
}

/// 🚀 Optimized App Initialization
///
/// Handles all initialization tasks with proper error handling
/// and platform-specific optimizations
Future<void> initializeApp() async {
  try {
    debugPrint('🚀 Starting app initialization...');

    // 1. Initialize connectivity service
    await _initializeConnectivity();

    // 2. Initialize Firebase conditionally
    if (Environment.pushNotify) {
      await _initializeFirebase();
    } else {
      debugPrint('ℹ️ Firebase initialization skipped (PUSH_NOTIFY=false)');
    }

    // 3. Initialize notification services
    if (Environment.pushNotify && Environment.isNotification) {
      await _initializeNotifications();
    } else {
      debugPrint('ℹ️ Notification services skipped (not required)');
    }

    // 4. Run the app
    debugPrint('✅ App initialization completed successfully');
    runApp(MyApp(
      webUrl: Environment.webUrl,
      isBottomMenu: Environment.isBottomMenu,
      isSplash: Environment.isSplash,
      splashLogo: Environment.splashUrl,
      splashBg: Environment.splashBgUrl,
      splashDuration: Environment.splashDuration,
      splashAnimation: Environment.splashAnimation,
      bottomMenuItems: Environment.bottomMenuItems,
      isDomainUrl: Environment.isDomainUrl,
      backgroundColor: Environment.splashBgColor,
      activeTabColor: Environment.bottomMenuActiveTabColor,
      textColor: Environment.bottomMenuTextColor,
      iconColor: Environment.bottomMenuIconColor,
      iconPosition: Environment.bottomMenuIconPosition,
      taglineColor: Environment.splashTaglineColor,
      spbgColor: Environment.splashBgColor,
      isLoadIndicator: Environment.isLoadIndicator,
      splashTagline: Environment.splashTagline,
      taglineFont: Environment.splashTaglineFont,
      taglineSize: double.tryParse(Environment.splashTaglineSize) ?? 24.0,
      taglineBold: Environment.splashTaglineBold,
      taglineItalic: Environment.splashTaglineItalic,
    ));
  } catch (e, stackTrace) {
    debugPrint('❌ App initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');

    // In production, we might want to show an error screen
    if (Environment.isProduction) {
      debugPrint('🔄 Attempting to run app with minimal configuration...');
      runApp(MyApp(
        webUrl: Environment.webUrl,
        isBottomMenu: Environment.isBottomMenu,
        isSplash: Environment.isSplash,
        splashLogo: Environment.splashUrl,
        splashBg: Environment.splashBgUrl,
        splashDuration: Environment.splashDuration,
        splashAnimation: Environment.splashAnimation,
        bottomMenuItems: Environment.bottomMenuItems,
        isDomainUrl: Environment.isDomainUrl,
        backgroundColor: Environment.splashBgColor,
        activeTabColor: Environment.bottomMenuActiveTabColor,
        textColor: Environment.bottomMenuTextColor,
        iconColor: Environment.bottomMenuIconColor,
        iconPosition: Environment.bottomMenuIconPosition,
        taglineColor: Environment.splashTaglineColor,
        spbgColor: Environment.splashBgColor,
        isLoadIndicator: Environment.isLoadIndicator,
        splashTagline: Environment.splashTagline,
        taglineFont: Environment.splashTaglineFont,
        taglineSize: double.tryParse(Environment.splashTaglineSize) ?? 24.0,
        taglineBold: Environment.splashTaglineBold,
        taglineItalic: Environment.splashTaglineItalic,
      ));
    } else {
      rethrow;
    }
  }
}

/// 🌐 Initialize connectivity service with error handling
Future<void> _initializeConnectivity() async {
  try {
    debugPrint('🌐 Initializing connectivity service...');
    await ConnectivityService().initialize();
    debugPrint('✅ Connectivity service initialized');

    // Force connectivity refresh for reliability
    await ConnectivityService().refreshConnectivity();
    debugPrint('✅ Connectivity refresh completed');
  } catch (e) {
    debugPrint('⚠️ Connectivity service initialization failed: $e');
    debugPrint('🔄 Continuing without connectivity service...');

    // Set default connectivity state
    try {
      final connectivityService = ConnectivityService();
      await connectivityService.refreshConnectivity();
      debugPrint('✅ Forced connectivity refresh completed');
    } catch (refreshError) {
      debugPrint('❌ Connectivity refresh also failed: $refreshError');
    }
  }
}

/// 🔥 Initialize Firebase with platform-specific configuration
Future<void> _initializeFirebase() async {
  try {
    debugPrint('🔥 Initializing Firebase...');

    // Get platform-specific Firebase configuration
    final platformConfig = Environment.platformConfig;
    final firebaseConfig = platformConfig['firebaseConfig'] as String;

    if (firebaseConfig.isEmpty) {
      debugPrint(
          '⚠️ No Firebase configuration available for platform: ${platformConfig['platform']}');
      return;
    }

    debugPrint('📱 Platform: ${platformConfig['platform']}');
    debugPrint('🔥 Firebase config: $firebaseConfig');

    // Check Firebase service status
    final firebaseStatus = ConditionalFirebaseService.getStatus();
    debugPrint('   - Required: ${firebaseStatus['isRequired']}');
    debugPrint('   - Config Available: ${firebaseStatus['isConfigAvailable']}');
    debugPrint('   - Should Initialize: ${firebaseStatus['shouldInitialize']}');

    if (firebaseStatus['shouldInitialize'] == true) {
      final success =
          await ConditionalFirebaseService.initializeConditionally();
      if (success) {
        debugPrint('✅ Firebase initialized successfully');

        // Verify Firebase availability
        final isAvailable = ConditionalFirebaseService.isFirebaseAvailableSafe;
        final appsCount = ConditionalFirebaseService.getStatus()['appsCount'];
        debugPrint('   - Firebase available: $isAvailable');
        debugPrint('   - Apps count: $appsCount');
      } else {
        debugPrint('❌ Firebase initialization failed');
        debugPrint('🔄 Continuing without Firebase...');
      }
    } else {
      debugPrint('⚠️ Firebase not required or config not available');
      debugPrint('🔄 Continuing without Firebase...');
    }
  } catch (e) {
    debugPrint('⚠️ Firebase initialization error: $e');
    debugPrint('🔄 Continuing without Firebase...');
  }
}

/// 🔔 Initialize notification services with proper error handling
Future<void> _initializeNotifications() async {
  try {
    debugPrint('🔔 Initializing notification services...');

    // Initialize local notifications first
    await initLocalNotifications();
    debugPrint('✅ Local notifications initialized');

    // Request notification permissions
    final bool permissionsGranted = await requestNotificationPermissions();
    if (permissionsGranted) {
      debugPrint('✅ Notification permissions granted');
    } else {
      debugPrint(
          '⚠️ Notification permissions not granted - push notifications may not work');
    }

    // Initialize Firebase messaging if Firebase is available
    if (ConditionalFirebaseService.isFirebaseAvailableSafe) {
      await initializeFirebaseMessaging();
      debugPrint('✅ Firebase messaging initialized');
    } else {
      debugPrint('ℹ️ Firebase messaging skipped (Firebase not available)');
    }

    debugPrint('🎉 All notification services initialized successfully!');
  } catch (notificationError) {
    debugPrint(
        '❌ Notification service initialization failed: $notificationError');
    debugPrint('🔄 Continuing without notification services...');
  }
}

/// 🎯 Platform-specific configuration validation
void _validatePlatformConfiguration() {
  final platformConfig = Environment.platformConfig;
  final platform = platformConfig['platform'] as String;

  debugPrint('🔍 Validating platform configuration for: $platform');

  switch (platform) {
    case 'android':
      if (Environment.packageName.isEmpty) {
        debugPrint('⚠️ Warning: PKG_NAME not set for Android');
      }
      if (Environment.firebaseConfigAndroid.isEmpty) {
        debugPrint('⚠️ Warning: FIREBASE_CONFIG_ANDROID not set for Android');
      }
      break;

    case 'ios':
      if (Environment.bundleId.isEmpty) {
        debugPrint('⚠️ Warning: BUNDLE_ID not set for iOS');
      }
      if (Environment.firebaseConfigIos.isEmpty) {
        debugPrint('⚠️ Warning: FIREBASE_CONFIG_IOS not set for iOS');
      }
      break;

    case 'web':
      if (Environment.firebaseConfigAndroid.isEmpty) {
        debugPrint('⚠️ Warning: FIREBASE_CONFIG_ANDROID not set for web');
      }
      break;

    default:
      debugPrint('⚠️ Warning: Unknown platform: $platform');
  }
}

/// 📊 Log build information for debugging
void _logBuildInformation() {
  debugPrint('📊 Build Information:');
  debugPrint('   - Workflow: ${Environment.workflowId}');
  debugPrint('   - Build ID: ${Environment.buildId}');
  debugPrint('   - Branch: ${Environment.branch}');
  debugPrint('   - Commit: ${Environment.commitHash}');
  debugPrint(
      '   - Environment: ${Environment.isProduction ? 'Production' : 'Development'}');
  debugPrint('   - Platform: ${Environment.platformConfig['platform']}');

  // Log feature flags
  debugPrint('🎯 Feature Flags:');
  debugPrint('   - Push Notifications: ${Environment.pushNotify}');
  debugPrint('   - Chatbot: ${Environment.isChatbot}');
  debugPrint('   - Domain URL: ${Environment.isDomainUrl}');
  debugPrint('   - Splash Screen: ${Environment.isSplash}');
  debugPrint('   - Bottom Menu: ${Environment.isBottomMenu}');
  debugPrint('   - Google Auth: ${Environment.isGoogleAuth}');
  debugPrint('   - Apple Auth: ${Environment.isAppleAuth}');
}
