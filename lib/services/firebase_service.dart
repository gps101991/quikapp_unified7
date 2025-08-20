import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../config/env_config.dart';
import 'package:http/http.dart' as http;

/// Conditional Firebase Service - Only initializes when required and available
class ConditionalFirebaseService {
  static bool _isInitialized = false;
  static FirebaseOptions? _cachedOptions;
  static String? _lastError;

  /// Check if Firebase is required for this build
  static bool get isFirebaseRequired {
    return EnvConfig.pushNotify;
  }

  /// Check if Firebase configuration is available
  static bool get isFirebaseConfigAvailable {
    if (Platform.isAndroid) {
      return EnvConfig.firebaseConfigAndroid.isNotEmpty;
    } else if (Platform.isIOS) {
      return EnvConfig.firebaseConfigIos.isNotEmpty;
    }
    return false;
  }

  /// Check if Firebase should be initialized
  static bool get shouldInitializeFirebase {
    return isFirebaseRequired && isFirebaseConfigAvailable;
  }

  /// Get Firebase initialization status
  static bool get isInitialized => _isInitialized;

  /// Check if Firebase is actually available (initialized and apps exist)
  static bool get isFirebaseAvailable {
    try {
      return _isInitialized && Firebase.apps.isNotEmpty;
    } catch (e) {
      debugPrint("⚠️ Error checking Firebase availability: $e");
      return false;
    }
  }

  /// Safely check if Firebase is available without throwing errors
  static bool get isFirebaseAvailableSafe {
    try {
      if (!_isInitialized) return false;

      // Check if Firebase.apps is accessible
      final apps = Firebase.apps;
      return apps.isNotEmpty;
    } catch (e) {
      debugPrint("⚠️ Safe Firebase availability check failed: $e");
      return false;
    }
  }

  /// Get last Firebase error
  static String? get lastError => _lastError;

  /// Initialize Firebase conditionally
  static Future<bool> initializeConditionally() async {
    try {
      // Check if Firebase is needed
      if (!shouldInitializeFirebase) {
        debugPrint("ℹ️ Firebase not required or config not available");
        debugPrint("   - pushNotify: ${EnvConfig.pushNotify}");
        debugPrint("   - configAvailable: $isFirebaseConfigAvailable");
        return false;
      }

      // Check if already initialized
      if (_isInitialized) {
        debugPrint("✅ Firebase already initialized");
        return true;
      }

      // Load Firebase options
      final options = await _loadFirebaseOptions();
      if (options == null) {
        debugPrint("❌ Failed to load Firebase options");
        debugPrint(
            "🔄 Skipping Firebase initialization - continuing without Firebase");
        return false;
      }

      // Initialize Firebase
      await Firebase.initializeApp(options: options);
      _isInitialized = true;
      _lastError = null;

      debugPrint("✅ Firebase initialized successfully");
      return true;
    } catch (e) {
      _lastError = e.toString();
      debugPrint("❌ Firebase initialization failed: $e");
      debugPrint(
          "🔄 Skipping Firebase initialization - continuing without Firebase");
      return false;
    }
  }

  /// Load Firebase options with caching
  static Future<FirebaseOptions?> _loadFirebaseOptions() async {
    try {
      // Use cached options if available
      if (_cachedOptions != null) {
        debugPrint("📦 Using cached Firebase options");
        return _cachedOptions;
      }

      debugPrint("🔍 Loading Firebase configuration...");

      if (Platform.isAndroid) {
        _cachedOptions = await _loadAndroidConfig();
      } else if (Platform.isIOS) {
        _cachedOptions = await _loadIOSConfig();
      } else {
        throw UnsupportedError('Unsupported platform');
      }

      return _cachedOptions;
    } catch (e) {
      debugPrint("🚨 Error loading Firebase options: $e");
      debugPrint("🔄 Skipping Firebase setup - continuing without Firebase");
      return null;
    }
  }

  /// Load Android Firebase configuration
  static Future<FirebaseOptions?> _loadAndroidConfig() async {
    try {
      debugPrint("🤖 Loading Android Firebase config...");

      // First, try to load from local google-services.json file
      try {
        final localFile = File('android/app/google-services.json');
        if (await localFile.exists()) {
          debugPrint(
              "📁 Loading Firebase config from local google-services.json");
          final String jsonString = await localFile.readAsString();
          final Map<String, dynamic> jsonMap = json.decode(jsonString);

          return _parseGoogleServicesJson(jsonMap);
        }
      } catch (e) {
        debugPrint("⚠️ Failed to load local google-services.json: $e");
      }

      // Fallback: try to download from URL if local file doesn't exist
      if (EnvConfig.firebaseConfigAndroid.isNotEmpty) {
        debugPrint("🌐 Downloading Firebase config from URL...");
        try {
          final http.Response response = await http
              .get(
                Uri.parse(EnvConfig.firebaseConfigAndroid),
              )
              .timeout(const Duration(seconds: 10));

          if (response.statusCode != 200) {
            throw Exception(
              'Failed to download google-services.json (${response.statusCode})',
            );
          }

          final Map<String, dynamic> jsonMap = json.decode(response.body);
          return _parseGoogleServicesJson(jsonMap);
        } catch (e) {
          debugPrint("❌ Failed to download Firebase config: $e");
        }
      }

      debugPrint("❌ No Firebase configuration available (local or remote)");
      return null;
    } catch (e) {
      debugPrint("❌ Error loading Android Firebase config: $e");
      return null;
    }
  }

