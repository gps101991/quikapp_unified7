import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_service.dart';
import 'services/connectivity_service.dart';
import 'services/notification_service.dart';
import 'config/env_config.dart';
import 'module/myapp.dart';

void main() {
  initializeApp();
}

Future<void> initializeApp() async {
  try {
    // Initialize connectivity service first
    try {
      await ConnectivityService().initialize();
      debugPrint("✅ Connectivity service initialized");
    } catch (e) {
      debugPrint("⚠️ Connectivity service initialization failed: $e");
      debugPrint("🔄 Continuing without connectivity service...");
      // Force connectivity to true to prevent offline screen
      try {
        final connectivityService = ConnectivityService();
        await connectivityService.refreshConnectivity();
        debugPrint(
            "🔄 Forced connectivity refresh after initialization failure");
      } catch (refreshError) {
        debugPrint("❌ Connectivity refresh also failed: $refreshError");
      }
    }

    // Initialize Firebase conditionally
    if (EnvConfig.pushNotify) {
      try {
        debugPrint("🔥 Initializing Firebase...");
        final firebaseStatus = ConditionalFirebaseService.getStatus();
        debugPrint("   - Required: ${firebaseStatus['isRequired']}");
        debugPrint(
            "   - Config Available: ${firebaseStatus['isConfigAvailable']}");
        debugPrint(
            "   - Should Initialize: ${firebaseStatus['shouldInitialize']}");

        if (firebaseStatus['shouldInitialize'] == true) {
          final success =
              await ConditionalFirebaseService.initializeConditionally();
          if (success) {
            debugPrint("✅ Firebase initialized successfully");

            // Verify Firebase is actually available
            final isAvailable =
                ConditionalFirebaseService.isFirebaseAvailableSafe;
            debugPrint("   - Firebase available: $isAvailable");
            debugPrint(
                "   - Apps count: ${ConditionalFirebaseService.getStatus()['appsCount']}");

            // 🔔 CRITICAL: Initialize notification services after Firebase
            try {
              debugPrint("🔔 Initializing notification services...");

              // Initialize local notifications first
              await initLocalNotifications();
              debugPrint("✅ Local notifications initialized");

              // 🔐 CRITICAL: Request notification permissions
              final bool permissionsGranted =
                  await requestNotificationPermissions();
              if (permissionsGranted) {
                debugPrint("✅ Notification permissions granted");
              } else {
                debugPrint(
                    "⚠️ Notification permissions not granted - push notifications may not work");
              }

              // Initialize Firebase messaging
              await initializeFirebaseMessaging();
              debugPrint("✅ Firebase messaging initialized");

              debugPrint(
                  "🎉 All notification services initialized successfully!");
            } catch (notificationError) {
              debugPrint(
                  "❌ Notification service initialization failed: $notificationError");
              debugPrint("🔄 Continuing without notification services...");
            }
          } else {
            debugPrint("❌ Firebase initialization failed");
            debugPrint("🔄 Continuing without Firebase...");
          }
        } else {
          debugPrint("⚠️ Firebase not required or config not available");
          debugPrint("🔄 Continuing without Firebase...");
        }
      } catch (e) {
        debugPrint("⚠️ Firebase initialization error: $e");
        debugPrint("🔄 Continuing without Firebase...");
      }
    } else {
      debugPrint("ℹ️ Firebase not required (PUSH_NOTIFY=false)");

      // 🔔 CRITICAL: Even without Firebase, initialize local notifications for basic functionality
      try {
        debugPrint("🔔 Initializing local notifications (without Firebase)...");
        await initLocalNotifications();
        debugPrint("✅ Local notifications initialized");

        // 🔐 CRITICAL: Request notification permissions even without Firebase
        final bool permissionsGranted = await requestNotificationPermissions();
        if (permissionsGranted) {
          debugPrint("✅ Notification permissions granted");
        } else {
          debugPrint(
              "⚠️ Notification permissions not granted - push notifications may not work");
        }
      } catch (notificationError) {
        debugPrint(
            "❌ Local notification initialization failed: $notificationError");
      }
    }

    // Validate critical environment variables
    if (EnvConfig.webUrl.isEmpty) {
      debugPrint("❗ Missing WEB_URL environment variable.");
      runApp(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    "Configuration Error",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text("WEB_URL not configured."),
                  SizedBox(height: 16),
                  Text(
                    "Please check your environment configuration.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      return;
    }

    // Validate other critical values
    if (EnvConfig.appName.isEmpty) {
      debugPrint("⚠️ App name is empty, using fallback");
    }

    debugPrint("""
      🛠 Runtime Config:
      - pushNotify: ${EnvConfig.pushNotify}
      - webUrl: ${EnvConfig.webUrl}
      - isSplash: ${EnvConfig.isSplash},
      - splashLogo: ${EnvConfig.splashUrl},
      - splashBg: ${EnvConfig.splashBg},
      - splashDuration: ${EnvConfig.splashDuration},
      - splashAnimation: ${EnvConfig.splashAnimation},
      - taglineColor: ${EnvConfig.splashTaglineColor},
      - spbgColor: ${EnvConfig.splashBgColor},
      - isBottomMenu: ${EnvConfig.isBottommenu},
      - bottomMenuItems: ${EnvConfig.bottommenuItems},
      - isDomainUrl: ${EnvConfig.isDomainUrl},
      - backgroundColor: ${EnvConfig.bottommenuBgColor},
      - activeTabColor: ${EnvConfig.bottommenuActiveTabColor},
      - textColor: ${EnvConfig.bottommenuTextColor},
      - iconColor: ${EnvConfig.bottommenuIconColor},
      - iconPosition: ${EnvConfig.bottommenuIconPosition},
      - Permissions:
        - Camera: ${EnvConfig.isCamera}
        - Location: ${EnvConfig.isLocation}
        - Mic: ${EnvConfig.isMic}
        - Notification: ${EnvConfig.isNotification}
        - Contact: ${EnvConfig.isContact}
      """);

    // Safely parse numeric values with fallbacks
    double taglineSize;
    try {
      taglineSize = double.parse(EnvConfig.splashTaglineSize);
    } catch (e) {
      debugPrint(
        "⚠️ Failed to parse splashTaglineSize: ${EnvConfig.splashTaglineSize}, using default: 14.0",
      );
      taglineSize = 14.0;
    }

    // Create MyApp with error handling
    try {
      final myApp = MyApp(
        webUrl: EnvConfig.webUrl,
        isSplash: EnvConfig.isSplash,
        splashLogo: EnvConfig.splashUrl,
        splashBg: EnvConfig.splashBg,
        splashDuration: EnvConfig.splashDuration,
        splashAnimation: EnvConfig.splashAnimation,
        taglineColor: EnvConfig.splashTaglineColor,
        spbgColor: EnvConfig.splashBgColor,
        isBottomMenu: EnvConfig.isBottommenu,
        bottomMenuItems: EnvConfig.bottommenuItems,
        isDomainUrl: EnvConfig.isDomainUrl,
        backgroundColor: EnvConfig.bottommenuBgColor,
        activeTabColor: EnvConfig.bottommenuActiveTabColor,
        textColor: EnvConfig.bottommenuTextColor,
        iconColor: EnvConfig.bottommenuIconColor,
        iconPosition: EnvConfig.bottommenuIconPosition,
        isLoadIndicator: EnvConfig.isLoadIndicator,
        splashTagline: EnvConfig.splashTagline,
        taglineFont: EnvConfig.splashTaglineFont,
        taglineSize: taglineSize,
        taglineBold: EnvConfig.splashTaglineBold,
        taglineItalic: EnvConfig.splashTaglineItalic,
      );

      debugPrint("✅ MyApp created successfully, running app...");
      debugPrint("🔍 App configuration summary:");
      debugPrint("   - Web URL: ${EnvConfig.webUrl}");
      debugPrint("   - Splash enabled: ${EnvConfig.isSplash}");
      debugPrint("   - Bottom menu enabled: ${EnvConfig.isBottommenu}");
      debugPrint("   - Firebase enabled: ${EnvConfig.pushNotify}");
      debugPrint("🚀 Starting app...");
      runApp(myApp);
    } catch (e, stackTrace) {
      debugPrint("❌ Error creating MyApp: $e");
      debugPrint("Stack trace: $stackTrace");

      // Show error screen instead of crashing
      runApp(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    "App Creation Error",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text("Failed to create app: $e"),
                  SizedBox(height: 16),
                  Text(
                    "Please check the configuration and try again.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Show debug information in console instead of dialog
                      debugPrint("=== DEBUG INFO ===");
                      debugPrint("Error: $e");
                      debugPrint("Stack Trace: $stackTrace");
                      debugPrint("==================");
                    },
                    child: Text("Show Debug Info in Console"),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  } catch (e, stackTrace) {
    debugPrint("❌ Fatal error during initialization: $e");
    debugPrint("Stack trace: $stackTrace");
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text("Error: $e"))),
      ),
    );
  }
}
