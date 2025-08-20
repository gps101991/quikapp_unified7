#!/bin/bash
set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ENV_GEN] $1"; }

# Network connectivity test
test_network_connectivity() {
    log "🌐 Testing network connectivity..."
    
    # Test basic internet connectivity
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log "✅ Basic internet connectivity confirmed"
    else
        log "⚠️  Basic internet connectivity issues detected"
    fi
    
    # Test DNS resolution
    if nslookup google.com >/dev/null 2>&1; then
        log "✅ DNS resolution working"
    else
        log "⚠️  DNS resolution issues detected"
    fi
    
    # Test HTTPS connectivity
    if curl --connect-timeout 10 --max-time 30 --silent --head https://www.google.com >/dev/null 2>&1; then
        log "✅ HTTPS connectivity confirmed"
    else
        log "⚠️  HTTPS connectivity issues detected"
    fi
}

# Enhanced environment validation
validate_environment() {
    log "🔍 Validating build environment..."
    
    # Check essential tools
    local tools=("flutter" "java" "gradle" "curl")
    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            log "✅ $tool is available"
        else
            log "⚠️  $tool is not available"
        fi
    done
    
    # Check Flutter version
    if flutter --version >/dev/null 2>&1; then
        FLUTTER_VERSION=$(flutter --version | head -1)
        log "📱 Flutter version: $FLUTTER_VERSION"
    fi
    
    # Check Java version
    if java -version >/dev/null 2>&1; then
        JAVA_VERSION=$(java -version 2>&1 | head -1)
        log "☕ Java version: $JAVA_VERSION"
    fi
    
    # Check available disk space
    if command -v df >/dev/null 2>&1; then
        DISK_SPACE=$(df -h . | awk 'NR==2{print $4}')
        log "💾 Available disk space: $DISK_SPACE"
    fi
    
    # Check available memory
    if command -v free >/dev/null 2>&1; then
        AVAILABLE_MEM=$(free -m | awk 'NR==2{printf "%.0f", $7}')
        log "🧠 Available memory: ${AVAILABLE_MEM}MB"
    fi
}