  /// Parse google-services.json content
  static FirebaseOptions? _parseGoogleServicesJson(
      Map<String, dynamic> jsonMap) {
    try {
      final projectInfo = jsonMap['project_info'];
      if (projectInfo == null) {
        throw Exception("Missing project_info in google-services.json");
      }

      final clients = jsonMap['client'] as List;
      if (clients.isEmpty) {
        throw Exception(
            "No client configuration found in google-services.json");
      }

      final client = clients.first;
      final clientInfo = client['client_info'];
      final apiKey = (client['api_key'] as List).firstWhere(
        (key) => key['current_key'] != null,
        orElse: () => throw Exception("No valid API key found"),
      );

      return FirebaseOptions(
        apiKey: apiKey['current_key'],
        appId: clientInfo['mobilesdk_app_id'],
        messagingSenderId: projectInfo['project_number'],
        projectId: projectInfo['project_id'],
        storageBucket: projectInfo['storage_bucket'],
      );
    } catch (e) {
      debugPrint("❌ Error parsing google-services.json: $e");
      return null;
    }
  }

  /// Load iOS Firebase configuration
  static Future<FirebaseOptions?> _loadIOSConfig() async {
    try {
      debugPrint("🍎 Loading iOS Firebase config...");

      // First, try to load from local GoogleService-Info.plist file
      try {
        final localFile = File('ios/Runner/GoogleService-Info.plist');
        if (await localFile.exists()) {
          debugPrint(
              "📁 Loading Firebase config from local GoogleService-Info.plist");
          final String plistStr = await localFile.readAsString();

          return _parsePlistString(plistStr);
        }
      } catch (e) {
        debugPrint("⚠️ Failed to load local GoogleService-Info.plist: $e");
      }

      // Download the PLIST file from the URL
      if (EnvConfig.firebaseConfigIos.isNotEmpty) {
        debugPrint("🌐 Downloading Firebase config from URL...");
        try {
          final http.Response response = await http
              .get(
                Uri.parse(EnvConfig.firebaseConfigIos),
              )
              .timeout(const Duration(seconds: 10));

          if (response.statusCode != 200) {
            throw Exception(
              'Failed to download GoogleService-Info.plist (${response.statusCode})',
            );
          }

          final String plistStr = response.body;
          return _parsePlistString(plistStr);
        } catch (e) {
          debugPrint("❌ Failed to download Firebase config: $e");
        }
      }

      debugPrint("❌ No Firebase configuration available (local or remote)");
      return null;
    } catch (e) {
      debugPrint("❌ Error loading iOS Firebase config: $e");
      return null;
    }
  }

  /// Parse PLIST string content
  static FirebaseOptions? _parsePlistString(String plistStr) {
    try {
      final apiKey = _extractFromPlist(plistStr, 'API_KEY');
      final appId = _extractFromPlist(plistStr, 'GOOGLE_APP_ID');
      final messagingSenderId = _extractFromPlist(plistStr, 'GCM_SENDER_ID');
      final projectId = _extractFromPlist(plistStr, 'PROJECT_ID');
      final storageBucket = _extractFromPlist(plistStr, 'STORAGE_BUCKET');
      final iosClientId = _extractFromPlist(plistStr, 'CLIENT_ID');
      final iosBundleId = _extractFromPlist(plistStr, 'BUNDLE_ID');

      if (apiKey == null ||
          appId == null ||
          messagingSenderId == null ||
          projectId == null) {
        throw Exception(
          "Missing required Firebase configuration values in GoogleService-Info.plist",
        );
      }

      return FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        storageBucket: storageBucket ?? '',
        iosClientId: iosClientId,
        iosBundleId: iosBundleId,
      );
    } catch (e) {
      debugPrint("❌ Error parsing GoogleService-Info.plist: $e");
      return null;
    }
  }

  /// Extract value from PLIST string
  static String? _extractFromPlist(String plistStr, String key) {
    final regex = RegExp('<$key>(.*?)</$key>');
    final match = regex.firstMatch(plistStr);
    return match?.group(1);
  }

  /// Clear Firebase cache (useful for testing)
  static void clearCache() {
    _cachedOptions = null;
    _lastError = null;
    debugPrint("🧹 Firebase cache cleared");
  }

  /// Reset Firebase state (useful for testing)
  static void reset() {
    _isInitialized = false;
    _cachedOptions = null;
    _lastError = null;
    debugPrint("🔄 Firebase state reset");
  }

  /// Get Firebase status summary
  static Map<String, dynamic> getStatus() {
    return {
      'isRequired': isFirebaseRequired,
      'isConfigAvailable': isFirebaseConfigAvailable,
      'shouldInitialize': shouldInitializeFirebase,
      'isInitialized': _isInitialized,
      'isAvailable': isFirebaseAvailable,
      'lastError': _lastError,
      'hasCachedOptions': _cachedOptions != null,
      'appsCount': Firebase.apps.length,
    };
  }
}

/// Legacy function for backward compatibility
@Deprecated('Use ConditionalFirebaseService.initializeConditionally() instead')
Future<FirebaseOptions> loadFirebaseOptionsFromJson() async {
  final options = await ConditionalFirebaseService._loadFirebaseOptions();
  if (options == null) {
    throw Exception('Failed to load Firebase options');
  }
  return options;
}
