import 'package:flutter/foundation.dart';

/// 🚀 Optimized Environment Configuration for Codemagic Workflows
///
/// This class provides a unified interface for accessing environment variables
/// that are dynamically injected by Codemagic workflows. It includes:
/// - Type-safe access to all workflow variables
/// - Fallback values for development
/// - Platform-specific configurations
/// - Build-time optimization
class Environment {
  // Private constructor to prevent instantiation
  Environment._();

  // ===== CORE APP CONFIGURATION =====

  /// App name from workflow configuration
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'QuikApp',
  );

  /// App version name from workflow configuration
  static const String versionName = String.fromEnvironment(
    'VERSION_NAME',
    defaultValue: '1.0.0',
  );

  /// App version code from workflow configuration
  static const int versionCode = int.fromEnvironment(
    'VERSION_CODE',
    defaultValue: 1,
  );

  /// Package name for Android
  static const String packageName = String.fromEnvironment(
    'PKG_NAME',
    defaultValue: 'com.example.app',
  );

  /// Bundle ID for iOS
  static const String bundleId = String.fromEnvironment(
    'BUNDLE_ID',
    defaultValue: 'com.example.app',
  );

  /// Current workflow ID
  static const String workflowId = String.fromEnvironment(
    'WORKFLOW_ID',
    defaultValue: 'development',
  );

  // ===== USER & ORGANIZATION =====

  /// User name from workflow
  static const String userName = String.fromEnvironment(
    'USER_NAME',
    defaultValue: '',
  );

  /// App ID from workflow
  static const String appId = String.fromEnvironment(
    'APP_ID',
    defaultValue: '',
  );

  /// Organization name
  static const String orgName = String.fromEnvironment(
    'ORG_NAME',
    defaultValue: '',
  );

  /// Web URL
  static const String webUrl = String.fromEnvironment(
    'WEB_URL',
    defaultValue: '',
  );

  /// Email ID
  static const String emailId = String.fromEnvironment(
    'EMAIL_ID',
    defaultValue: '',
  );

  // ===== FEATURE FLAGS =====

  /// Push notification support
  static const bool pushNotify = bool.fromEnvironment(
    'PUSH_NOTIFY',
    defaultValue: false,
  );

  /// Chatbot functionality
  static const bool isChatbot = bool.fromEnvironment(
    'IS_CHATBOT',
    defaultValue: false,
  );

  /// Domain URL support
  static const bool isDomainUrl = bool.fromEnvironment(
    'IS_DOMAIN_URL',
    defaultValue: false,
  );

  /// Splash screen customization
  static const bool isSplash = bool.fromEnvironment(
    'IS_SPLASH',
    defaultValue: false,
  );

  /// Pull to refresh support
  static const bool isPulldown = bool.fromEnvironment(
    'IS_PULLDOWN',
    defaultValue: false,
  );

  /// Bottom menu support
  static const bool isBottomMenu = bool.fromEnvironment(
    'IS_BOTTOMMENU',
    defaultValue: false,
  );

  /// Loading indicator support
  static const bool isLoadIndicator = bool.fromEnvironment(
    'IS_LOAD_IND',
    defaultValue: false,
  );

  // ===== AUTHENTICATION =====

  /// Google authentication support
  static const bool isGoogleAuth = bool.fromEnvironment(
    'IS_GOOGLE_AUTH',
    defaultValue: false,
  );

  /// Apple authentication support
  static const bool isAppleAuth = bool.fromEnvironment(
    'IS_APPLE_AUTH',
    defaultValue: false,
  );

  // ===== PERMISSIONS =====

  /// Camera permission
  static const bool isCamera = bool.fromEnvironment(
    'IS_CAMERA',
    defaultValue: false,
  );

  /// Location permission
  static const bool isLocation = bool.fromEnvironment(
    'IS_LOCATION',
    defaultValue: false,
  );

  /// Microphone permission
  static const bool isMic = bool.fromEnvironment(
    'IS_MIC',
    defaultValue: false,
  );

  /// Notification permission
  static const bool isNotification = bool.fromEnvironment(
    'IS_NOTIFICATION',
    defaultValue: false,
  );

  /// Contact permission
  static const bool isContact = bool.fromEnvironment(
    'IS_CONTACT',
    defaultValue: false,
  );

  /// Biometric permission
  static const bool isBiometric = bool.fromEnvironment(
    'IS_BIOMETRIC',
    defaultValue: false,
  );

  /// Calendar permission
  static const bool isCalendar = bool.fromEnvironment(
    'IS_CALENDAR',
    defaultValue: false,
  );

  /// Storage permission
  static const bool isStorage = bool.fromEnvironment(
    'IS_STORAGE',
    defaultValue: false,
  );

  // ===== UI & BRANDING =====

  /// Logo URL
  static const String logoUrl = String.fromEnvironment(
    'LOGO_URL',
    defaultValue: '',
  );

  /// Splash image URL
  static const String splashUrl = String.fromEnvironment(
    'SPLASH_URL',
    defaultValue: '',
  );

  /// Splash background URL
  static const String splashBgUrl = String.fromEnvironment(
    'SPLASH_BG_URL',
    defaultValue: '',
  );

  /// Splash background color
  static const String splashBgColor = String.fromEnvironment(
    'SPLASH_BG_COLOR',
    defaultValue: '#FFFFFF',
  );

  /// Splash tagline text
  static const String splashTagline = String.fromEnvironment(
    'SPLASH_TAGLINE',
    defaultValue: '',
  );

  /// Splash tagline color
  static const String splashTaglineColor = String.fromEnvironment(
    'SPLASH_TAGLINE_COLOR',
    defaultValue: '#000000',
  );

  /// Splash tagline font
  static const String splashTaglineFont = String.fromEnvironment(
    'SPLASH_TAGLINE_FONT',
    defaultValue: 'Roboto',
  );

  /// Splash tagline size
  static const String splashTaglineSize = String.fromEnvironment(
    'SPLASH_TAGLINE_SIZE',
    defaultValue: '24',
  );

  /// Splash tagline bold
  static const bool splashTaglineBold = bool.fromEnvironment(
    'SPLASH_TAGLINE_BOLD',
    defaultValue: false,
  );

  /// Splash tagline italic
  static const bool splashTaglineItalic = bool.fromEnvironment(
    'SPLASH_TAGLINE_ITALIC',
    defaultValue: false,
  );

  /// Splash animation type
  static const String splashAnimation = String.fromEnvironment(
    'SPLASH_ANIMATION',
    defaultValue: 'fade',
  );

  /// Splash duration in seconds
  static const int splashDuration = int.fromEnvironment(
    'SPLASH_DURATION',
    defaultValue: 3,
  );

  // ===== BOTTOM MENU CONFIGURATION =====

  /// Bottom menu items JSON
  static const String bottomMenuItems = String.fromEnvironment(
    'BOTTOMMENU_ITEMS',
    defaultValue: '[]',
  );

  /// Bottom menu background color
  static const String bottomMenuBgColor = String.fromEnvironment(
    'BOTTOMMENU_BG_COLOR',
    defaultValue: '#FFFFFF',
  );

  /// Bottom menu icon color
  static const String bottomMenuIconColor = String.fromEnvironment(
    'BOTTOMMENU_ICON_COLOR',
    defaultValue: '#666666',
  );

  /// Bottom menu text color
  static const String bottomMenuTextColor = String.fromEnvironment(
    'BOTTOMMENU_TEXT_COLOR',
    defaultValue: '#666666',
  );

  /// Bottom menu font family
  static const String bottomMenuFont = String.fromEnvironment(
    'BOTTOMMENU_FONT',
    defaultValue: 'Roboto',
  );

  /// Bottom menu font size
  static const double bottomMenuFontSize = 12.0;

  /// Bottom menu font bold
  static const bool bottomMenuFontBold = bool.fromEnvironment(
    'BOTTOMMENU_FONT_BOLD',
    defaultValue: false,
  );

  /// Bottom menu font italic
  static const bool bottomMenuFontItalic = bool.fromEnvironment(
    'BOTTOMMENU_FONT_ITALIC',
    defaultValue: false,
  );

  /// Bottom menu active tab color
  static const String bottomMenuActiveTabColor = String.fromEnvironment(
    'BOTTOMMENU_ACTIVE_TAB_COLOR',
    defaultValue: '#007AFF',
  );

  /// Bottom menu icon position
  static const String bottomMenuIconPosition = String.fromEnvironment(
    'BOTTOMMENU_ICON_POSITION',
    defaultValue: 'above',
  );

  // ===== FIREBASE CONFIGURATION =====

  /// Firebase config for Android
  static const String firebaseConfigAndroid = String.fromEnvironment(
    'FIREBASE_CONFIG_ANDROID',
    defaultValue: '',
  );

  /// Firebase config for iOS
  static const String firebaseConfigIos = String.fromEnvironment(
    'FIREBASE_CONFIG_IOS',
    defaultValue: '',
  );

  // ===== BUILD INFORMATION =====

  /// Build ID from Codemagic
  static const String buildId = String.fromEnvironment(
    'CM_BUILD_ID',
    defaultValue: '',
  );

  /// Branch name
  static const String branch = String.fromEnvironment(
    'BRANCH',
    defaultValue: 'main',
  );

  /// Commit hash
  static const String commitHash = String.fromEnvironment(
    'CM_COMMIT',
    defaultValue: '',
  );

  // ===== UTILITY METHODS =====

  /// Check if running in production build
  static bool get isProduction => !kDebugMode;

  /// Check if running in development
  static bool get isDevelopment => kDebugMode;

  /// Check if running in test environment
  static bool get isTest =>
      const bool.fromEnvironment('dart.vm.product') == false;

  /// Get current platform-specific configuration
  static Map<String, dynamic> get platformConfig {
    if (kIsWeb) {
      return {
        'platform': 'web',
        'firebaseConfig': firebaseConfigAndroid, // Use Android config for web
      };
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return {
        'platform': 'android',
        'firebaseConfig': firebaseConfigAndroid,
        'packageName': packageName,
      };
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return {
        'platform': 'ios',
        'firebaseConfig': firebaseConfigIos,
        'bundleId': bundleId,
      };
    }
    return {
      'platform': 'unknown',
      'firebaseConfig': '',
    };
  }

  /// Get all configuration as a map for debugging
  static Map<String, dynamic> get allConfig => {
        'appName': appName,
        'versionName': versionName,
        'versionCode': versionCode,
        'packageName': packageName,
        'bundleId': bundleId,
        'workflowId': workflowId,
        'pushNotify': pushNotify,
        'isChatbot': isChatbot,
        'isDomainUrl': isDomainUrl,
        'isSplash': isSplash,
        'isBottomMenu': isBottomMenu,
        'isGoogleAuth': isGoogleAuth,
        'isAppleAuth': isAppleAuth,
        'buildId': buildId,
        'branch': branch,
        'commitHash': commitHash,
        'platform': platformConfig,
      };

  /// Validate critical configuration
  static List<String> get validationErrors {
    final errors = <String>[];

    if (appName.isEmpty) errors.add('APP_NAME is required');
    if (versionName.isEmpty) errors.add('VERSION_NAME is required');
    if (versionCode <= 0) errors.add('VERSION_CODE must be positive');
    if (packageName.isEmpty) errors.add('PKG_NAME is required');

    return errors;
  }

  /// Check if configuration is valid
  static bool get isValid => validationErrors.isEmpty;

  /// Get configuration summary for logging
  static String get configSummary => '''
🚀 Environment Configuration Summary:
   App: $appName v$versionName ($versionCode)
   Package: $packageName
   Workflow: $workflowId
   Platform: ${platformConfig['platform']}
   Features: Push($pushNotify) Chat($isChatbot) Auth($isGoogleAuth/$isAppleAuth)
   Build: $buildId on $branch
''';
}