# Generate Android-specific environment configuration
generate_android_env_config() {
    log "📱 Generating Android-specific environment configuration..."
    
    cat > lib/config/env_config.dart <<EOF
// Generated Android Environment Configuration
// Generated on: $(date)
// Workflow: ${WORKFLOW_ID:-unknown}
// Platform: Android

class EnvConfig {
  // Core App Configuration
  static const String appName = "${APP_NAME:-QuikApp}";
  static const String versionName = "${VERSION_NAME:-1.0.0}";
  static const int versionCode = ${VERSION_CODE:-1};
  static const String packageName = "${PKG_NAME:-com.example.app}";
  static const String workflowId = "${WORKFLOW_ID:-unknown}";
  
  // User & Organization
  static const String userName = "${USER_NAME:-}";
  static const String appId = "${APP_ID:-}";
  static const String orgName = "${ORG_NAME:-}";
  static const String webUrl = "${WEB_URL:-}";
  static const String emailId = "${EMAIL_ID:-}";
  
  // Feature Flags
  static const bool pushNotify = ${PUSH_NOTIFY:-false};
  static const bool isChatbot = ${IS_CHATBOT:-false};
  static const bool isDomainUrl = ${IS_DOMAIN_URL:-false};
  static const bool isSplash = ${IS_SPLASH:-false};
  static const bool isPulldown = ${IS_PULLDOWN:-false};
  static const bool isBottommenu = ${IS_BOTTOMMENU:-false};
  static const bool isLoadInd = ${IS_LOAD_IND:-false};
  static const bool isLoadIndicator = ${IS_LOAD_IND:-false};
  static const bool isGoogleAuth = ${IS_GOOGLE_AUTH:-false};
  static const bool isAppleAuth = ${IS_APPLE_AUTH:-false};
  
  // Permissions
  static const bool isCamera = ${IS_CAMERA:-false};
  static const bool isLocation = ${IS_LOCATION:-false};
  static const bool isMic = ${IS_MIC:-false};
  static const bool isNotification = ${IS_NOTIFICATION:-false};
  static const bool isContact = ${IS_CONTACT:-false};
  static const bool isBiometric = ${IS_BIOMETRIC:-false};
  static const bool isCalendar = ${IS_CALENDAR:-false};
  static const bool isStorage = ${IS_STORAGE:-false};
  
  // UI/Branding
  static const String logoUrl = "${LOGO_URL:-}";
  static const String splashUrl = "${SPLASH_URL:-}";
  static const String splashBg = "${SPLASH_BG_URL:-}";
  static const String splashBgUrl = "${SPLASH_BG_URL:-}";
  static const String splashBgColor = "${SPLASH_BG_COLOR:-#FFFFFF}";
  static const String splashTagline = "${SPLASH_TAGLINE:-}";
  static const String splashTaglineColor = "${SPLASH_TAGLINE_COLOR:-#000000}";
  static const String splashTaglineFont = "${SPLASH_TAGLINE_FONT:-DM Sans}";
  static const String splashTaglineSize = "${SPLASH_TAGLINE_SIZE:-14.0}";
  static const bool splashTaglineBold = ${SPLASH_TAGLINE_BOLD:-false};
  static const bool splashTaglineItalic = ${SPLASH_TAGLINE_ITALIC:-false};
  static const String splashAnimation = "${SPLASH_ANIMATION:-none}";
  static const int splashDuration = ${SPLASH_DURATION:-3};

  // Bottom Menu Configuration
  static const String bottommenuItems = """${BOTTOMMENU_ITEMS:-[]}""";
  static const String bottommenuBgColor = "${BOTTOMMENU_BG_COLOR:-#FFFFFF}";
  static const String bottommenuIconColor = "${BOTTOMMENU_ICON_COLOR:-#000000}";
  static const String bottommenuTextColor = "${BOTTOMMENU_TEXT_COLOR:-#000000}";
  static const String bottommenuFont = "${BOTTOMMENU_FONT:-DM Sans}";
  static const double bottommenuFontSize = ${BOTTOMMENU_FONT_SIZE:-14.0};
  static const bool bottommenuFontBold = ${BOTTOMMENU_FONT_BOLD:-false};
  static const bool bottommenuFontItalic = ${BOTTOMMENU_FONT_ITALIC:-false};
  static const String bottommenuActiveTabColor = "${BOTTOMMENU_ACTIVE_TAB_COLOR:-#0000FF}";
  static const String bottommenuIconPosition = "${BOTTOMMENU_ICON_POSITION:-top}";
  static const String bottommenuVisibleOn = "${BOTTOMMENU_VISIBLE_ON:-}";

  // Firebase Configuration
  static const String firebaseConfigAndroid = "${FIREBASE_CONFIG_ANDROID:-}";
  static const String firebaseConfigIos = "";

  // Firebase Status Helpers
  static bool get hasFirebaseConfig => firebaseConfigAndroid.isNotEmpty || firebaseConfigIos.isNotEmpty;
  static bool get isFirebaseRequired => ${PUSH_NOTIFY:-false};
  static bool get shouldInitializeFirebase => isFirebaseRequired && hasFirebaseConfig;

  // Android Signing
  static const String keyStoreUrl = "${KEY_STORE_URL:-}";
  static const String cmKeystorePassword = "${CM_KEYSTORE_PASSWORD:-}";
  static const String cmKeyAlias = "${CM_KEY_ALIAS:-}";
  static const String cmKeyPassword = "${CM_KEY_PASSWORD:-}";

  // Build Environment
  static const String buildId = "${CM_BUILD_ID:-unknown}";
  static const String buildDir = "${CM_BUILD_DIR:-}";
  static const String projectRoot = "${PROJECT_ROOT:-}";
  static const String outputDir = "${OUTPUT_DIR:-output}";

  // Utility Methods
  static bool get isAndroidBuild => true;
  static bool get isIosBuild => false;
  static bool get isCombinedBuild => false;
  static bool get hasFirebase => firebaseConfigAndroid.isNotEmpty;
  static bool get hasKeystore => keyStoreUrl.isNotEmpty;
  static bool get hasIosSigning => false;
}
EOF
}

