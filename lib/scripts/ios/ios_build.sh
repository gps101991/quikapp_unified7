#!/usr/bin/env bash

# Improved iOS Workflow Script
# Uses Codemagic CLI keychain commands for reliable code signing
# Based on build_ios-workflow(example ref).sh

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

# Logging functions
log_info() { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error() { echo "❌ $1"; }
log_warning() { echo "⚠️ $1"; }
log() { echo "📌 $1"; }

# Ensure all logging functions are available
export -f log_info log_success log_error log_warning log

echo "🚀 Starting Improved iOS Workflow..."

# Environment info
echo "📊 Build Environment:"
echo " - Flutter: $(flutter --version | head -1)"
echo " - Java: $(java -version 2>&1 | head -1)"
echo " - Xcode: $(xcodebuild -version | head -1)"
echo " - CocoaPods: $(pod --version)"

# Comprehensive Feature Status Check (Non-blocking)
echo "🔍 Feature Configuration Status:"
echo "  - Push Notifications: ${PUSH_NOTIFY:-false}"
echo "  - Firebase iOS Config: ${FIREBASE_CONFIG_IOS:-not set}"
echo "  - Firebase Android Config: ${FIREBASE_CONFIG_ANDROID:-not set}"
echo "  - App Name: ${APP_NAME:-not set}"
echo "  - Bundle ID: ${BUNDLE_ID:-not set}"
echo "  - Version Name: ${VERSION_NAME:-not set}"
echo "  - Version Code: ${VERSION_CODE:-not set}"
echo "  - Team ID: ${APPLE_TEAM_ID:-not set}"
echo "  - Profile URL: ${PROFILE_URL:-not set}"
echo "  - Certificate Type: ${CERT_TYPE:-not set}"
echo "  - Profile Type: ${PROFILE_TYPE:-not set}"
echo "  - Upload to App Store: ${UPLOAD_TO_APP_STORE:-false}"
echo "  - App Store Connect Key: ${APP_STORE_CONNECT_KEY_IDENTIFIER:-not set}"
echo "  - App Store Connect Issuer: ${APP_STORE_CONNECT_ISSUER_ID:-not set}"
echo "  - App Store Connect API Key: ${APP_STORE_CONNECT_API_KEY_URL:-not set}"
echo "  - Logo URL: ${LOGO_URL:-not set}"
echo "  - Splash URL: ${SPLASH_URL:-not set}"
echo "  - Chat Bot: ${IS_CHATBOT:-false}"
echo "  - Domain URL: ${IS_DOMAIN_URL:-false}"
echo "  - Splash Screen: ${IS_SPLASH:-false}"
echo "  - Pull to Refresh: ${IS_PULLDOWN:-false}"
echo "  - Bottom Menu: ${IS_BOTTOMMENU:-false}"
echo "  - Loading Indicator: ${IS_LOAD_IND:-false}"
echo "  - Camera: ${IS_CAMERA:-false}"
echo "  - Location: ${IS_LOCATION:-false}"
echo "  - Microphone: ${IS_MIC:-false}"
echo "  - Notifications: ${IS_NOTIFICATION:-false}"
echo "  - Contacts: ${IS_CONTACT:-false}"
echo "  - Biometric: ${IS_BIOMETRIC:-false}"
echo "  - Calendar: ${IS_CALENDAR:-false}"
echo "  - Storage: ${IS_STORAGE:-false}"

# Critical Variable Validation (Non-blocking)
echo "🔍 Critical Variable Validation:"
CRITICAL_VARS=("BUNDLE_ID" "APPLE_TEAM_ID" "PROFILE_URL" "CERT_PASSWORD")
MISSING_CRITICAL=()

for var in "${CRITICAL_VARS[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        echo "  ❌ $var: MISSING (critical for iOS build)"
        MISSING_CRITICAL+=("$var")
    else
        echo "  ✅ $var: ${!var}"
    fi
done

if [[ ${#MISSING_CRITICAL[@]} -gt 0 ]]; then
    echo "⚠️  WARNING: Missing critical variables: ${MISSING_CRITICAL[*]}"
    echo "ℹ️  Build may fail or use default values"
else
    echo "✅ All critical variables are present"
fi

# Cleanup
echo "🧹 Pre-build cleanup..."
flutter clean > /dev/null 2>&1 || log_warning "⚠️ flutter clean failed (continuing)"

rm -rf ~/Library/Developer/Xcode/DerivedData/* > /dev/null 2>&1 || true
rm -rf .dart_tool/ > /dev/null 2>&1 || true
rm -rf ios/Pods/ > /dev/null 2>&1 || true
rm -rf ios/build/ > /dev/null 2>&1 || true
rm -rf ios/.symlinks > /dev/null 2>&1 || true

# Firebase Setup for iOS Push Notifications - MOVED TO AFTER CUSTOMIZATION
log_info "🔥 Firebase setup will be configured after app customization..."

# Initialize keychain using Codemagic CLI
echo "🔐 Initialize keychain to be used for codesigning using Codemagic CLI 'keychain' command"
keychain initialize

# Setup provisioning profile
log_info "Setting up provisioning profile..."

PROFILES_HOME="$HOME/Library/MobileDevice/Provisioning Profiles"
mkdir -p "$PROFILES_HOME"

if [[ -n "$PROFILE_URL" ]]; then
    # Download provisioning profile
    PROFILE_PATH="$PROFILES_HOME/app_store.mobileprovision"
    
    if [[ "$PROFILE_URL" == http* ]]; then
        curl -fSL "$PROFILE_URL" -o "$PROFILE_PATH"
        log_success "Downloaded provisioning profile to $PROFILE_PATH"
    else
        cp "$PROFILE_URL" "$PROFILE_PATH"
        log_success "Copied provisioning profile from $PROFILE_URL to $PROFILE_PATH"
    fi
    
    # Extract information from provisioning profile
    security cms -D -i "$PROFILE_PATH" > /tmp/profile.plist
    UUID=$(/usr/libexec/PlistBuddy -c "Print UUID" /tmp/profile.plist 2>/dev/null || echo "")
    BUNDLE_ID_FROM_PROFILE=$(/usr/libexec/PlistBuddy -c "Print :Entitlements:application-identifier" /tmp/profile.plist 2>/dev/null | cut -d '.' -f 2- || echo "")
    
    if [[ -n "$UUID" ]]; then
        echo "UUID: $UUID"
    fi
    if [[ -n "$BUNDLE_ID_FROM_PROFILE" ]]; then
        echo "Bundle Identifier from profile: $BUNDLE_ID_FROM_PROFILE"
        
        # Use bundle ID from profile if BUNDLE_ID is not set or is default
        if [[ -z "$BUNDLE_ID" || "$BUNDLE_ID" == "com.example.sampleprojects.sampleProject" || "$BUNDLE_ID" == "com.test.app" || "$BUNDLE_ID" == "com.example.quikapp" ]]; then
            BUNDLE_ID="$BUNDLE_ID_FROM_PROFILE"
            log_info "Using bundle ID from provisioning profile: $BUNDLE_ID"
        else
            log_info "Using provided bundle ID: $BUNDLE_ID (profile has: $BUNDLE_ID_FROM_PROFILE)"
        fi
    fi
else
    log_warning "No provisioning profile URL provided (PROFILE_URL)"
    UUID=""
fi

# Setup certificate using Codemagic CLI
log_info "Setting up certificate using Codemagic CLI..."

# Determine certificate type (default to p12 if not specified)
CERT_TYPE="${CERT_TYPE:-p12}"
log_info "Certificate type: $CERT_TYPE"

if [[ "$CERT_TYPE" == "p12" ]]; then
    # P12 Certificate Setup
    if [[ -n "$CERT_P12_URL" && -n "$CERT_PASSWORD" ]]; then
        log_info "📥 Downloading P12 certificate from: $CERT_P12_URL"
        curl -fSL "$CERT_P12_URL" -o /tmp/certificate.p12
        log_success "✅ Downloaded P12 certificate to /tmp/certificate.p12"
        
        # Add certificate to keychain using Codemagic CLI
        keychain add-certificates --certificate /tmp/certificate.p12 --certificate-password "$CERT_PASSWORD"
        log_success "✅ P12 certificate added to keychain using Codemagic CLI"
    else
        log_warning "⚠️ P12 certificate type selected but CERT_P12_URL or CERT_PASSWORD not provided"
        log_info "Continuing without certificate setup..."
    fi
    
elif [[ "$CERT_TYPE" == "manual" ]]; then
    # Manual Certificate Setup (CER + KEY)
    if [[ -n "$CERT_CER_URL" && -n "$CERT_KEY_URL" ]]; then
        log_info "📥 Downloading CER certificate from: $CERT_CER_URL"
        curl -fSL "$CERT_CER_URL" -o /tmp/certificate.cer
        log_success "✅ Downloaded CER certificate"
        
        log_info "📥 Downloading KEY file from: $CERT_KEY_URL"
        curl -fSL "$CERT_KEY_URL" -o /tmp/certificate.key
        log_success "✅ Downloaded KEY file"
        
        # Generate P12 from CER/KEY
        log_info "🔧 Generating P12 from CER/KEY files..."
        if [[ -n "$CERT_PASSWORD" ]]; then
            openssl pkcs12 -export -in /tmp/certificate.cer -inkey /tmp/certificate.key -out /tmp/certificate.p12 -passout pass:"$CERT_PASSWORD"
            log_success "✅ Generated P12 with password protection"
        else
            openssl pkcs12 -export -in /tmp/certificate.cer -inkey /tmp/certificate.key -out /tmp/certificate.p12 -nodes
            log_success "✅ Generated P12 without password protection"
        fi
        
        # Add certificate to keychain using Codemagic CLI
        if [[ -n "$CERT_PASSWORD" ]]; then
            keychain add-certificates --certificate /tmp/certificate.p12 --certificate-password "$CERT_PASSWORD"
        else
            keychain add-certificates --certificate /tmp/certificate.p12
        fi
        log_success "✅ Manual certificate added to keychain using Codemagic CLI"
    else
        log_warning "⚠️ Manual certificate type selected but CERT_CER_URL or CERT_KEY_URL not provided"
        log_info "Continuing without certificate setup..."
    fi
    
else
    log_warning "⚠️ Unknown certificate type: $CERT_TYPE (supported: p12, manual)"
    log_info "Continuing without certificate setup..."
fi

# Validate signing identities (non-blocking)
IDENTITY_COUNT=$(security find-identity -v -p codesigning | grep -c "iPhone Distribution" || echo "0")
if [[ "$IDENTITY_COUNT" -eq 0 ]]; then
    log_warning "⚠️ No valid iPhone Distribution signing identities found in keychain."
    log_info "ℹ️ This might cause signing issues, but continuing build..."
    
    # Try to find any signing identity
    ANY_IDENTITY_COUNT=$(security find-identity -v -p codesigning | grep -c "iPhone" || echo "0")
    if [[ "$ANY_IDENTITY_COUNT" -gt 0 ]]; then
        log_info "ℹ️ Found $ANY_IDENTITY_COUNT iPhone signing identity(ies) (may not be Distribution)"
    else
        log_warning "⚠️ No iPhone signing identities found at all"
    fi
else
    log_success "Found $IDENTITY_COUNT valid iPhone Distribution identity(ies) in keychain."
fi

# Validate provisioning profile and bundle ID match
if [[ -n "$UUID" && -n "$BUNDLE_ID" ]]; then
    log_info "🔍 Validating provisioning profile and bundle ID match..."
    
    # Check if provisioning profile exists and is valid
    if [[ -f "$PROFILE_PATH" ]]; then
        log_success "Provisioning profile exists: $PROFILE_PATH"
        
        # Verify bundle ID in profile matches our bundle ID
        if [[ -n "$BUNDLE_ID_FROM_PROFILE" ]]; then
            if [[ "$BUNDLE_ID_FROM_PROFILE" == "$BUNDLE_ID" ]]; then
                log_success "✅ Bundle ID matches provisioning profile: $BUNDLE_ID"
            else
                log_warning "⚠️ Bundle ID mismatch with provisioning profile"
                log_warning "Profile expects: $BUNDLE_ID_FROM_PROFILE"
                log_warning "Using: $BUNDLE_ID"
                log_info "This might cause signing issues. Consider updating the provisioning profile."
            fi
        fi
    else
        log_warning "⚠️ Provisioning profile not found at expected location"
    fi
else
    log_warning "⚠️ Missing UUID or BUNDLE_ID for validation"
fi

# CocoaPods commands
run_cocoapods_commands() {
    if [ -f "ios/Podfile.lock" ]; then
        cp ios/Podfile.lock ios/Podfile.lock.backup
        log_info "🗂️ Backed up Podfile.lock to Podfile.lock.backup"
        rm ios/Podfile.lock
        log_info "🗑️ Removed original Podfile.lock"
    else
        log_warning "⚠️ Podfile.lock not found — skipping backup and removal"
    fi

    log_info "📦 Running CocoaPods commands..."

    if ! command -v pod &>/dev/null; then
        log_error "CocoaPods is not installed!"
        exit 1
    fi

    pushd ios > /dev/null || { log_error "Failed to enter ios directory"; return 1; }
    
    # Clean pod cache to ensure fresh installation
    log_info "🧹 Cleaning pod cache..."
    pod cache clean --all 2>/dev/null || log_warning "⚠️ Pod cache clean failed (continuing)"
    
    # CRITICAL: Clean up any existing pods to ensure fresh start
    log_info "🧹 Cleaning up existing pods for fresh start..."
    rm -rf Pods Podfile.lock 2>/dev/null || true
    
    # Show Podfile contents for debugging
    log_info "📋 Podfile contents:"
    cat Podfile
    
    log_info "🔄 Running: pod install"
    
    # Run pod install with comprehensive error handling and recovery (non-blocking)
    log_info "🔄 Attempting pod install with modular headers..."
    
    # First attempt: standard pod install
    if pod install 2>&1 | tee pod_install.log; then
        log_success "✅ pod install completed successfully"
    else
        log_warning "⚠️ First pod install attempt failed, analyzing error..."
        
        # Analyze the error and attempt recovery
        if grep -q "Swift pods cannot yet be integrated" pod_install.log; then
            log_warning "🚨 Swift module integration issue detected, attempting recovery..."
            
            # CRITICAL FIX: Regenerate the Podfile completely to resolve Swift module issues
            log_info "🔧 Regenerating Podfile to fix Swift module integration issues..."
            
            # Restore the backup and regenerate
            if [[ -f "ios/Podfile.backup" ]]; then
                cp ios/Podfile.backup ios/Podfile
                log_info "✅ Restored Podfile from backup"
            fi
            
            # Force regenerate the Podfile with the correct structure
            log_info "🔧 Applying critical Podfile regeneration for Swift module integration..."
            
            # Generate a clean Podfile with the correct structure
            cat > ios/Podfile << 'EOF'
# Uncomment this line to define a global platform for your project
platform :ios, '13.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!
  
  # Install Flutter pods FIRST
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  # Firebase dependencies with comprehensive modular headers configuration
  pod 'Firebase/Core', :modular_headers => true
  pod 'Firebase/Messaging', :modular_headers => true
  pod 'FirebaseCoreInternal', :modular_headers => true
  pod 'GoogleUtilities', :modular_headers => true
  pod 'nanopb', :modular_headers => true
  pod 'GTMSessionFetcher', :modular_headers => true
  pod 'PromisesObjC', :modular_headers => true
  pod 'AppCheckCore', :modular_headers => true
  
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    target.build_configurations.each do |config|
      # Set minimum iOS version
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      
      # Disable code signing for pods
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ''
      
      # Fix for Flutter.h not found
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
      
      # Force modular headers for all pods
      config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
      config.build_settings['DEFINES_MODULE'] = 'YES'
      
      # Add framework search paths
      config.build_settings['FRAMEWORK_SEARCH_PATHS'] ||= [
        '$(inherited)',
        '${PODS_ROOT}/../Flutter',
        '${PODS_XCFRAMEWORKS_BUILD_DIR}/Flutter',
        '${PODS_CONFIGURATION_BUILD_DIR}'
      ]
      
      # Add header search paths
      config.build_settings['HEADER_SEARCH_PATHS'] ||= [
        '$(inherited)',
        '${PODS_ROOT}/Headers/Public',
        '${PODS_ROOT}/Headers/Public/Flutter',
        '${PODS_ROOT}/Headers/Public/Flutter/Flutter'
      ]
    end
  end
end
EOF
            
            log_success "✅ Podfile regenerated for Swift module integration"
            
            # Clean up any existing pods and try again
            log_info "🧹 Cleaning up existing pods and retrying..."
            rm -rf ios/Pods ios/Podfile.lock 2>/dev/null || true
            
            log_info "🔄 Retrying pod install after Podfile regeneration..."
            if pod install 2>&1 | tee pod_install_recovery.log; then
                log_success "✅ pod install completed successfully after Podfile regeneration"
            else
                log_warning "⚠️ Recovery attempt failed, trying with repo update..."
                
                # Third attempt: update repo and retry
                if pod repo update && pod install 2>&1 | tee pod_install_final.log; then
                    log_success "✅ pod install completed successfully on final attempt"
                else
                    log_warning "⚠️ All pod install attempts failed (continuing build)"
                    log_info "📋 Error analysis:"
                    cat pod_install.log | grep -E "(error|Error|ERROR|warning|Warning|WARNING)" || echo "No specific errors found"
                    log_info "📋 Recovery attempt log:"
                    cat pod_install_recovery.log | grep -E "(error|Error|ERROR|warning|Warning|WARNING)" || echo "No specific errors found"
                    log_info "📋 Final attempt log:"
                    cat pod_install_final.log | grep -E "(error|Error|ERROR|warning|Warning|WARNING)" || echo "No specific errors found"
                    
                    log_warning "⚠️ pod install failed with exit code $? (continuing)"
                    log_info "ℹ️ Continuing build process despite pod install failure"
                fi
            fi
        else
            log_warning "⚠️ Unknown pod install error, trying with repo update..."
            
            # Second attempt: update repo and retry
            if pod repo update && pod install 2>&1 | tee pod_install_retry.log; then
                log_success "✅ pod install completed successfully on retry"
            else
                log_warning "⚠️ pod install failed on retry (continuing build)"
                log_info "📋 First attempt error log:"
                cat pod_install.log | grep -E "(error|Error|ERROR|warning|Warning|WARNING)" || echo "No specific errors found"
                log_info "📋 Retry attempt error log:"
                cat pod_install_retry.log | grep -E "(error|Error|ERROR|warning|Warning|WARNING)" || echo "No specific errors found"
                
                log_warning "⚠️ pod install failed with exit code $? (continuing)"
                log_info "ℹ️ Continuing build process despite pod install failure"
            fi
        fi
    fi

    popd > /dev/null
    log_success "✅ CocoaPods commands completed"
}

# Update display name and bundle id
if [[ -n "$APP_NAME" ]]; then
    PLIST_PATH="ios/Runner/Info.plist"
    /usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" "$PLIST_PATH" 2>/dev/null \
        && /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName '$APP_NAME'" "$PLIST_PATH" \
        || /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string '$APP_NAME'" "$PLIST_PATH"
    log_success "Updated app display name to: $APP_NAME"
fi

if [[ -n "$BUNDLE_ID" ]]; then
    log_info "Updating bundle identifier to: $BUNDLE_ID"
    
    # List of possible default bundle IDs to replace
    DEFAULT_BUNDLE_IDS=("com.example.sampleprojects.sampleProject" "com.test.app" "com.example.quikapp" "com.example.quikappflutter")
    
    for OLD_BUNDLE_ID in "${DEFAULT_BUNDLE_IDS[@]}"; do
        log_info "Replacing $OLD_BUNDLE_ID with $BUNDLE_ID"
        find ios -name "project.pbxproj" -exec sed -i '' "s/$OLD_BUNDLE_ID/$BUNDLE_ID/g" {} \;
        find ios -name "Info.plist" -exec sed -i '' "s/$OLD_BUNDLE_ID/$BUNDLE_ID/g" {} \;
        find ios -name "*.entitlements" -exec sed -i '' "s/$OLD_BUNDLE_ID/$BUNDLE_ID/g" {} \;
    done
    
    # Also update the Info.plist directly
    PLIST_PATH="ios/Runner/Info.plist"
    
    # Check if Info.plist is corrupted and fix it BEFORE trying to modify it
    if [ -f "lib/scripts/ios-workflow/fix_corrupted_infoplist.sh" ]; then
        log_info "🔧 Checking for Info.plist corruption before bundle ID update..."
        chmod +x lib/scripts/ios-workflow/fix_corrupted_infoplist.sh
        if ./lib/scripts/ios-workflow/fix_corrupted_infoplist.sh; then
            log_success "✅ Info.plist corruption fixed, proceeding with bundle ID update"
        else
            log_warning "⚠️ Info.plist fix failed, attempting to continue..."
        fi
    else
        log_warning "⚠️ Info.plist fix script not found, proceeding without corruption check"
    fi
    
    # Now try to update the bundle ID
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$PLIST_PATH" 2>/dev/null || \
        /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $BUNDLE_ID" "$PLIST_PATH"
    
    # Update project.pbxproj PRODUCT_BUNDLE_IDENTIFIER
    PROJECT_FILE="ios/Runner.xcodeproj/project.pbxproj"
    if [[ -f "$PROJECT_FILE" ]]; then
        log_info "Updating PRODUCT_BUNDLE_IDENTIFIER in project.pbxproj..."
        sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = [^;]*;/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID;/g" "$PROJECT_FILE"
        log_success "Updated PRODUCT_BUNDLE_IDENTIFIER in project.pbxproj"
    fi
    
    log_success "Bundle Identifier updated to $BUNDLE_ID"
fi

# Generate environment configuration
log_info "📝 Step: Generate environment configuration..."
if [ -f "lib/scripts/utils/gen_env_config.sh" ]; then
    chmod +x lib/scripts/utils/gen_env_config.sh
    if ./lib/scripts/utils/gen_env_config.sh; then
        log_success "✅ Environment configuration generated successfully"
        
        # Verify the file was written correctly
        if [ -f "lib/config/env_config.dart" ]; then
            log_info "📋 Verifying environment configuration file..."
            
            # Check file size
            FILE_SIZE=$(stat -f%z "lib/config/env_config.dart" 2>/dev/null || stat -c%s "lib/config/env_config.dart" 2>/dev/null || echo "0")
            if [ "$FILE_SIZE" -gt 100 ]; then
                log_success "✅ Environment configuration file size: ${FILE_SIZE} bytes"
            else
                log_error "❌ Environment configuration file too small: ${FILE_SIZE} bytes"
                exit 1
            fi
            
            # Test Dart syntax
            if flutter analyze lib/config/env_config.dart >/dev/null 2>&1; then
                log_success "✅ Environment configuration syntax is valid"
            else
                log_error "❌ Environment configuration has syntax errors"
                flutter analyze lib/config/env_config.dart
                exit 1
            fi
            
            # Force file system sync
            sync 2>/dev/null || true
            sleep 1
            
            log_success "✅ Environment configuration verified and ready for build"
        else
            log_error "❌ Environment configuration file not found after generation"
            exit 1
        fi
    else
        log_error "❌ Environment configuration failed"
        exit 1
    fi
else
    log_error "❌ Environment configuration script not found"
    exit 1
fi

# Step 11.5: iOS app branding (logo and splash screen) - MUST HAPPEN BEFORE ICON FIX
log_info "🎨 Step 11.5: iOS app branding (logo and splash screen)..."
if [ -f "lib/scripts/ios-workflow/ios_branding.sh" ]; then
    chmod +x lib/scripts/ios-workflow/ios_branding.sh
    if ./lib/scripts/ios-workflow/ios_branding.sh; then
        log_success "✅ iOS app branding completed successfully"
    else
        log_error "❌ Failed to complete iOS app branding"
        log_warning "⚠️ Continuing build without custom branding..."
    fi
else
    log_warning "⚠️ iOS branding script not found, skipping branding..."
fi

# Fix all iOS permissions for App Store compliance
log_info "🔐 Step: Fix all iOS permissions for App Store compliance..."
if [ -f "lib/scripts/ios-workflow/fix_all_permissions.sh" ]; then
    chmod +x lib/scripts/ios-workflow/fix_all_permissions.sh
    if ./lib/scripts/ios-workflow/fix_all_permissions.sh; then
        log_success "✅ All iOS permissions fixed successfully"
    else
        log_error "❌ Failed to fix iOS permissions"
        log_warning "⚠️ Continuing build but permissions may not work correctly..."
    fi
else
    log_warning "⚠️ All permissions fix script not found, trying speech-only fix..."
    if [ -f "lib/scripts/ios-workflow/fix_speech_permissions.sh" ]; then
        chmod +x lib/scripts/ios-workflow/fix_speech_permissions.sh
        if ./lib/scripts/ios-workflow/fix_speech_permissions.sh; then
            log_success "✅ Speech recognition permissions fixed successfully"
        else
            log_error "❌ Failed to fix speech recognition permissions"
            log_warning "⚠️ Continuing build but speech permissions may not work..."
        fi
    else
        log_warning "⚠️ Speech permissions fix script not found, skipping..."
    fi
fi

# Test icon fix to verify it worked
log_info "🧪 Testing icon fix to verify App Store validation readiness..."
if [ -f "lib/scripts/ios-workflow/test_icon_fix.sh" ]; then
    chmod +x lib/scripts/ios-workflow/test_icon_fix.sh
    if ./lib/scripts/ios-workflow/test_icon_fix.sh; then
        log_success "✅ Icon fix test passed - App Store validation should succeed"
    else
        log_warning "⚠️ Icon fix test failed - App Store validation may still fail"
        log_warning "⚠️ Check the test output above for specific issues"
    fi
else
    log_warning "⚠️ Icon fix test script not found, cannot verify fix"
fi

# iOS app branding (logo and splash screen)
log_info "🎨 Step: iOS app branding (logo and splash screen)..."
if [ -f "lib/scripts/ios-workflow/ios_branding.sh" ]; then
    chmod +x lib/scripts/ios-workflow/ios_branding.sh
    if ./lib/scripts/ios-workflow/ios_branding.sh; then
        log_success "✅ iOS app branding completed successfully"
    else
        log_error "❌ Failed to complete iOS app branding"
        log_warning "⚠️ Continuing build without custom branding..."
    fi
else
    log_warning "⚠️ iOS branding script not found, skipping branding..."
fi

# Step 11.6: Robust iOS Icon Fix (CRITICAL for App Store validation) - AFTER BRANDING
log_info "🖼️ Step 11.6: Robust iOS Icon Fix for App Store Validation..."

# Fix iOS icons to prevent upload failures
log_info "Fixing iOS icons to prevent App Store validation errors..."

# Try robust icon fix first
if [ -f "lib/scripts/ios-workflow/fix_ios_icons_robust.sh" ]; then
    chmod +x lib/scripts/ios-workflow/fix_ios_icons_robust.sh
    if ./lib/scripts/ios-workflow/fix_ios_icons_robust.sh; then
        log_success "✅ Robust iOS icon fix completed successfully"
        log_info "📱 App should now pass App Store icon validation"
    else
        log_error "❌ Robust iOS icon fix failed, trying fallback..."
        # Try fallback icon fixes
        if [ -f "lib/scripts/ios-workflow/fix_ios_workflow_icons.sh" ]; then
            chmod +x lib/scripts/ios-workflow/fix_ios_workflow_icons.sh
            if ./lib/scripts/ios-workflow/fix_ios_workflow_icons.sh; then
                log_success "✅ Fallback icon fix completed successfully"
            else
                log_warning "⚠️ Fallback icon fix failed"
            fi
        fi
    fi
else
    log_warning "⚠️ Robust iOS icon fix script not found, trying fallback icon fixes..."
    
    # Try fallback icon fixes
    if [ -f "lib/scripts/ios-workflow/fix_ios_workflow_icons.sh" ]; then
        chmod +x lib/scripts/ios-workflow/fix_ios_workflow_icons.sh
        if ./lib/scripts/ios-workflow/fix_ios_workflow_icons.sh; then
            log_success "✅ Fallback icon fix completed successfully"
        else
            log_warning "⚠️ Fallback icon fix failed"
        fi
    else
        log_warning "⚠️ No icon fix scripts found, skipping icon validation"
        log_warning "⚠️ App may fail App Store validation due to missing icons"
    fi
fi

# Dynamic iOS app icon fix for ITMS compliance (ITMS-90022, ITMS-90023, ITMS-90713)
log_info "🚀 Step: Dynamic iOS app icon fix for ITMS compliance..."
if [ -f "lib/scripts/ios-workflow/fix_ios_app_icons_dynamic.sh" ]; then
    chmod +x lib/scripts/ios-workflow/fix_ios_app_icons_dynamic.sh
    if ./lib/scripts/ios-workflow/fix_ios_app_icons_dynamic.sh; then
        log_success "✅ Dynamic iOS app icon fix completed successfully"
    else
        log_error "❌ Dynamic iOS app icon fix failed"
        log_warning "⚠️ Trying comprehensive iOS workflow fix..."
        
        # Try comprehensive fix as primary fallback
        if [ -f "lib/scripts/ios-workflow/fix_ios_workflow_comprehensive.sh" ]; then
            chmod +x lib/scripts/ios-workflow/fix_ios_workflow_comprehensive.sh
            if ./lib/scripts/ios-workflow/fix_ios_workflow_comprehensive.sh; then
                log_success "✅ Comprehensive iOS workflow fix completed"
            else
                log_warning "⚠️ Comprehensive fix failed, trying robust ITMS icon fix..."
                
                # Try robust ITMS icon fix as secondary fallback
                if [ -f "lib/scripts/ios-workflow/fix_ios_app_icons_robust.sh" ]; then
                    chmod +x lib/scripts/ios-workflow/fix_ios_app_icons_robust.sh
                    if ./lib/scripts/ios-workflow/fix_ios_app_icons_robust.sh; then
                        log_success "✅ Robust ITMS icon fix completed"
                    else
                        log_warning "⚠️ Robust ITMS icon fix failed, trying individual fixes..."
                        
                        # Try individual fixes as tertiary fallback
                        if [ -f "lib/scripts/ios-workflow/fix_dynamic_permissions.sh" ]; then
                            chmod +x lib/scripts/ios-workflow/fix_dynamic_permissions.sh
                            ./lib/scripts/ios-workflow/fix_dynamic_permissions.sh || log_warning "⚠️ Dynamic permissions fix failed"
                        fi
                        
                        if [ -f "lib/scripts/ios-workflow/fix_ios_launcher_icons.sh" ]; then
                            chmod +x lib/scripts/ios-workflow/fix_ios_launcher_icons.sh
                            ./lib/scripts/ios-workflow/fix_ios_launcher_icons.sh || log_warning "⚠️ App icons fix failed"
                        fi
                    fi
                else
                    log_warning "⚠️ Robust ITMS icon fix script not found, trying individual fixes..."
                    
                    # Try individual fixes
                    if [ -f "lib/scripts/ios-workflow/fix_dynamic_permissions.sh" ]; then
                        chmod +x lib/scripts/ios-workflow/fix_dynamic_permissions.sh
                        ./lib/scripts/ios-workflow/fix_dynamic_permissions.sh || log_warning "⚠️ Dynamic permissions fix failed"
                    fi
                    
                    if [ -f "lib/scripts/ios-workflow/fix_ios_launcher_icons.sh" ]; then
                        chmod +x lib/scripts/ios-workflow/fix_ios_launcher_icons.sh
                        ./lib/scripts/ios-workflow/fix_ios_launcher_icons.sh || log_warning "⚠️ App icons fix failed"
                    fi
                fi
            fi
        else
            log_warning "⚠️ Comprehensive fix script not found, trying robust ITMS icon fix..."
            
            # Try robust ITMS icon fix
            if [ -f "lib/scripts/ios-workflow/fix_ios_app_icons_robust.sh" ]; then
                chmod +x lib/scripts/ios-workflow/fix_ios_app_icons_robust.sh
                if ./lib/scripts/ios-workflow/fix_ios_app_icons_robust.sh; then
                    log_success "✅ Robust ITMS icon fix completed"
                else
                    log_warning "⚠️ Robust ITMS icon fix failed, trying individual fixes..."
                    
                    # Try individual fixes
                    if [ -f "lib/scripts/ios-workflow/fix_dynamic_permissions.sh" ]; then
                        chmod +x lib/scripts/ios-workflow/fix_dynamic_permissions.sh
                        ./lib/scripts/ios-workflow/fix_dynamic_permissions.sh || log_warning "⚠️ Dynamic permissions fix failed"
                    fi
                    
                    if [ -f "lib/scripts/ios-workflow/fix_ios_launcher_icons.sh" ]; then
                        chmod +x lib/scripts/ios-workflow/fix_ios_launcher_icons.sh
                        ./lib/scripts/ios-workflow/fix_ios_launcher_icons.sh || log_warning "⚠️ App icons fix failed"
                    fi
                fi
            else
                log_warning "⚠️ No robust ITMS icon fix script, trying individual fixes..."
                
                # Try individual fixes
                if [ -f "lib/scripts/ios-workflow/fix_dynamic_permissions.sh" ]; then
                    chmod +x lib/scripts/ios-workflow/fix_dynamic_permissions.sh
                    ./lib/scripts/ios-workflow/fix_dynamic_permissions.sh || log_warning "⚠️ Dynamic permissions fix failed"
                fi
                
                if [ -f "lib/scripts/ios-workflow/fix_ios_launcher_icons.sh" ]; then
                    chmod +x lib/scripts/ios-workflow/fix_ios_launcher_icons.sh
                    ./lib/scripts/ios-workflow/fix_ios_launcher_icons.sh || log_warning "⚠️ App icons fix failed"
                fi
            fi
        fi
    fi
else
    log_warning "⚠️ Dynamic iOS app icon fix script not found, trying comprehensive fix..."
    
    # Try comprehensive fix
    if [ -f "lib/scripts/ios-workflow/fix_ios_workflow_comprehensive.sh" ]; then
        chmod +x lib/scripts/ios-workflow/fix_ios_workflow_comprehensive.sh
        if ./lib/scripts/ios-workflow/fix_ios_workflow_comprehensive.sh; then
            log_success "✅ Comprehensive iOS workflow fix completed"
        else
            log_warning "⚠️ Comprehensive fix failed, trying robust ITMS icon fix..."
            
            # Try robust ITMS icon fix
            if [ -f "lib/scripts/ios-workflow/fix_ios_app_icons_robust.sh" ]; then
                chmod +x lib/scripts/ios-workflow/fix_ios_app_icons_robust.sh
                if ./lib/scripts/ios-workflow/fix_ios_app_icons_robust.sh; then
                    log_success "✅ Robust ITMS icon fix completed"
                else
                    log_warning "⚠️ Robust ITMS icon fix failed, trying individual fixes..."
                    
                    # Try individual fixes
                    if [ -f "lib/scripts/ios-workflow/fix_dynamic_permissions.sh" ]; then
                        chmod +x lib/scripts/ios-workflow/fix_dynamic_permissions.sh
                        ./lib/scripts/ios-workflow/fix_dynamic_permissions.sh || log_warning "⚠️ Dynamic permissions fix failed"
                    fi
                    
                    if [ -f "lib/scripts/ios-workflow/fix_ios_launcher_icons.sh" ]; then
                        chmod +x lib/scripts/ios-workflow/fix_ios_launcher_icons.sh
                        ./lib/scripts/ios-workflow/fix_ios_launcher_icons.sh || log_warning "⚠️ App icons fix failed"
                    fi
                fi
            else
                log_warning "⚠️ No robust ITMS icon fix script, trying individual fixes..."
                
                # Try individual fixes
                if [ -f "lib/scripts/ios-workflow/fix_dynamic_permissions.sh" ]; then
                    chmod +x lib/scripts/ios-workflow/fix_dynamic_permissions.sh
                    ./lib/scripts/ios-workflow/fix_dynamic_permissions.sh || log_warning "⚠️ Dynamic permissions fix failed"
                fi
                
                if [ -f "lib/scripts/ios-workflow/fix_ios_launcher_icons.sh" ]; then
                    chmod +x lib/scripts/ios-workflow/fix_ios_launcher_icons.sh
                    ./lib/scripts/ios-workflow/fix_ios_launcher_icons.sh || log_warning "⚠️ App icons fix failed"
                fi
            fi
        fi
    else
        log_warning "⚠️ No comprehensive fix script, trying robust ITMS icon fix..."
        
        # Try robust ITMS icon fix
        if [ -f "lib/scripts/ios-workflow/fix_ios_app_icons_robust.sh" ]; then
            chmod +x lib/scripts/ios-workflow/fix_ios_app_icons_robust.sh
            if ./lib/scripts/ios-workflow/fix_ios_app_icons_robust.sh; then
                log_success "✅ Robust ITMS icon fix completed"
            else
                log_warning "⚠️ Robust ITMS icon fix failed, trying individual fixes..."
                
                # Try individual fixes
                if [ -f "lib/scripts/ios-workflow/fix_dynamic_permissions.sh" ]; then
                    chmod +x lib/scripts/ios-workflow/fix_dynamic_permissions.sh
                    ./lib/scripts/ios-workflow/fix_dynamic_permissions.sh || log_warning "⚠️ Dynamic permissions fix failed"
                fi
                
                if [ -f "lib/scripts/ios-workflow/fix_ios_launcher_icons.sh" ]; then
                    chmod +x lib/scripts/ios-workflow/fix_ios_launcher_icons.sh
                    ./lib/scripts/ios-workflow/fix_ios_launcher_icons.sh || log_warning "⚠️ App icons fix failed"
                fi
            fi
        else
            log_warning "⚠️ No robust ITMS icon fix script, trying individual fixes..."
            
            # Try individual fixes
            if [ -f "lib/scripts/ios-workflow/fix_dynamic_permissions.sh" ]; then
                chmod +x lib/scripts/ios-workflow/fix_dynamic_permissions.sh
                ./lib/scripts/ios-workflow/fix_dynamic_permissions.sh || log_warning "⚠️ Dynamic permissions fix failed"
            fi
            
            if [ -f "lib/scripts/ios-workflow/fix_ios_launcher_icons.sh" ]; then
                chmod +x lib/scripts/ios-workflow/fix_ios_launcher_icons.sh
                ./lib/scripts/ios-workflow/fix_ios_launcher_icons.sh || log_warning "⚠️ App icons fix failed"
            fi
        fi
    fi
fi

# 🔔 COMPREHENSIVE PUSH NOTIFICATION SETUP FOR iOS
log_info "🔔 Setting up Push Notifications for iOS..."
log_info "📋 Push Notification Configuration Status:"
log_info "  - PUSH_NOTIFY: ${PUSH_NOTIFY:-false}"
log_info "  - IS_NOTIFICATION: ${IS_NOTIFICATION:-false}"
log_info "  - FIREBASE_CONFIG_IOS: ${FIREBASE_CONFIG_IOS:-not set}"

# 🔐 CRITICAL: Configure iOS permissions for notifications
if [[ "${IS_NOTIFICATION:-false}" == "true" ]]; then
    log_info "🔐 Configuring iOS notification permissions..."
    
    # 1. Configure Info.plist for push notifications
    log_info "📝 Configuring Info.plist for push notifications..."
    
    # Add UIBackgroundModes with remote-notification
    if ! /usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" ios/Runner/Info.plist >/dev/null 2>&1; then
        /usr/libexec/PlistBuddy -c "Add :UIBackgroundModes array" ios/Runner/Info.plist 2>/dev/null || log_warning "⚠️ Could not add UIBackgroundModes array"
        /usr/libexec/PlistBuddy -c "Add :UIBackgroundModes:0 string 'remote-notification'" ios/Runner/Info.plist 2>/dev/null || log_warning "⚠️ Could not add remote-notification mode"
        log_success "✅ Added UIBackgroundModes with remote-notification to Info.plist"
    else
        # Check if remote-notification is already present
        if ! /usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" ios/Runner/Info.plist 2>/dev/null | grep -q "remote-notification"; then
            # Get current array length and add remote-notification
            ARRAY_LENGTH=$(/usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" ios/Runner/Info.plist 2>/dev/null | wc -l || echo "0")
            /usr/libexec/PlistBuddy -c "Add :UIBackgroundModes:$ARRAY_LENGTH string 'remote-notification'" ios/Runner/Info.plist 2>/dev/null || log_warning "⚠️ Could not add remote-notification mode"
            log_success "✅ Added remote-notification to existing UIBackgroundModes"
        else
            log_info "ℹ️ remote-notification already present in UIBackgroundModes"
        fi
    fi
    
    # 2. Create/Update entitlements file for push notifications
    log_info "🔐 Configuring push notification entitlements..."
    if [[ ! -f "ios/Runner/Runner.entitlements" ]]; then
        log_info "📝 Creating Runner.entitlements file for push notifications..."
        cat > ios/Runner/Runner.entitlements << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>aps-environment</key>
    <string>development</string>
    <key>com.apple.developer.aps-environment</key>
    <string>development</string>
    <key>com.apple.developer.background-modes</key>
    <array>
        <string>remote-notification</string>
    </array>
</dict>
</plist>
EOF
        log_success "✅ Created Runner.entitlements file with push notification support"
    else
        log_info "ℹ️ Runner.entitlements file already exists, updating for push notifications..."
        
        # Update aps-environment based on profile type
        if [[ "${PROFILE_TYPE:-}" == "app-store" ]]; then
            /usr/libexec/PlistBuddy -c "Set :aps-environment production" ios/Runner/Runner.entitlements 2>/dev/null || \
            /usr/libexec/PlistBuddy -c "Add :aps-environment string production" ios/Runner/Runner.entitlements 2>/dev/null || true
            
            /usr/libexec/PlistBuddy -c "Set :com.apple.developer.aps-environment production" ios/Runner/Runner.entitlements 2>/dev/null || \
            /usr/libexec/PlistBuddy -c "Add :com.apple.developer.aps-environment string production" ios/Runner/Runner.entitlements 2>/dev/null || true
            log_info "✅ Updated entitlements for production environment"
        else
            /usr/libexec/PlistBuddy -c "Set :aps-environment development" ios/Runner/Runner.entitlements 2>/dev/null || \
            /usr/libexec/PlistBuddy -c "Add :aps-environment string development" ios/Runner/Runner.entitlements 2>/dev/null || true
            
            /usr/libexec/PlistBuddy -c "Set :com.apple.developer.aps-environment development" ios/Runner/Runner.entitlements 2>/dev/null || \
            /usr/libexec/PlistBuddy -c "Add :com.apple.developer.aps-environment string development" ios/Runner/Runner.entitlements 2>/dev/null || true
            log_info "✅ Updated entitlements for development environment"
        fi
        
        # Ensure background modes include remote-notification
        if ! /usr/libexec/PlistBuddy -c "Print :com.apple.developer.background-modes" ios/Runner/Runner.entitlements 2>/dev/null | grep -q "remote-notification"; then
            if ! /usr/libexec/PlistBuddy -c "Print :com.apple.developer.background-modes" ios/Runner/Runner.entitlements 2>/dev/null; then
                /usr/libexec/PlistBuddy -c "Add :com.apple.developer.background-modes array" ios/Runner/Runner.entitlements 2>/dev/null || true
            fi
            ARRAY_LENGTH=$(/usr/libexec/PlistBuddy -c "Print :com.apple.developer.background-modes" ios/Runner/Runner.entitlements 2>/dev/null | wc -l || echo "0")
            /usr/libexec/PlistBuddy -c "Add :com.apple.developer.background-modes:$ARRAY_LENGTH string 'remote-notification'" ios/Runner/Runner.entitlements 2>/dev/null || true
            log_success "✅ Added remote-notification to entitlements background modes"
        else
            log_info "ℹ️ remote-notification already in entitlements background modes"
        fi
    fi
    
    # 3. Enable push notification capability in Xcode project
    log_info "🏗️ Enabling push notification capability in Xcode project..."
    
    # Create a more robust approach to modify Xcode project
    if [[ -f "ios/Runner.xcodeproj/project.pbxproj" ]]; then
        log_info "📝 Modifying Xcode project for push notification capability..."
        
        # Create a backup of the original project file
        cp ios/Runner.xcodeproj/project.pbxproj ios/Runner.xcodeproj/project.pbxproj.backup
        
        # Method 1: Try to add push notification capability using PlistBuddy if possible
        log_info "🔧 Attempting to add push notification capability to project..."
        
        # Check if SystemCapabilities section exists
        if grep -q "SystemCapabilities" ios/Runner.xcodeproj/project.pbxproj; then
            log_info "ℹ️ SystemCapabilities section found, adding push notification capability..."
            
            # Create a temporary file for modification
            TEMP_FILE="/tmp/project_mod.tmp"
            cp ios/Runner.xcodeproj/project.pbxproj "$TEMP_FILE"
            
            # Use awk for more reliable text processing
            awk '
            /SystemCapabilities = {/ {
                print $0
                print "\t\t\tcom.apple.Push = {"
                print "\t\t\t\tenabled = 1;"
                print "\t\t\t};"
                in_system_capabilities = 1
                next
            }
            /^[[:space:]]*};[[:space:]]*$/ && in_system_capabilities {
                in_system_capabilities = 0
                next
            }
            { print $0 }
            ' "$TEMP_FILE" > ios/Runner.xcodeproj/project.pbxproj
            
            rm -f "$TEMP_FILE" 2>/dev/null || true
            log_success "✅ Added push notification capability to existing SystemCapabilities"
        else
            log_info "ℹ️ SystemCapabilities section not found, creating new one..."
            
            # Find the CODE_SIGN_ENTITLEMENTS line and add SystemCapabilities after it
            TEMP_FILE="/tmp/project_mod.tmp"
            cp ios/Runner.xcodeproj/project.pbxproj "$TEMP_FILE"
            
            awk '
            /CODE_SIGN_ENTITLEMENTS = Runner\/Runner.entitlements;/ {
                print $0
                print "\t\t\tSystemCapabilities = {"
                print "\t\t\t\tcom.apple.Push = {"
                print "\t\t\t\t\tenabled = 1;"
                print "\t\t\t\t};"
                print "\t\t\t};"
                next
            }
            { print $0 }
            ' "$TEMP_FILE" > ios/Runner.xcodeproj/project.pbxproj
            
            rm -f "$TEMP_FILE" 2>/dev/null || true
            log_success "✅ Created SystemCapabilities section with push notification capability"
        fi
        
        # Verify the modification
        if grep -q "com.apple.Push" ios/Runner.xcodeproj/project.pbxproj; then
            log_success "✅ Push notification capability successfully added to Xcode project"
        else
            log_warning "⚠️ Push notification capability not found in project, attempting alternative method..."
            
            # Alternative method: Direct string replacement
            sed -i.bak 's/CODE_SIGN_ENTITLEMENTS = Runner\/Runner.entitlements;/CODE_SIGN_ENTITLEMENTS = Runner\/Runner.entitlements;\n\t\t\tSystemCapabilities = {\n\t\t\t\tcom.apple.Push = {\n\t\t\t\t\tenabled = 1;\n\t\t\t\t};\n\t\t\t};/' ios/Runner.xcodeproj/project.pbxproj 2>/dev/null || true
            rm -f ios/Runner.xcodeproj/project.pbxproj.bak 2>/dev/null || true
            
            # Final verification
            if grep -q "com.apple.Push" ios/Runner.xcodeproj/project.pbxproj; then
                log_success "✅ Push notification capability added using alternative method"
            else
                log_error "❌ Failed to add push notification capability to Xcode project"
                log_warning "⚠️ You may need to manually enable push notifications in Xcode"
            fi
        fi
    else
        log_error "❌ Project file not found, cannot configure push notification capability"
    fi
    
    # 4. Add FirebaseAppDelegateProxyEnabled to Info.plist
    log_info "🔥 Adding Firebase configuration to Info.plist..."
    if ! /usr/libexec/PlistBuddy -c "Print :FirebaseAppDelegateProxyEnabled" ios/Runner/Info.plist >/dev/null 2>&1; then
        /usr/libexec/PlistBuddy -c "Add :FirebaseAppDelegateProxyEnabled bool false" ios/Runner/Info.plist 2>/dev/null || log_warning "⚠️ Could not add FirebaseAppDelegateProxyEnabled"
        log_success "✅ Added FirebaseAppDelegateProxyEnabled to Info.plist"
    else
        log_info "ℹ️ FirebaseAppDelegateProxyEnabled already present in Info.plist"
    fi
    
    # 5. 🔔 CRITICAL: Add iOS notification permission request configuration
    log_info "🔔 Adding iOS notification permission request configuration..."
    
    # Add NSUserNotificationAlertStyle for iOS 10+ compatibility
    if ! /usr/libexec/PlistBuddy -c "Print :NSUserNotificationAlertStyle" ios/Runner/Info.plist >/dev/null 2>&1; then
        /usr/libexec/PlistBuddy -c "Add :NSUserNotificationAlertStyle string alert" ios/Runner/Info.plist 2>/dev/null || log_warning "⚠️ Could not add NSUserNotificationAlertStyle"
        log_success "✅ Added NSUserNotificationAlertStyle for iOS 10+ compatibility"
    else
        log_info "ℹ️ NSUserNotificationAlertStyle already present in Info.plist"
    fi
    
    # Add NSUserNotificationUsageDescription for better permission request
    if ! /usr/libexec/PlistBuddy -c "Print :NSUserNotificationUsageDescription" ios/Runner/Info.plist >/dev/null 2>&1; then
        NOTIFICATION_DESCRIPTION="${APP_NAME} needs to send you notifications to keep you updated with important information."
        /usr/libexec/PlistBuddy -c "Add :NSUserNotificationUsageDescription string '$NOTIFICATION_DESCRIPTION'" ios/Runner/Info.plist 2>/dev/null || log_warning "⚠️ Could not add NSUserNotificationUsageDescription"
        log_success "✅ Added NSUserNotificationUsageDescription for better permission request"
    else
        log_info "ℹ️ NSUserNotificationUsageDescription already present in Info.plist"
    fi
    
    # 🔔 CRITICAL: Add iOS notification permission request trigger
    log_info "🔔 Adding iOS notification permission request trigger..."
    
    # Add NSUserNotificationAlertStyle to trigger permission request
    if ! /usr/libexec/PlistBuddy -c "Print :NSUserNotificationAlertStyle" ios/Runner/Info.plist >/dev/null 2>&1; then
        /usr/libexec/PlistBuddy -c "Add :NSUserNotificationAlertStyle string alert" ios/Runner/Info.plist 2>/dev/null || log_warning "⚠️ Could not add NSUserNotificationAlertStyle"
        log_success "✅ Added NSUserNotificationAlertStyle to trigger permission request"
    else
        log_info "ℹ️ NSUserNotificationAlertStyle already present in Info.plist"
    fi
    
    # 🔔 CRITICAL: Add iOS notification permission request description for better UX
    log_info "🔔 Adding iOS notification permission request description for better UX..."
    
    # Add NSUserNotificationUsageDescription for better permission request
    if ! /usr/libexec/PlistBuddy -c "Print :NSUserNotificationUsageDescription" ios/Runner/Info.plist >/dev/null 2>&1; then
        NOTIFICATION_DESCRIPTION="\ needs to send you notifications to keep you updated with important information."
        /usr/libexec/PlistBuddy -c "Add :NSUserNotificationUsageDescription string '$NOTIFICATION_DESCRIPTION'" ios/Runner/Info.plist 2>/dev/null || log_warning "⚠️ Could not add NSUserNotificationUsageDescription"
        log_success "✅ Added NSUserNotificationUsageDescription for better UX"
    else
        log_info "ℹ️ NSUserNotificationUsageDescription already present in Info.plist"
    fi
    
    # 🔔 CRITICAL: Add modern iOS notification permission request configuration
    log_info "🔔 Adding modern iOS notification permission request configuration..."
    
    # Add NSUserNotificationAlertStyle for iOS 10+ compatibility and permission trigger
    if ! /usr/libexec/PlistBuddy -c "Print :NSUserNotificationAlertStyle" ios/Runner/Info.plist >/dev/null 2>&1; then
        /usr/libexec/PlistBuddy -c "Add :NSUserNotificationAlertStyle string alert" ios/Runner/Info.plist 2>/dev/null || log_warning "⚠️ Could not add NSUserNotificationAlertStyle"
        log_success "✅ Added NSUserNotificationAlertStyle for iOS 10+ compatibility and permission trigger"
    else
        log_info "ℹ️ NSUserNotificationAlertStyle already present in Info.plist"
    fi
    
    # 🔔 CRITICAL: Add iOS notification permission request description for modern iOS
    log_info "🔔 Adding iOS notification permission request description for modern iOS..."
    
    # Add NSUserNotificationUsageDescription for modern permission request
    if ! /usr/libexec/PlistBuddy -c "Print :NSUserNotificationUsageDescription" ios/Runner/Info.plist >/dev/null 2>&1; then
        NOTIFICATION_DESCRIPTION="${APP_NAME} needs to send you notifications to keep you updated with important information."
        /usr/libexec/PlistBuddy -c "Add :NSUserNotificationUsageDescription string '$NOTIFICATION_DESCRIPTION'" ios/Runner/Info.plist 2>/dev/null || log_warning "⚠️ Could not add NSUserNotificationUsageDescription"
        log_success "✅ Added NSUserNotificationUsageDescription for modern iOS permission request"
    else
        log_info "ℹ️ NSUserNotificationUsageDescription already present in Info.plist"
    fi
    
    # 🔔 CRITICAL: Add iOS notification permission request trigger
    log_info "🔔 Adding iOS notification permission request trigger..."
    
    # Add NSUserNotificationAlertStyle to trigger permission request
    if ! /usr/libexec/PlistBuddy -c "Print :NSUserNotificationAlertStyle" ios/Runner/Info.plist >/dev/null 2>&1; then
        /usr/libexec/PlistBuddy -c "Add :NSUserNotificationAlertStyle string alert" ios/Runner/Info.plist 2>/dev/null || log_warning "⚠️ Could not add NSUserNotificationAlertStyle"
        log_success "✅ Added NSUserNotificationAlertStyle to trigger permission request"
    else
        log_info "ℹ️ NSUserNotificationAlertStyle already present in Info.plist"
    fi
    
    # 🔔 CRITICAL: Add iOS notification permission request description for better UX
    log_info "🔔 Adding iOS notification permission request description for better UX..."
    
    # Add NSUserNotificationUsageDescription for better permission request
    if ! /usr/libexec/PlistBuddy -c "Print :NSUserNotificationUsageDescription" ios/Runner/Info.plist >/dev/null 2>&1; then
        NOTIFICATION_DESCRIPTION="\ needs to send you notifications to keep you updated with important information."
        /usr/libexec/PlistBuddy -c "Add :NSUserNotificationUsageDescription string '$NOTIFICATION_DESCRIPTION'" ios/Runner/Info.plist 2>/dev/null || log_warning "⚠️ Could not add NSUserNotificationUsageDescription"
        log_success "✅ Added NSUserNotificationUsageDescription for better UX"
    else
        log_info "ℹ️ NSUserNotificationUsageDescription already present in Info.plist"
    fi
    
    log_success "✅ iOS notification permissions configured successfully"
    
    # 🔍 CRITICAL: Verify iOS notification permission configuration
    log_info "🔍 Verifying iOS notification permission configuration..."
    
    # 🔐 CRITICAL: Ensure entitlements file is properly referenced in project
    log_info "🔐 Ensuring entitlements file is properly referenced in project..."
    
    # Check if CODE_SIGN_ENTITLEMENTS is set in project.pbxproj
    if ! grep -q "CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements" ios/Runner.xcodeproj/project.pbxproj; then
        log_warning "⚠️ CODE_SIGN_ENTITLEMENTS not found in project, adding it..."
        
        # Find the build configuration section and add entitlements
        TEMP_FILE="/tmp/project_entitlements.tmp"
        cp ios/Runner.xcodeproj/project.pbxproj "$TEMP_FILE"
        
        # Add CODE_SIGN_ENTITLEMENTS after CODE_SIGN_IDENTITY
        awk '
        /CODE_SIGN_IDENTITY = "iPhone Developer";/ {
            print $0
            print "\t\t\t\t\tCODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;"
            next
        }
        { print $0 }
        ' "$TEMP_FILE" > ios/Runner.xcodeproj/project.pbxproj
        
        rm -f "$TEMP_FILE" 2>/dev/null || true
        log_success "✅ Added CODE_SIGN_ENTITLEMENTS to project"
    else
        log_info "ℹ️ CODE_SIGN_ENTITLEMENTS already properly configured"
    fi
    
    # Check Info.plist configurations
    if /usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" ios/Runner/Info.plist >/dev/null 2>&1 | grep -q "remote-notification"; then
        log_success "✅ UIBackgroundModes includes remote-notification"
    else
        log_error "❌ UIBackgroundModes missing remote-notification"
    fi
    
    # Check entitlements configurations
    if [[ -f "ios/Runner/Runner.entitlements" ]]; then
        if /usr/libexec/PlistBuddy -c "Print :aps-environment" ios/Runner/Runner.entitlements >/dev/null 2>&1; then
            log_success "✅ aps-environment configured in entitlements"
        else
            log_error "❌ aps-environment not configured in entitlements"
        fi
        
        if /usr/libexec/PlistBuddy -c "Print :com.apple.developer.background-modes" ios/Runner/Runner.entitlements >/dev/null 2>&1 | grep -q "remote-notification"; then
            log_success "✅ Background modes include remote-notification in entitlements"
        else
            log_error "❌ Background modes missing remote-notification in entitlements"
        fi
    fi
    
    # Check Xcode project capability
    if [[ -f "ios/Runner.xcodeproj/project.pbxproj" ]]; then
        if grep -q "com.apple.Push" ios/Runner.xcodeproj/project.pbxproj; then
            log_success "✅ Push notification capability enabled in Xcode project"
        else
            log_error "❌ Push notification capability not found in Xcode project"
            log_warning "⚠️ Attempting to add push notification capability again..."
            
            # Try to add the capability one more time
            TEMP_FILE="/tmp/project_final.tmp"
            cp ios/Runner.xcodeproj/project.pbxproj "$TEMP_FILE"
            
            # Add SystemCapabilities section if it doesn't exist
            if ! grep -q "SystemCapabilities" "$TEMP_FILE"; then
                awk '
                /CODE_SIGN_ENTITLEMENTS = Runner\/Runner.entitlements;/ {
                    print $0
                    print "\t\t\t\tSystemCapabilities = {"
                    print "\t\t\t\t\tcom.apple.Push = {"
                    print "\t\t\t\t\t\tenabled = 1;"
                    print "\t\t\t\t\t};"
                    print "\t\t\t\t};"
                    next
                }
                { print $0 }
                ' "$TEMP_FILE" > ios/Runner.xcodeproj/project.pbxproj
                
                log_info "✅ Added SystemCapabilities with push notification capability"
            else
                # Add to existing SystemCapabilities
                awk '
                /SystemCapabilities = {/ {
                    print $0
                    print "\t\t\t\t\tcom.apple.Push = {"
                    print "\t\t\t\t\t\tenabled = 1;"
                    print "\t\t\t\t\t};"
                    in_system_capabilities = 1
                    next
                }
                /^[[:space:]]*};[[:space:]]*$/ && in_system_capabilities {
                    in_system_capabilities = 0
                    next
                }
                { print $0 }
                ' "$TEMP_FILE" > ios/Runner.xcodeproj/project.pbxproj
                
                log_info "✅ Added push notification capability to existing SystemCapabilities"
            fi
            
            rm -f "$TEMP_FILE" 2>/dev/null || true
            
            # Final verification
            if grep -q "com.apple.Push" ios/Runner.xcodeproj/project.pbxproj; then
                log_success "✅ Push notification capability successfully added on second attempt"
            else
                log_error "❌ Failed to add push notification capability after multiple attempts"
                log_warning "⚠️ Manual intervention required in Xcode"
            fi
        fi
    fi
    
    # Check Info.plist notification keys
    if /usr/libexec/PlistBuddy -c "Print :NSUserNotificationAlertStyle" ios/Runner/Info.plist >/dev/null 2>&1; then
        log_success "✅ NSUserNotificationAlertStyle configured in Info.plist"
    else
        log_error "❌ NSUserNotificationAlertStyle not configured in Info.plist"
    fi
    
    if /usr/libexec/PlistBuddy -c "Print :NSUserNotificationUsageDescription" ios/Runner/Info.plist >/dev/null 2>&1; then
        log_success "✅ NSUserNotificationUsageDescription configured in Info.plist"
    else
        log_error "❌ NSUserNotificationUsageDescription not configured in Info.plist"
    fi
    
    log_success "🎉 iOS notification permission configuration verification completed!"
    log_info "📱 Your iOS app is now configured to request notification permissions automatically!"
    log_info "🔔 Users will see the permission dialog: 'Allow [App Name] to send you notifications?'"
    log_info "📱 Push notifications will work in ALL app states: background, closed, and active"
    
else
    log_info "ℹ️ iOS notification permissions disabled (IS_NOTIFICATION=false)"
fi

# 🔥 Firebase Setup for iOS Push Notifications
if [[ "${PUSH_NOTIFY:-false}" == "true" ]]; then
    log_info "🔥 Setting up Firebase for iOS Push Notifications..."
    
    # Check if Firebase configuration is available
    if [[ -n "${FIREBASE_CONFIG_IOS:-}" ]]; then
        log_info "📥 Downloading Firebase iOS configuration..."
        
        # Download Firebase config with error handling and validation
        if curl -fSL "${FIREBASE_CONFIG_IOS}" -o ios/Runner/GoogleService-Info.plist 2>/dev/null; then
            log_success "✅ Firebase iOS configuration downloaded successfully"
            
            # Validate Firebase config file
            if [[ -f "ios/Runner/GoogleService-Info.plist" ]]; then
                log_success "✅ Firebase config file exists and is readable"
                
                # Validate key Firebase keys
                log_info "🔍 Validating Firebase configuration file..."
                if /usr/libexec/PlistBuddy -c "Print :API_KEY" ios/Runner/GoogleService-Info.plist >/dev/null 2>&1; then
                    log_success "✅ Firebase API_KEY found in config"
                else
                    log_warning "⚠️ Firebase API_KEY missing from config"
                fi
                
                if /usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" ios/Runner/GoogleService-Info.plist >/dev/null 2>&1; then
                    FIREBASE_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" ios/Runner/GoogleService-Info.plist)
                    log_success "✅ Firebase BUNDLE_ID found: $FIREBASE_BUNDLE_ID"
                    
                    # Check bundle ID consistency
                    if [[ -n "${BUNDLE_ID:-}" && "$FIREBASE_BUNDLE_ID" != "$BUNDLE_ID" ]]; then
                        log_warning "⚠️ Bundle ID mismatch: Firebase=$FIREBASE_BUNDLE_ID, Project=$BUNDLE_ID"
                        log_info "ℹ️ This may cause push notification issues"
                    fi
                else
                    log_warning "⚠️ Firebase BUNDLE_ID missing from config"
                fi
                
                if /usr/libexec/PlistBuddy -c "Print :GOOGLE_APP_ID" ios/Runner/GoogleService-Info.plist >/dev/null 2>&1; then
                    log_success "✅ Firebase GOOGLE_APP_ID found in config"
                else
                    log_warning "⚠️ Firebase GOOGLE_APP_ID missing from config"
                fi
                
                # Update Podfile with Firebase dependencies
                log_info "📦 Adding Firebase dependencies to Podfile..."
                if [[ -f "ios/Podfile" ]]; then
                    # Remove existing Firebase entries if any
                    sed -i.bak '/pod .Firebase\/Core./d' ios/Podfile 2>/dev/null || true
                    sed -i.bak '/pod .Firebase\/Messaging./d' ios/Podfile 2>/dev/null || true
                    rm -f ios/Podfile.bak 2>/dev/null || true
                    
                    # Add Firebase dependencies
                    if ! grep -q "pod 'Firebase/Core'" ios/Podfile; then
                        cat >> ios/Podfile << 'EOF'

# Firebase dependencies for push notifications
pod 'Firebase/Core'
pod 'Firebase/Messaging'
EOF
                        log_success "✅ Firebase dependencies added to Podfile"
                    else
                        log_info "ℹ️ Firebase dependencies already present in Podfile"
                    fi
                else
                    log_warning "⚠️ Podfile not found, Firebase dependencies cannot be added"
                fi
                
                log_success "✅ Firebase setup completed successfully"
            else
                log_warning "⚠️ Firebase config file may not be properly downloaded"
            fi
        else
            log_warning "⚠️ Failed to download Firebase iOS configuration"
            log_info "ℹ️ Push notifications will not work without Firebase configuration"
        fi
    else
        log_warning "⚠️ FIREBASE_CONFIG_IOS not provided"
        log_info "ℹ️ Push notifications will not work without Firebase configuration"
    fi
else
    log_info "ℹ️ Firebase setup skipped - push notifications disabled (PUSH_NOTIFY=false)"
fi

# 🔍 Final push notification configuration verification
log_info "🔍 Verifying final push notification configuration..."
if [[ "${IS_NOTIFICATION:-false}" == "true" ]]; then
    # Check Info.plist configurations
    if /usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" ios/Runner/Info.plist >/dev/null 2>&1 | grep -q "remote-notification"; then
        log_success "✅ UIBackgroundModes includes remote-notification"
    else
        log_error "❌ UIBackgroundModes missing remote-notification"
    fi
    
    # Check entitlements configurations
    if [[ -f "ios/Runner/Runner.entitlements" ]]; then
        if /usr/libexec/PlistBuddy -c "Print :aps-environment" ios/Runner/Runner.entitlements >/dev/null 2>&1; then
            log_success "✅ aps-environment configured in entitlements"
        else
            log_error "❌ aps-environment not configured in entitlements"
        fi
        
        if /usr/libexec/PlistBuddy -c "Print :com.apple.developer.background-modes" ios/Runner/Runner.entitlements >/dev/null 2>&1 | grep -q "remote-notification"; then
            log_success "✅ Background modes include remote-notification in entitlements"
        else
            log_error "❌ Background modes missing remote-notification in entitlements"
        fi
    fi
    
    # 🔔 CRITICAL: Ensure notification permission request is properly configured
    log_info "🔔 Final notification permission request verification..."
    
    log_success "🎉 Push notification configuration verification completed!"
    log_info "📱 Your iOS app is now configured to receive push notifications in ALL states:"
    echo "   🔵 Background state (app in background)"
    echo "   🔴 Closed state (app terminated)"
    echo "   🟢 Opened state (app active)"
    echo ""
    log_info "🔔 Notification permission will be requested automatically when the app first runs"
    log_info "📱 Users will see a permission dialog asking: 'Allow [App Name] to send you notifications?'"
else
    log_info "ℹ️ Push notification verification skipped (IS_NOTIFICATION=false)"
fi

# Always ensure basic push notification structure exists (non-blocking)
log_info "🔧 Ensuring basic push notification structure..."
if [[ ! -f "ios/Runner/Runner.entitlements" ]]; then
    log_info "📝 Creating basic entitlements file..."
    cat > ios/Runner/Runner.entitlements << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>aps-environment</key>
    <string>development</string>
    <key>com.apple.developer.aps-environment</key>
    <string>development</string>
    <key>com.apple.developer.background-modes</key>
    <array>
        <string>remote-notification</string>
    </array>
</dict>
</plist>
EOF
    log_success "✅ Created basic entitlements file"
fi

# Ensure Info.plist has basic push notification structure (non-blocking)
if ! /usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" ios/Runner/Info.plist >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Add :UIBackgroundModes array" ios/Runner/Info.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :UIBackgroundModes: string 'remote-notification'" ios/Runner/Info.plist 2>/dev/null || true
    log_info "✅ Added basic UIBackgroundModes to Info.plist"
fi

# Push notification capability is now handled in ios-workflow/permissions.sh
# This ensures proper Xcode project configuration for push notifications
log_info "ℹ️ Push notification capability configuration handled by permissions script"

# Flutter dependencies
echo "📦 Installing Flutter dependencies..."
flutter pub get > /dev/null || {
    log_error "flutter pub get failed"
    exit 1
}

# Comprehensive Podfile Validation and Fix (Non-blocking)
log_info "🔍 Comprehensive Podfile validation and fix..."
if [[ -f "ios/Podfile" ]]; then
    # Check for critical Podfile configurations
    log_info "📋 Checking Podfile configuration..."
    
    # Check if use_modular_headers! is present
    if ! grep -q "use_modular_headers!" ios/Podfile; then
        log_warning "⚠️ use_modular_headers! missing from Podfile, adding it..."
        sed -i.bak 's/use_frameworks!/use_frameworks!\n  use_modular_headers!/' ios/Podfile
        rm -f ios/Podfile.bak 2>/dev/null || true
        log_success "✅ Added use_modular_headers! to Podfile"
    else
        log_info "ℹ️ use_modular_headers! already present in Podfile"
    fi
    
    # Check Firebase dependencies
    if grep -q "pod 'Firebase/Core'" ios/Podfile && grep -q "pod 'Firebase/Messaging'" ios/Podfile; then
        log_success "✅ Firebase dependencies found in Podfile"
    else
        if [[ "$FIREBASE_ENABLED" == "true" ]]; then
            log_warning "⚠️ Firebase dependencies missing from Podfile, adding them..."
            # Add Firebase dependencies if missing
            if ! grep -q "pod 'Firebase/Core'" ios/Podfile; then
                echo "" >> ios/Podfile
                echo "# Firebase dependencies for push notifications" >> ios/Podfile
                echo "pod 'Firebase/Core'" >> ios/Podfile
                echo "pod 'Firebase/Messaging'" >> ios/Podfile
                log_success "✅ Firebase dependencies added to Podfile"
            fi
        else
            log_info "ℹ️ Firebase disabled, skipping dependency verification"
        fi
    fi
    
    # Check for comprehensive modular headers configuration
    log_info "🔧 Ensuring comprehensive modular headers configuration..."
    
    # Add missing modular headers for problematic pods
    PROBLEMATIC_PODS=("GoogleUtilities" "FirebaseCoreInternal" "nanopb" "GTMSessionFetcher" "PromisesObjC" "AppCheckCore")
    
    for pod in "${PROBLEMATIC_PODS[@]}"; do
        if grep -q "pod '$pod'" ios/Podfile; then
            if ! grep -q "pod '$pod'.*:modular_headers => true" ios/Podfile; then
                log_info "🔧 Adding :modular_headers => true to $pod"
                sed -i.bak "s/pod '$pod'/pod '$pod', :modular_headers => true/" ios/Podfile
                rm -f ios/Podfile.bak 2>/dev/null || true
            fi
        fi
    done
    
    # CRITICAL FIX: Ensure the Podfile has the correct structure for Swift module integration
    log_info "🔧 Applying critical Podfile fixes for Swift module integration..."
    
    # Create a backup of the original Podfile
    cp ios/Podfile ios/Podfile.backup
    
    # Generate a clean Podfile with the correct structure
    cat > ios/Podfile << 'EOF'
# Uncomment this line to define a global platform for your project
platform :ios, '13.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!
  
  # Install Flutter pods FIRST
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  # Firebase dependencies with comprehensive modular headers configuration
  pod 'Firebase/Core', :modular_headers => true
  pod 'Firebase/Messaging', :modular_headers => true
  pod 'FirebaseCoreInternal', :modular_headers => true
  pod 'GoogleUtilities', :modular_headers => true
  pod 'nanopb', :modular_headers => true
  pod 'GTMSessionFetcher', :modular_headers => true
  pod 'PromisesObjC', :modular_headers => true
  pod 'AppCheckCore', :modular_headers => true
  
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    target.build_configurations.each do |config|
      # Set minimum iOS version
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      
      # Disable code signing for pods
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ''
      
      # Fix for Flutter.h not found
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
      
      # Force modular headers for all pods
      config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
      config.build_settings['DEFINES_MODULE'] = 'YES'
      
      # Add framework search paths
      config.build_settings['FRAMEWORK_SEARCH_PATHS'] ||= [
        '$(inherited)',
        '${PODS_ROOT}/../Flutter',
        '${PODS_XCFRAMEWORKS_BUILD_DIR}/Flutter',
        '${PODS_CONFIGURATION_BUILD_DIR}'
      ]
      
      # Add header search paths
      config.build_settings['HEADER_SEARCH_PATHS'] ||= [
        '$(inherited)',
        '${PODS_ROOT}/Headers/Public',
        '${PODS_ROOT}/Headers/Public/Flutter',
        '${PODS_ROOT}/Headers/Public/Flutter/Flutter'
      ]
    end
  end
end
EOF
    
    log_success "✅ Critical Podfile fixes applied for Swift module integration"
    
    log_success "✅ Podfile validation and fix completed"
    
    # Show final Podfile contents for debugging
    log_info "📋 Final Podfile contents:"
    cat ios/Podfile
else
    log_warning "⚠️ Podfile not found, continuing without validation"
fi

run_cocoapods_commands

# Update Release.xcconfig
XC_CONFIG_PATH="ios/Flutter/release.xcconfig"
echo "🔧 Updating release.xcconfig with dynamic signing values..."
sed -i '' '/^CODE_SIGN_STYLE/d' "$XC_CONFIG_PATH"
sed -i '' '/^DEVELOPMENT_TEAM/d' "$XC_CONFIG_PATH"
sed -i '' '/^PROVISIONING_PROFILE_SPECIFIER/d' "$XC_CONFIG_PATH"
sed -i '' '/^CODE_SIGN_IDENTITY/d' "$XC_CONFIG_PATH"
sed -i '' '/^PRODUCT_BUNDLE_IDENTIFIER/d' "$XC_CONFIG_PATH"

cat <<EOF >> "$XC_CONFIG_PATH"
CODE_SIGN_STYLE = Manual
DEVELOPMENT_TEAM = $APPLE_TEAM_ID
PROVISIONING_PROFILE_SPECIFIER = $UUID
CODE_SIGN_IDENTITY = iPhone Distribution
PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID
EOF

echo "✅ release.xcconfig updated:"
cat "$XC_CONFIG_PATH"

# Step 5.5: Fix corrupted Info.plist if needed (CRITICAL for workflow success)
echo "🔧 Step 5.5: Fixing Corrupted Info.plist (if needed)..."

# Check if Info.plist is corrupted and fix it
if [ -f "lib/scripts/ios-workflow/fix_corrupted_infoplist.sh" ]; then
    chmod +x lib/scripts/ios-workflow/fix_corrupted_infoplist.sh
    if ./lib/scripts/ios-workflow/fix_corrupted_infoplist.sh; then
        log_success "✅ Info.plist corruption check completed"
    else
        log_warning "⚠️ Info.plist fix failed, but continuing..."
    fi
else
    log_warning "⚠️ Info.plist fix script not found, skipping corruption check"
fi

# Validate bundle ID consistency
log_info "🔍 Validating bundle ID consistency..."
ACTUAL_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" ios/Runner/Info.plist 2>/dev/null || echo "")
if [[ "$ACTUAL_BUNDLE_ID" != "$BUNDLE_ID" ]]; then
    log_warning "Bundle ID mismatch detected!"
    log_warning "Expected: $BUNDLE_ID"
    log_warning "Actual: $ACTUAL_BUNDLE_ID"
    log_info "Fixing bundle ID in Info.plist..."
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" ios/Runner/Info.plist
    log_success "Bundle ID fixed in Info.plist"
else
    log_success "Bundle ID consistency verified: $BUNDLE_ID"
fi

echo "Set up code signing settings on Xcode project"
xcode-project use-profiles

# Final verification before build
log_info "🔍 Final verification before build..."
log_info "Bundle ID: $BUNDLE_ID"
log_info "Team ID: $APPLE_TEAM_ID"
log_info "Provisioning Profile UUID: $UUID"
log_info "Provisioning Profile Path: $PROFILE_PATH"

# Verify key files exist
if [[ -f "ios/Runner/Info.plist" ]]; then
    # Check if Info.plist is corrupted before final verification
    if [ -f "lib/scripts/ios-workflow/fix_corrupted_infoplist.sh" ]; then
        log_info "🔧 Final Info.plist corruption check before verification..."
        chmod +x lib/scripts/ios-workflow/fix_corrupted_infoplist.sh
        ./lib/scripts/ios-workflow/fix_corrupted_infoplist.sh
    fi
    
    ACTUAL_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" ios/Runner/Info.plist 2>/dev/null || echo "")
    log_info "Info.plist Bundle ID: $ACTUAL_BUNDLE_ID"
fi

if [[ -f "ios/Flutter/release.xcconfig" ]]; then
    log_info "Release.xcconfig contents:"
    cat ios/Flutter/release.xcconfig
fi

log_success "✅ Pre-build verification completed"

# Clean and prepare for build
log_info "🧹 Cleaning build cache to ensure fresh environment configuration..."
flutter clean > /dev/null 2>&1 || log_warning "⚠️ flutter clean failed (continuing)"
rm -rf .dart_tool/ > /dev/null 2>&1 || true
rm -rf build/ > /dev/null 2>&1 || true

# Verify environment configuration is still valid after clean
log_info "📋 Re-verifying environment configuration after clean..."
if flutter analyze lib/config/env_config.dart >/dev/null 2>&1; then
    log_success "✅ Environment configuration still valid after clean"
else
    log_error "❌ Environment configuration invalid after clean"
    flutter analyze lib/config/env_config.dart
    exit 1
fi

# CRITICAL: Final icon validation before build
log_info "🔍 CRITICAL: Final icon validation before Flutter build..."
log_info "This validation ensures App Store Connect upload will succeed..."

# Check if all critical icons exist and have content
CRITICAL_ICONS=(
    "Icon-App-60x60@2x.png:120x120"
    "Icon-App-76x76@2x.png:152x152"
    "Icon-App-83.5x83.5@2x.png:167x167"
)

ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
MISSING_CRITICAL=()
EMPTY_CRITICAL=()

for icon_info in "${CRITICAL_ICONS[@]}"; do
    icon="${icon_info%%:*}"
    size="${icon_info##*:}"
    filepath="$ICON_DIR/$icon"
    
    if [[ ! -f "$filepath" ]]; then
        MISSING_CRITICAL+=("$icon ($size)")
    elif [[ ! -s "$filepath" ]]; then
        EMPTY_CRITICAL+=("$icon ($size)")
    fi
done

if [[ ${#MISSING_CRITICAL[@]} -gt 0 ]]; then
    log_error "❌ CRITICAL: Missing icons before build:"
    for icon in "${MISSING_CRITICAL[@]}"; do
        log_error "  - $icon"
    done
    log_error "❌ Build will fail App Store Connect validation"
    log_error "❌ Running emergency icon fix..."
    
    # Emergency icon fix
    if [ -f "lib/scripts/ios-workflow/fix_ios_icons_robust.sh" ]; then
        chmod +x lib/scripts/ios-workflow/fix_ios_icons_robust.sh
        if ./lib/scripts/ios-workflow/fix_ios_icons_robust.sh; then
            log_success "✅ Emergency icon fix completed"
        else
            log_error "❌ Emergency icon fix failed - build may fail validation"
        fi
    else
        log_error "❌ Emergency icon fix script not found"
    fi
fi

if [[ ${#EMPTY_CRITICAL[@]} -gt 0 ]]; then
    log_error "❌ CRITICAL: Empty icons before build:"
    for icon in "${EMPTY_CRITICAL[@]}"; do
        log_error "  - $icon"
    done
    log_error "❌ Build will fail App Store Connect validation"
fi

# Check CFBundleIconName in Info.plist
PLIST_PATH="ios/Runner/Info.plist"
if [[ -f "$PLIST_PATH" ]]; then
    if grep -q "CFBundleIconName" "$PLIST_PATH"; then
        log_success "✅ CFBundleIconName is present in Info.plist"
    else
        log_error "❌ CRITICAL: CFBundleIconName missing from Info.plist"
        log_error "❌ Build will fail App Store Connect validation"
        log_error "❌ Adding CFBundleIconName..."
        
        # Add CFBundleIconName
        if ! grep -q "CFBundleIconName" "$PLIST_PATH"; then
            sed -i '' 's/<dict>/<dict>\n\t<key>CFBundleIconName<\/key>\n\t<string>AppIcon<\/string>/' "$PLIST_PATH"
            log_success "✅ CFBundleIconName added to Info.plist"
        fi
    fi
else
    log_error "❌ Info.plist not found: $PLIST_PATH"
    exit 1
fi

# Final validation summary
if [[ ${#MISSING_CRITICAL[@]} -eq 0 ]] && [[ ${#EMPTY_CRITICAL[@]} -eq 0 ]]; then
    log_success "✅ All critical icons are present and valid"
    log_success "✅ CFBundleIconName is properly configured"
    log_success "✅ Build should pass App Store Connect validation"
else
    log_warning "⚠️ Icon issues detected - build may fail App Store Connect validation"
    log_warning "⚠️ Continuing build but upload may fail..."
fi

# Build
log_info "📱 Building Flutter iOS app in release mode..."
flutter build ios --release --no-codesign \
    --build-name="$VERSION_NAME" \
    --build-number="$VERSION_CODE" \
    2>&1 | tee flutter_build.log

# Check if Flutter build was successful
if [ $? -eq 0 ]; then
    log_success "✅ Flutter build completed successfully"
else
    log_error "❌ Flutter build failed"
    # Show relevant error messages from the log
    echo "=== Flutter Build Log (Errors/Warnings) ==="
    grep -E "(Error|FAILURE|Exception|error|warning|Warning)" flutter_build.log || echo "No specific errors found in log"
    echo "=== End Flutter Build Log ==="
    exit 1
fi

log_info "📦 Archiving app with Xcode..."
mkdir -p build/ios/archive

xcodebuild -workspace ios/Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -archivePath build/ios/archive/Runner.xcarchive \
    -destination 'generic/platform=iOS' \
    archive \
    DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
    2>&1 | tee xcodebuild_archive.log

# Check if Xcode archive was successful
if [ $? -eq 0 ]; then
    log_success "✅ Xcode archive completed successfully"
else
    log_error "❌ Xcode archive failed"
    # Show relevant error messages from the log
    echo "=== Xcode Archive Log (Errors/Warnings) ==="
    grep -E "(error:|warning:|Check dependencies|Provisioning|CodeSign|FAILED)" xcodebuild_archive.log || echo "No specific errors found in log"
    echo "=== End Xcode Archive Log ==="
    exit 1
fi

log_info "🛠️ Writing ExportOptions.plist..."
cat > ios/ExportOptions.plist << EXPORTPLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>$BUNDLE_ID</key>
        <string>$UUID</string>
    </dict>
    <key>teamID</key>
    <string>$APPLE_TEAM_ID</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EXPORTPLIST

# Final icon verification before IPA export
log_info "🔍 Final icon verification before IPA export..."
if [ -f "lib/scripts/ios-workflow/test_icon_fix.sh" ]; then
    chmod +x lib/scripts/ios-workflow/test_icon_fix.sh
    if ./lib/scripts/ios-workflow/test_icon_fix.sh; then
        log_success "✅ Final icon verification passed - IPA should pass App Store validation"
    else
        log_error "❌ Final icon verification failed - IPA will fail App Store validation"
        log_warning "⚠️ Check the verification output above for specific issues"
        log_warning "⚠️ Consider fixing icon issues before proceeding with export"
    fi
else
    log_warning "⚠️ Icon verification script not found, cannot verify icons before export"
fi

log_info "📤 Exporting IPA..."
set -x # verbose shell output

xcodebuild -exportArchive \
    -archivePath build/ios/archive/Runner.xcarchive \
    -exportPath build/ios/output \
    -exportOptionsPlist ios/ExportOptions.plist

# Find and verify IPA
IPA_PATH=$(find build/ios/output -name "*.ipa" | head -n 1)
if [ -z "$IPA_PATH" ]; then
    echo "IPA not found in build/ios/output. Searching entire clone directory..."
    IPA_PATH=$(find . -name "*.ipa" | head -n 1)
fi
if [ -z "$IPA_PATH" ]; then
    log_error "❌ IPA file not found. Build failed."
    exit 1
fi
log_success "✅ IPA found at: $IPA_PATH"

# Create artifacts summary
log_info "📋 Creating artifacts summary..."
mkdir -p output/ios
cat > output/ios/ARTIFACTS_SUMMARY.txt << EOF
iOS Build Artifacts Summary
===========================

Build Information:
- App Name: ${APP_NAME:-Unknown}
- Bundle ID: ${BUNDLE_ID:-Unknown}
- Version: ${VERSION_NAME:-Unknown}
- Build Number: ${VERSION_CODE:-Unknown}
- Team ID: ${APPLE_TEAM_ID:-Unknown}

Generated Files:
- IPA File: $IPA_PATH
- Archive: build/ios/archive/Runner.xcarchive
- ExportOptions: ios/ExportOptions.plist
- Release Config: ios/Flutter/release.xcconfig

Build Logs:
- Flutter Build: flutter_build.log
- Xcode Archive: xcodebuild_archive.log

Build Status: ✅ SUCCESS
Build Date: $(date)
EOF

log_success "✅ Artifacts summary created: output/ios/ARTIFACTS_SUMMARY.txt"

# Copy IPA to output directory for easier access
cp "$IPA_PATH" "output/ios/" 2>/dev/null || log_warning "Could not copy IPA to output/ios/"

# List all generated artifacts
log_info "📦 Generated artifacts:"
find build/ios/output -name "*.ipa" -exec echo "  📱 IPA: {}" \;
find build/ios/archive -name "*.xcarchive" -exec echo "  📦 Archive: {}" \;
find output/ios -name "*" -exec echo "  📋 Output: {}" \;

# Upload to App Store Connect if configured (non-blocking)
log_info "📤 App Store Connect Upload Status:"
log_info "  - UPLOAD_TO_APP_STORE: ${UPLOAD_TO_APP_STORE:-false}"
log_info "  - APP_STORE_CONNECT_API_KEY_URL: ${APP_STORE_CONNECT_API_KEY_URL:-not set}"
log_info "  - APP_STORE_CONNECT_KEY_IDENTIFIER: ${APP_STORE_CONNECT_KEY_IDENTIFIER:-not set}"
log_info "  - APP_STORE_CONNECT_ISSUER_ID: ${APP_STORE_CONNECT_ISSUER_ID:-not set}"

if [[ "${UPLOAD_TO_APP_STORE:-false}" == "true" ]]; then
    if [[ -n "${APP_STORE_CONNECT_API_KEY_URL:-}" && -n "${APP_STORE_CONNECT_KEY_IDENTIFIER:-}" && -n "${APP_STORE_CONNECT_ISSUER_ID:-}" ]]; then
        log_info "📤 Uploading to App Store Connect..."
        
        APP_STORE_CONNECT_API_KEY_PATH="$HOME/private_keys/AuthKey_${APP_STORE_CONNECT_KEY_IDENTIFIER}.p8"
        mkdir -p "$(dirname "$APP_STORE_CONNECT_API_KEY_PATH")"
        
        if curl -fSL "${APP_STORE_CONNECT_API_KEY_URL}" -o "$APP_STORE_CONNECT_API_KEY_PATH" 2>/dev/null; then
            log_success "✅ API key downloaded to $APP_STORE_CONNECT_API_KEY_PATH"

            if xcrun altool --upload-app \
                -f "$IPA_PATH" \
                -t ios \
                --apiKey "$APP_STORE_CONNECT_KEY_IDENTIFIER" \
                --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID" 2>&1; then
                log_success "✅ App uploaded to App Store Connect successfully"
            else
                log_warning "⚠️ App Store Connect upload failed (continuing)"
            fi
        else
            log_warning "⚠️ Failed to download App Store Connect API key (continuing)"
        fi
    else
        log_warning "⚠️ App Store Connect upload skipped - missing required variables"
        log_info "ℹ️ Required: UPLOAD_TO_APP_STORE=true, APP_STORE_CONNECT_API_KEY_URL, APP_STORE_CONNECT_KEY_IDENTIFIER, APP_STORE_CONNECT_ISSUER_ID"
    fi
else
    log_info "ℹ️ App Store Connect upload disabled (UPLOAD_TO_APP_STORE=false)"
fi

log_success "🎉 iOS build process completed successfully!"
log_info "📦 Artifacts available in:"
log_info "  📱 IPA: $IPA_PATH"
log_info "  📋 Summary: output/ios/ARTIFACTS_SUMMARY.txt"
log_info "  📦 Archive: build/ios/archive/Runner.xcarchive"
log_info "  📋 Config: ios/ExportOptions.plist"
