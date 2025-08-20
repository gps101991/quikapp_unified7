import 'dart:io';
import 'package:flutter/material.dart';
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

/// 🌐 Initialize connectivity service with proper error handling
Future<void> _initializeConnectivity() async {
  try {
    debugPrint('🌐 Initializing connectivity service...');
    await ConnectivityService().initialize();
    debugPrint('✅ Connectivity service initialized');
  } catch (e) {
    debugPrint('⚠️ Connectivity initialization error: $e');
    debugPrint('🔄 Continuing without connectivity service...');
  }
}

/// 🔥 Initialize Firebase with proper error handling
Future<void> _initializeFirebase() async {
  try {
    debugPrint('🔥 Initializing Firebase...');
    await ConditionalFirebaseService.initializeConditionally();
    debugPrint('✅ Firebase initialized successfully');
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