# Generate iOS-specific environment configuration
generate_ios_env_config() {
    log "🍎 Generating iOS-specific environment configuration..."
    
    cat > lib/config/env_config.dart <<EOF
// Generated iOS Environment Configuration
// Generated on: $(date)
// Workflow: ${WORKFLOW_ID:-unknown}
// Platform: iOS

class EnvConfig {
  // Core App Configuration
  static const String appName = "${APP_NAME:-QuikApp}";
  static const String versionName = "${VERSION_NAME:-1.0.0}";
  static const int versionCode = ${VERSION_CODE:-1};
  static const String bundleId = "${BUNDLE_ID:-com.example.app}";
  static const String workflowId = "${WORKFLOW_ID:-unknown}";
  
  // User & Organization
  static const String userName = "${USER_NAME:-}";
  static const String appId = "${APP_ID:-}";
  static const String orgName = "${ORG_NAME:-}";
  static const String webUrl = "${WEB_URL:-}";
  static const String emailId = "${EMAIL_ID:-}";
  
  // Feature Flags
  static const bool pushNotify = ${PUSH_NOTIFY:-false};
  static const bool isChatbot = ${IS_CHATBOT:-false};
  static const bool isDomainUrl = ${IS_DOMAIN_URL:-false};
  static const bool isSplash = ${IS_SPLASH:-false};
  static const bool isPulldown = ${IS_PULLDOWN:-false};
  static const bool isBottommenu = ${IS_BOTTOMMENU:-false};
  static const bool isLoadInd = ${IS_LOAD_IND:-false};
  static const bool isLoadIndicator = ${IS_LOAD_IND:-false};
  
  // Permissions
  static const bool isCamera = ${IS_CAMERA:-false};
  static const bool isLocation = ${IS_LOCATION:-false};
  static const bool isMic = ${IS_MIC:-false};
  static const bool isNotification = ${IS_NOTIFICATION:-false};
  static const bool isContact = ${IS_CONTACT:-false};
  static const bool isBiometric = ${IS_BIOMETRIC:-false};
  static const bool isCalendar = ${IS_CALENDAR:-false};
  static const bool isStorage = ${IS_STORAGE:-false};
  
  // UI/Branding
  static const String logoUrl = "${LOGO_URL:-}";
  static const String splashUrl = "${SPLASH_URL:-}";
  static const String splashBg = "${SPLASH_BG_URL:-}";
  static const String splashBgUrl = "${SPLASH_BG_URL:-}";
  static const String splashBgColor = "${SPLASH_BG_COLOR:-#FFFFFF}";
  static const String splashTagline = "${SPLASH_TAGLINE:-}";
  static const String splashTaglineColor = "${SPLASH_TAGLINE_COLOR:-#000000}";
  static const String splashTaglineFont = "${SPLASH_TAGLINE_FONT:-DM Sans}";
  static const String splashTaglineSize = "${SPLASH_TAGLINE_SIZE:-14.0}";
  static const bool splashTaglineBold = ${SPLASH_TAGLINE_BOLD:-false};
  static const bool splashTaglineItalic = ${SPLASH_TAGLINE_ITALIC:-false};
  static const String splashAnimation = "${SPLASH_ANIMATION:-none}";
  static const int splashDuration = ${SPLASH_DURATION:-3};

  // Bottom Menu Configuration
  static const String bottommenuItems = """${BOTTOMMENU_ITEMS:-[]}""";
  static const String bottommenuBgColor = "${BOTTOMMENU_BG_COLOR:-#FFFFFF}";
  static const String bottommenuIconColor = "${BOTTOMMENU_ICON_COLOR:-#000000}";
  static const String bottommenuTextColor = "${BOTTOMMENU_TEXT_COLOR:-#000000}";
  static const String bottommenuFont = "${BOTTOMMENU_FONT:-DM Sans}";
  static const double bottommenuFontSize = ${BOTTOMMENU_FONT_SIZE:-14.0};
  static const bool bottommenuFontBold = ${BOTTOMMENU_FONT_BOLD:-false};
  static const bool bottommenuFontItalic = ${BOTTOMMENU_FONT_ITALIC:-false};
  static const String bottommenuActiveTabColor = "${BOTTOMMENU_ACTIVE_TAB_COLOR:-#0000FF}";
  static const String bottommenuIconPosition = "${BOTTOMMENU_ICON_POSITION:-top}";
  static const String bottommenuVisibleOn = "${BOTTOMMENU_VISIBLE_ON:-}";

  // Firebase Configuration
  static const String firebaseConfigIos = "${FIREBASE_CONFIG_IOS:-}";
  static const String firebaseConfigAndroid = "";

  // Firebase Status Helpers
  static bool get hasFirebaseConfig => firebaseConfigAndroid.isNotEmpty || firebaseConfigIos.isNotEmpty;
  static bool get isFirebaseRequired => ${PUSH_NOTIFY:-false};
  static bool get shouldInitializeFirebase => isFirebaseRequired && hasFirebaseConfig;

  // iOS Signing
  static const String appleTeamId = "${APPLE_TEAM_ID:-}";
  static const String apnsKeyId = "${APNS_KEY_ID:-}";
  static const String apnsAuthKeyUrl = "${APNS_AUTH_KEY_URL:-}";
  static const String certPassword = "${CERT_PASSWORD:-}";
  static const String profileUrl = "${PROFILE_URL:-}";
  static const String certP12Url = "${CERT_P12_URL:-}";
  static const String certCerUrl = "${CERT_CER_URL:-}";
  static const String certKeyUrl = "${CERT_KEY_URL:-}";
  static const String profileType = "${PROFILE_TYPE:-app-store}";
  static const String appStoreConnectKeyIdentifier = "${APP_STORE_CONNECT_KEY_IDENTIFIER:-}";

  // Build Environment
  static const String buildId = "${CM_BUILD_ID:-unknown}";
  static const String buildDir = "${CM_BUILD_DIR:-}";
  static const String projectRoot = "${PROJECT_ROOT:-}";
  static const String outputDir = "${OUTPUT_DIR:-output}";

  // Utility Methods
  static bool get isAndroidBuild => false;
  static bool get isIosBuild => true;
  static bool get isCombinedBuild => false;
  static bool get hasFirebase => firebaseConfigIos.isNotEmpty;
  static bool get hasKeystore => false;
  static bool get hasIosSigning => certPassword.isNotEmpty && profileUrl.isNotEmpty;
}
EOF
}

