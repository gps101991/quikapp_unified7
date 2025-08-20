// Generated Android Environment Configuration
// Generated on: Fri Aug 15 08:00:00 UTC 2025
// Workflow: android-publish
// Platform: Android

class EnvConfig {
  // Core App Configuration
  static const String appName = "Pixaware";
  static const String versionName = "1.0.2";
  static const int versionCode = 11;
  static const String packageName = "co.pixaware.pixaware";
  static const String workflowId = "android-publish";

  // User & Organization
  static const String userName = "prasannasrie";
  static const String appId = "10023";
  static const String orgName = "Pixaware Technology Solutions Private Limited";
  static const String webUrl = "https://pixaware.co/";
  static const String emailId = "prasannasrinivasan32@gmail.com";

  // Feature Flags
  static const bool pushNotify = true;
  static const bool isChatbot = true;
  static const bool isDomainUrl = true;
  static const bool isSplash = true;
  static const bool isPulldown = true;
  static const bool isBottommenu = true;
  static const bool isLoadInd = true;
  static const bool isLoadIndicator = true;
  static const bool isGoogleAuth = true;
  static const bool isAppleAuth = true;

  // Permissions
  static const bool isCamera = false;
  static const bool isLocation = false;
  static const bool isMic = true;
  static const bool isNotification = true;
  static const bool isContact = false;
  static const bool isBiometric = false;
  static const bool isCalendar = false;
  static const bool isStorage = false;

  // UI/Branding
  static const String logoUrl =
      "https://raw.githubusercontent.com/prasanna91/QuikApp/main/pixaware_logo.png";
  static const String splashUrl =
      "https://raw.githubusercontent.com/prasanna91/QuikApp/main/pixaware_logo.png";
  static const String splashBg = "";
  static const String splashBgUrl = "";
  static const String splashBgColor = "#cbdbf5";
  static const String splashTagline = "Pixaware";
  static const String splashTaglineColor = "#a30237";
  static const String splashTaglineFont = "Roboto";
  static const String splashTaglineSize = "30";
  static const bool splashTaglineBold = false;
  static const bool splashTaglineItalic = false;
  static const String splashAnimation = "zoom";
  static const int splashDuration = 4;

  // Bottom Menu Configuration
  static const String bottommenuItems =
      """[{"label": "Home", "icon": {"type": "preset", "name": "home_outlined"}, "url": "https://pixaware.co/"}, {"label": "Solutions", "icon": {"type": "preset", "name": "build"}, "url": "https://pixaware.co/solutions/"}, {"label": "About", "icon": {"type": "preset", "name": "info"}, "url": "https://pixaware.co/who-we-are/"}, {"label": "Contact", "icon": {"type": "preset", "name": "phone"}, "url": "https://pixaware.co/lets-talk/"}]""";
  static const String bottommenuBgColor = "#FFFFFF";
  static const String bottommenuIconColor = "#6d6e8c";
  static const String bottommenuTextColor = "#6d6e8c";
  static const String bottommenuFont = "DM Sans";
  static const double bottommenuFontSize = 12.0;
  static const bool bottommenuFontBold = false;
  static const bool bottommenuFontItalic = false;
  static const String bottommenuActiveTabColor = "#a30237";
  static const String bottommenuIconPosition = "above";
  static const String bottommenuVisibleOn = "home,settings,profile";

  // Firebase Configuration (Android only)
  static const String firebaseConfigAndroid =
      "https://raw.githubusercontent.com/prasanna91/QuikApp/main/google-services-pixaware.json";
  static const String firebaseConfigIos = "";

  // Android Signing
  static const String keyStoreUrl =
      "https://raw.githubusercontent.com/prasanna91/QuikApp/main/keystore.jks";
  static const String cmKeystorePassword = "opeN@1234";
  static const String cmKeyAlias = "my_key_alias";
  static const String cmKeyPassword = "opeN@1234";

  // iOS Signing (not used in Android build)
  static const String appleTeamId = "9H2AD7NQ49";
  static const String apnsKeyId = "";
  static const String apnsAuthKeyUrl = "";
  static const String certPassword = "";
  static const String profileUrl = "";
  static const String certP12Url = "";
  static const String certCerUrl = "";
  static const String certKeyUrl = "";
  static const String profileType = "";
  static const String appStoreConnectKeyIdentifier = "";

  // Build Environment
  static const String buildId = "689eb6062db84a669e2a003c";
  static const String buildDir = "";
  static const String projectRoot = "";
  static const String outputDir = "output";

  // Utility Methods
  static bool get isAndroidBuild => true;
  static bool get isIosBuild => false;
  static bool get isCombinedBuild => false;
  static bool get hasFirebase => firebaseConfigAndroid.isNotEmpty;
  static bool get hasKeystore => keyStoreUrl.isNotEmpty;
  static bool get hasIosSigning => false;

  // Firebase Status Helpers
  static bool get isFirebaseRequired => pushNotify;
  static bool get hasFirebaseConfig => firebaseConfigAndroid.isNotEmpty;
  static bool get shouldInitializeFirebase =>
      pushNotify && firebaseConfigAndroid.isNotEmpty;
}