# Generate combined environment configuration
generate_combined_env_config() {
    log "🔄 Generating combined environment configuration..."
    
    cat > lib/config/env_config.dart <<EOF
// Generated Combined Environment Configuration
// Generated on: $(date)
// Workflow: ${WORKFLOW_ID:-unknown}
// Platform: Android + iOS

class EnvConfig {
  // Core App Configuration
  static const String appName = "${APP_NAME:-QuikApp}";
  static const String versionName = "${VERSION_NAME:-1.0.0}";
  static const int versionCode = ${VERSION_CODE:-1};
  static const String packageName = "${PKG_NAME:-com.example.app}";
  static const String bundleId = "${BUNDLE_ID:-com.example.app}";
  static const String workflowId = "${WORKFLOW_ID:-unknown}";
  
  // User & Organization
  static const String userName = "${USER_NAME:-}";
  static const String appId = "${APP_ID:-}";
  static const String orgName = "${ORG_NAME:-}";
  static const String webUrl = "${WEB_URL:-}";
  static const String emailId = "${EMAIL_ID:-}";
  
  // Feature Flags
  static const bool pushNotify = ${PUSH_NOTIFY:-false};
  static const bool isChatbot = ${IS_CHATBOT:-false};
  static const bool isDomainUrl = ${IS_DOMAIN_URL:-false};
  static const bool isSplash = ${IS_SPLASH:-false};
  static const bool isPulldown = ${IS_PULLDOWN:-false};
  static const bool isBottommenu = ${IS_BOTTOMMENU:-false};
  static const bool isLoadInd = ${IS_LOAD_IND:-false};
  static const bool isLoadIndicator = ${IS_LOAD_IND:-false};
  
  // Permissions
  static const bool isCamera = ${IS_CAMERA:-false};
  static const bool isLocation = ${IS_LOCATION:-false};
  static const bool isMic = ${IS_MIC:-false};
  static const bool isNotification = ${IS_NOTIFICATION:-false};
  static const bool isContact = ${IS_CONTACT:-false};
  static const bool isBiometric = ${IS_BIOMETRIC:-false};
  static const bool isCalendar = ${IS_CALENDAR:-false};
  static const bool isStorage = ${IS_STORAGE:-false};

  // UI/Branding
  static const String logoUrl = "${LOGO_URL:-}";
  static const String splashUrl = "${SPLASH_URL:-}";
  static const String splashBg = "${SPLASH_BG_URL:-}";
  static const String splashBgUrl = "${SPLASH_BG_URL:-}";
  static const String splashBgColor = "${SPLASH_BG_COLOR:-#FFFFFF}";
  static const String splashTagline = "${SPLASH_TAGLINE:-}";
  static const String splashTaglineColor = "${SPLASH_TAGLINE_COLOR:-#000000}";
  static const String splashTaglineFont = "${SPLASH_TAGLINE_FONT:-DM Sans}";
  static const String splashTaglineSize = "${SPLASH_TAGLINE_SIZE:-14.0}";
  static const bool splashTaglineBold = ${SPLASH_TAGLINE_BOLD:-false};
  static const bool splashTaglineItalic = ${SPLASH_TAGLINE_ITALIC:-false};
  static const String splashAnimation = "${SPLASH_ANIMATION:-none}";
  static const int splashDuration = ${SPLASH_DURATION:-3};

  // Bottom Menu Configuration
  static const String bottommenuItems = """${BOTTOMMENU_ITEMS:-[]}""";
  static const String bottommenuBgColor = "${BOTTOMMENU_BG_COLOR:-#FFFFFF}";
  static const String bottommenuIconColor = "${BOTTOMMENU_ICON_COLOR:-#000000}";
  static const String bottommenuTextColor = "${BOTTOMMENU_TEXT_COLOR:-#000000}";
  static const String bottommenuFont = "${BOTTOMMENU_FONT:-DM Sans}";
  static const double bottommenuFontSize = ${BOTTOMMENU_FONT_SIZE:-14.0};
  static const bool bottommenuFontBold = ${BOTTOMMENU_FONT_BOLD:-false};
  static const bool bottommenuFontItalic = ${BOTTOMMENU_FONT_ITALIC:-false};
  static const String bottommenuActiveTabColor = "${BOTTOMMENU_ACTIVE_TAB_COLOR:-#0000FF}";
  static const String bottommenuIconPosition = "${BOTTOMMENU_ICON_POSITION:-top}";
  static const String bottommenuVisibleOn = "${BOTTOMMENU_VISIBLE_ON:-}";

  // Firebase Configuration
  static const String firebaseConfigAndroid = "${FIREBASE_CONFIG_ANDROID:-}";
  static const String firebaseConfigIos = "${FIREBASE_CONFIG_IOS:-}";

  // Firebase Status Helpers
  static bool get hasFirebaseConfig => firebaseConfigAndroid.isNotEmpty || firebaseConfigIos.isNotEmpty;
  static bool get isFirebaseRequired => ${PUSH_NOTIFY:-false};
  static bool get shouldInitializeFirebase => isFirebaseRequired && hasFirebaseConfig;

  // Android Signing
  static const String keyStoreUrl = "${KEY_STORE_URL:-}";
  static const String cmKeystorePassword = "${CM_KEYSTORE_PASSWORD:-}";
  static const String cmKeyAlias = "${CM_KEY_ALIAS:-}";
  static const String cmKeyPassword = "${CM_KEY_PASSWORD:-}";

  // iOS Signing
  static const String appleTeamId = "${APPLE_TEAM_ID:-}";
  static const String apnsKeyId = "${APNS_KEY_ID:-}";
  static const String apnsAuthKeyUrl = "${APNS_AUTH_KEY_URL:-}";
  static const String certPassword = "${CERT_PASSWORD:-}";
  static const String profileUrl = "${PROFILE_URL:-}";
  static const String certP12Url = "${CERT_P12_URL:-}";
  static const String certCerUrl = "${CERT_CER_URL:-}";
  static const String certKeyUrl = "${CERT_KEY_URL:-}";
  static const String profileType = "${PROFILE_TYPE:-app-store}";
  static const String appStoreConnectKeyIdentifier = "${APP_STORE_CONNECT_KEY_IDENTIFIER:-}";

  // Build Environment
  static const String buildId = "${CM_BUILD_ID:-unknown}";
  static const String buildDir = "${CM_BUILD_DIR:-}";
  static const String projectRoot = "${PROJECT_ROOT:-}";
  static const String outputDir = "${OUTPUT_DIR:-output}";

  // Utility Methods
  static bool get isAndroidBuild => true;
  static bool get isIosBuild => true;
  static bool get isCombinedBuild => true;
  static bool get hasFirebase => firebaseConfigAndroid.isNotEmpty || firebaseConfigIos.isNotEmpty;
  static bool get hasKeystore => keyStoreUrl.isNotEmpty;
  static bool get hasIosSigning => certPassword.isNotEmpty && profileUrl.isNotEmpty;
}
EOF
}

# Main execution function
generate_env_config() {
    log "🚀 Starting enhanced environment configuration generation..."

    # Test network connectivity
    test_network_connectivity

    # Validate environment
    validate_environment

    # Generate environment config with enhanced error handling
    log "📝 Generating Dart environment configuration (lib/config/env_config.dart)..."

    # Debug: Show current environment variables
    log "🔍 Current environment variables:"
    log "   APP_NAME: ${APP_NAME:-not_set}"
    log "   PKG_NAME: ${PKG_NAME:-not_set}"
    log "   WORKFLOW_ID: ${WORKFLOW_ID:-not_set}"

    # Create the directory if it doesn't exist
    mkdir -p lib/config
    
    # Backup existing file if it exists
    if [ -f "lib/config/env_config.dart" ]; then
        cp lib/config/env_config.dart lib/config/env_config.dart.backup
        log "📋 Backed up existing env_config.dart"
    fi

    # Generate workflow-specific configuration
    local workflow_id="${WORKFLOW_ID:-unknown}"
    
    case "$workflow_id" in
        android-*)
            log "📱 Android workflow detected, generating Android-specific config"
            generate_android_env_config
            ;;
        ios-*)
            log "🍎 iOS workflow detected, generating iOS-specific config"
            generate_ios_env_config
            ;;
        combined)
            log "🔄 Combined workflow detected, generating combined config"
            generate_combined_env_config
            ;;
        *)
            log "⚠️  Unknown workflow '$workflow_id', generating Android config as fallback"
            generate_android_env_config
            ;;
    esac

    log "✅ Dart environment configuration generated successfully."
    
    # Show first few lines of generated file for verification
    log "🔍 Generated file preview:"
    head -20 lib/config/env_config.dart | while IFS= read -r line; do
        log "   $line"
    done

    # Validate generated config
    if [ -f "lib/config/env_config.dart" ]; then
        log "✅ Environment configuration generated successfully"
        
        # Check if config is valid Dart
        if command -v dart >/dev/null 2>&1; then
            if dart analyze lib/config/env_config.dart >/dev/null 2>&1; then
                log "✅ Generated config passes Dart analysis"
            else
                log "⚠️  Generated config has Dart analysis issues"
            fi
        fi
        
        # Show config summary
        log "📋 Configuration Summary:"
        log "   App: ${APP_NAME:-QuikApp} v${VERSION_NAME:-1.0.0}"
        log "   Workflow: ${WORKFLOW_ID:-unknown}"
        log "   Platform: $([ "$workflow_id" = "android-"* ] && echo "Android" || echo "iOS")"
        log "   Firebase: ${PUSH_NOTIFY:-false}"
        log "   Keystore: ${KEY_STORE_URL:+true}"
        log "   iOS Signing: ${CERT_PASSWORD:+true}"
        
    else
        log "❌ Failed to generate environment configuration"
        
        # Restore backup if available
        if [ -f "lib/config/env_config.dart.backup" ]; then
            cp lib/config/env_config.dart.backup lib/config/env_config.dart
            log "✅ Restored backup configuration"
        fi
        
        return 1
    fi

    log "🎉 Enhanced environment configuration generation completed"
    return 0
}

# Run the function if script is called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    generate_env_config
    exit $?
fi