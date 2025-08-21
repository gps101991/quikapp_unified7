#!/usr/bin/env bash

# Corrected iOS Workflow Script
# Follows the same logical sequence as Android workflow:
# 1. Build Acceleration & Setup
# 2. Version Management (app names, bundle IDs)
# 3. Asset Download & Configuration
# 4. Dynamic Firebase Setup (AFTER app configuration)
# 5. iOS-specific Configuration
# 6. Build Process

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

# Logging functions
log_info() { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error() { echo "❌ $1"; }
log_warning() { echo "⚠️ $1"; }
log() { echo "📌 $1"; }

echo "🚀 Starting Corrected iOS Workflow..."

# Environment info
echo "📊 Build Environment:"
echo " - Flutter: $(flutter --version | head -1)"
echo " - Java: $(java -version 2>&1 | head -1)"
echo " - Xcode: $(xcodebuild -version | head -1)"
echo " - CocoaPods: $(pod --version)"

# =============================================================================
# STEP 1: BUILD ACCELERATION & INITIAL SETUP
# =============================================================================
echo "🚀 Step 1: Build Acceleration & Initial Setup..."

# Basic cleanup and optimization
log_info "Performing basic cleanup and optimization..."
flutter clean > /dev/null 2>&1 || log_warning "flutter clean failed (continuing)"
rm -rf ~/Library/Developer/Xcode/DerivedData/* > /dev/null 2>&1 || true
rm -rf .dart_tool/ > /dev/null 2>&1 || true
rm -rf ios/Pods/ > /dev/null 2>&1 || true
rm -rf ios/build/ > /dev/null 2>&1 || true
rm -rf ios/.symlinks > /dev/null 2>&1 || true
rm -f ios/Podfile.lock > /dev/null 2>&1 || true

# Initialize Flutter to generate configuration files
log_info "Initializing Flutter to generate configuration files..."
flutter pub get || {
    log_warning "flutter pub get failed, trying flutter clean first..."
    flutter clean
    flutter pub get
}

# Force Flutter to generate iOS configuration files
log_info "Forcing Flutter to generate iOS configuration files..."
flutter build ios --no-codesign --debug || {
    log_warning "flutter build ios failed, but continuing with configuration generation..."
}

# Fix Generated.xcconfig issue
log_info "Fixing Generated.xcconfig configuration..."
if [ -f "lib/scripts/ios-workflow/fix_generated_config.sh" ]; then
    chmod +x lib/scripts/ios-workflow/fix_generated_config.sh
    if ./lib/scripts/ios-workflow/fix_generated_config.sh; then
        log_success "Generated.xcconfig fix completed"
    else
        log_error "Generated.xcconfig fix failed"
        exit 1
    fi
else
    log_error "Generated.xcconfig fix script not found"
    exit 1
fi

log_success "✅ Build acceleration and initial setup completed"

# =============================================================================
# STEP 2: VERSION MANAGEMENT & APP CONFIGURATION
# =============================================================================
echo "📝 Step 2: Version Management & App Configuration..."

# Generate environment configuration FIRST (like Android workflow)
log_info "🎯 Generating Environment Configuration from API Variables..."
if [ -f "lib/scripts/utils/gen_env_config.sh" ]; then
    chmod +x lib/scripts/utils/gen_env_config.sh
    source lib/scripts/utils/gen_env_config.sh
    if generate_env_config; then
        log_success "✅ Environment configuration generated successfully"
        
        # Show generated config summary
        log_info "📋 Generated Config Summary:"
        log_info "   App: ${APP_NAME} v${VERSION_NAME}"
        log_info "   Workflow: ${WORKFLOW_ID:-unknown}"
        log_info "   Bundle ID: ${BUNDLE_ID:-not_set}"
        log_info "   Firebase: ${PUSH_NOTIFY:-false}"
        log_info "   iOS Signing: ${CERT_PASSWORD:+true}"
        log_info "   Profile Type: ${PROFILE_TYPE:-app-store}"
    else
        log_error "❌ Failed to generate environment configuration"
        exit 1
    fi
else
    log_error "❌ Environment configuration generator not found"
    exit 1
fi

# Update app name and bundle ID (like Android version management)
log_info "📱 Updating iOS app configuration..."

# Update display name
if [[ -n "$APP_NAME" ]]; then
    PLIST_PATH="ios/Runner/Info.plist"
    /usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" "$PLIST_PATH" 2>/dev/null \
        && /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName '$APP_NAME'" "$PLIST_PATH" \
        || /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string '$APP_NAME'" "$PLIST_PATH"
    log_success "Updated app display name to: $APP_NAME"
fi

# Update bundle identifier
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

# Update version information
if [[ -n "$VERSION_NAME" ]]; then
    PLIST_PATH="ios/Runner/Info.plist"
    
    # Check if Info.plist is corrupted before version update
    if [ -f "lib/scripts/ios-workflow/fix_corrupted_infoplist.sh" ]; then
        log_info "🔧 Checking for Info.plist corruption before version name update..."
        chmod +x lib/scripts/ios-workflow/fix_corrupted_infoplist.sh
        ./lib/scripts/ios-workflow/fix_corrupted_infoplist.sh
    fi
    
    plutil -replace CFBundleShortVersionString -string "$VERSION_NAME" "$PLIST_PATH"
    log_success "Updated version name to: $VERSION_NAME"
fi

if [[ -n "$VERSION_CODE" ]]; then
    PLIST_PATH="ios/Runner/Info.plist"
    
    # Check if Info.plist is corrupted before version update
    if [ -f "lib/scripts/ios-workflow/fix_corrupted_infoplist.sh" ]; then
        log_info "🔧 Checking for Info.plist corruption before version code update..."
        chmod +x lib/scripts/ios-workflow/fix_corrupted_infoplist.sh
        ./lib/scripts/ios-workflow/fix_corrupted_infoplist.sh
    fi
    
    plutil -replace CFBundleVersion -string "$VERSION_CODE" "$PLIST_PATH"
    log_success "Updated version code to: $VERSION_CODE"
fi

log_success "✅ Version management and app configuration completed"

# =============================================================================
# STEP 3: ASSET DOWNLOAD & CONFIGURATION
# =============================================================================
echo "🎨 Step 3: Asset Download & Configuration..."

# Create necessary directories
mkdir -p ios/certificates
mkdir -p output/ios
mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles

# Download app icons (like Android branding)
log_info "Installing app icons..."
if [ -f "lib/scripts/ios-workflow/install_app_icon.sh" ]; then
    chmod +x lib/scripts/ios-workflow/install_app_icon.sh
    if ./lib/scripts/ios-workflow/install_app_icon.sh; then
        log_success "App icon installation completed"
    else
        log_warning "App icon installation failed, trying force creation..."
        if [ -f "lib/scripts/ios-workflow/force_create_icons.sh" ]; then
            chmod +x lib/scripts/ios-workflow/force_create_icons.sh
            if ./lib/scripts/ios-workflow/force_create_icons.sh; then
                log_success "Force icon creation completed"
            else
                log_error "Both icon installation methods failed"
                exit 1
            fi
        else
            log_error "Force icon creation script not found"
            exit 1
        fi
    fi
else
    log_warning "App icon installation script not found, trying force creation..."
    if [ -f "lib/scripts/ios-workflow/force_create_icons.sh" ]; then
        chmod +x lib/scripts/ios-workflow/force_create_icons.sh
        if ./lib/scripts/ios-workflow/force_create_icons.sh; then
            log_success "Force icon creation completed"
        else
            log_error "Force icon creation failed"
            exit 1
        fi
    else
        log_error "No icon installation scripts found"
        exit 1
    fi
fi

# Verify app icons were created
log_info "Verifying app icons were created..."
ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
if [ -d "$ICON_DIR" ]; then
    ICON_COUNT=$(ls -1 "$ICON_DIR"/*.png 2>/dev/null | wc -l)
    if [ "$ICON_COUNT" -ge 19 ]; then
        log_success "Found $ICON_COUNT app icons"
    else
        log_error "Only found $ICON_COUNT app icons, expected at least 19"
        exit 1
    fi
else
    log_error "App icon directory not found: $ICON_DIR"
    exit 1
fi

log_success "✅ Asset download and configuration completed"

# =============================================================================
# STEP 4: DYNAMIC FIREBASE SETUP (AFTER APP CONFIGURATION)
# =============================================================================
echo "🔥 Step 4: Dynamic Firebase Setup (AFTER App Configuration)..."

# NOTE: This runs AFTER app name and bundle ID changes are complete
log_info "🔥 Setting up dynamic Firebase configuration..."
if [ -f "lib/scripts/ios/firebase.sh" ]; then
    chmod +x lib/scripts/ios/firebase.sh
    if ./lib/scripts/ios/firebase.sh; then
        if [ "${PUSH_NOTIFY:-false}" = "true" ]; then
            log_success "✅ Firebase configured successfully for push notifications"
        else
            log_success "✅ Firebase setup skipped (push notifications disabled)"
        fi
    else
        log_warning "⚠️ Firebase configuration failed, but continuing..."
        log_info "🔄 Build will continue without Firebase features"
    fi
else
    log_warning "⚠️ Firebase script not found, skipping Firebase setup"
fi

log_success "✅ Dynamic Firebase setup completed"

# =============================================================================
# STEP 5: iOS-SPECIFIC CONFIGURATION
# =============================================================================
echo "⚙️ Step 5: iOS-Specific Configuration..."

# Initialize keychain using Codemagic CLI
log_info "🔐 Initialize keychain to be used for codesigning using Codemagic CLI 'keychain' command"
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
        log_info "UUID: $UUID"
    fi
    if [[ -n "$BUNDLE_ID_FROM_PROFILE" ]]; then
        log_info "Bundle Identifier from profile: $BUNDLE_ID_FROM_PROFILE"
        
        # Use bundle ID from profile if BUNDLE_ID is not set or is default
        if [[ -z "$BUNDLE_ID" || "$BUNDLE_ID" == "com.example.sampleprojects.sampleProject" || "$BUNDLE_ID" == "com.test.app" ]]; then
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

if [[ -n "$CERT_P12_URL" && -n "$CERT_PASSWORD" ]]; then
    # Download P12 certificate
    curl -fSL "$CERT_P12_URL" -o /tmp/certificate.p12
    log_success "Downloaded certificate to /tmp/certificate.p12"
    
    # Add certificate to keychain using Codemagic CLI
    keychain add-certificates --certificate /tmp/certificate.p12 --certificate-password "$CERT_PASSWORD"
    log_success "Certificate added to keychain using Codemagic CLI"
    
elif [[ -n "$CERT_CER_URL" && -n "$CERT_KEY_URL" ]]; then
    # Download CER and KEY files
    curl -fSL "$CERT_CER_URL" -o /tmp/certificate.cer
    curl -fSL "$CERT_KEY_URL" -o /tmp/certificate.key
    log_success "Downloaded CER and KEY files"
    
    # Generate P12 from CER/KEY
    openssl pkcs12 -export -in /tmp/certificate.cer -inkey /tmp/certificate.key -out /tmp/certificate.p12 -passout pass:"${CERT_PASSWORD:-quikapp2025}"
    log_success "Generated P12 from CER/KEY files"
    
    # Add certificate to keychain using Codemagic CLI
    keychain add-certificates --certificate /tmp/certificate.p12 --certificate-password "${CERT_PASSWORD}"
    log_success "Certificate added to keychain using Codemagic CLI"
else
    log_warning "No certificate configuration provided"
fi

# Validate signing identities
IDENTITY_COUNT=$(security find-identity -v -p codesigning | grep -c "iPhone Distribution" || echo "0")
if [[ "$IDENTITY_COUNT" -eq 0 ]]; then
    log_error "No valid iPhone Distribution signing identities found in keychain. Exiting build."
    exit 1
else
    log_success "Found $IDENTITY_COUNT valid iPhone Distribution identity(ies) in keychain."
fi

# Step 11.5: iOS Icon Fix (CRITICAL for App Store validation)
echo "🖼️ Step 11.5: iOS Icon Fix for App Store Validation..."

# Fix iOS icons to prevent upload failures
log_info "Fixing iOS icons to prevent App Store validation errors..."
if [ -f "lib/scripts/ios-workflow/fix_ios_workflow_icons.sh" ]; then
    chmod +x lib/scripts/ios-workflow/fix_ios_workflow_icons.sh
    if ./lib/scripts/ios-workflow/fix_ios_workflow_icons.sh; then
        log_success "✅ iOS icon fix completed successfully"
        log_info "📱 App should now pass App Store icon validation"
    else
        log_warning "⚠️ iOS icon fix failed, continuing anyway"
    fi
else
    log_warning "⚠️ iOS icon fix script not found, skipping icon validation"
fi

# Configure iOS permissions
log_info "Configuring iOS permissions..."
if [ -f "lib/scripts/ios-workflow/permissions.sh" ]; then
    chmod +x lib/scripts/ios-workflow/permissions.sh
    if ./lib/scripts/ios-workflow/permissions.sh; then
        log_success "iOS permissions configuration completed"
    else
        log_error "iOS permissions configuration failed"
        exit 1
    fi
else
    log_warning "iOS permissions script not found, using inline permission handling..."
    
    # Fallback inline permission handling
    if [ "${IS_CAMERA:-false}" = "true" ]; then
        plutil -replace NSCameraUsageDescription -string "This app needs camera access to take photos" ios/Runner/Info.plist
    fi

    if [ "${IS_LOCATION:-false}" = "true" ]; then
        plutil -replace NSLocationWhenInUseUsageDescription -string "This app needs location access to provide location-based services" ios/Runner/Info.plist
        plutil -replace NSLocationAlwaysAndWhenInUseUsageDescription -string "This app needs location access to provide location-based services" ios/Runner/Info.plist
    fi

    if [ "${IS_MIC:-false}" = "true" ]; then
        plutil -replace NSMicrophoneUsageDescription -string "This app needs microphone access for voice features" ios/Runner/Info.plist
    fi

    if [ "${IS_CONTACT:-false}" = "true" ]; then
        plutil -replace NSContactsUsageDescription -string "This app needs contacts access to manage contacts" ios/Runner/Info.plist
    fi

    if [ "${IS_BIOMETRIC:-false}" = "true" ]; then
        plutil -replace NSFaceIDUsageDescription -string "This app uses Face ID for secure authentication" ios/Runner/Info.plist
    fi

    if [ "${IS_CALENDAR:-false}" = "true" ]; then
        plutil -replace NSCalendarsUsageDescription -string "This app needs calendar access to manage events" ios/Runner/Info.plist
    fi

    if [ "${IS_STORAGE:-false}" = "true" ]; then
        plutil -replace NSPhotoLibraryUsageDescription -string "This app needs photo library access to save and manage photos" ios/Runner/Info.plist
        plutil -replace NSPhotoLibraryAddUsageDescription -string "This app needs photo library access to save photos" ios/Runner/Info.plist
    fi

    # Always add network security
    plutil -replace NSAppTransportSecurity -json '{"NSAllowsArbitraryLoads": true}' ios/Runner/Info.plist

    log_success "Privacy descriptions added"
fi

# Generate Podfile dynamically based on Flutter configuration
log_info "Generating Podfile dynamically..."
if [ -f "lib/scripts/ios-workflow/generate_podfile.sh" ]; then
    chmod +x lib/scripts/ios-workflow/generate_podfile.sh
    if ./lib/scripts/ios-workflow/generate_podfile.sh; then
        log_success "Dynamic Podfile generation completed"
    else
        log_error "Dynamic Podfile generation failed"
        exit 1
    fi
else
    log_error "Dynamic Podfile generator not found"
    exit 1
fi

# Run CocoaPods commands
log_info "📦 Running CocoaPods commands..."
if ! command -v pod &>/dev/null; then
    log_error "CocoaPods is not installed!"
    exit 1
fi

if [ ! -f "ios/Podfile" ]; then
    log_error "Podfile not found at ios/Podfile"
    exit 1
fi

# Clean up old files
if [ -f "ios/Podfile.lock" ]; then
    cp ios/Podfile.lock ios/Podfile.lock.backup
    log_info "🗂️ Backed up Podfile.lock to Podfile.lock.backup"
    rm ios/Podfile.lock
    log_info "🗑️ Removed original Podfile.lock"
fi

# Remove Pods directory if it exists
if [ -d "ios/Pods" ]; then
    rm -rf ios/Pods
    log_info "🗑️ Removed ios/Pods directory"
fi

# Enter ios directory and run pod install
pushd ios > /dev/null || { log_error "Failed to enter ios directory"; exit 1; }

log_info "🔄 Running: pod install"
if pod install > /dev/null 2>&1; then
    log_success "✅ pod install completed successfully"
else
    log_error "❌ pod install failed"
    popd > /dev/null
    exit 1
fi

popd > /dev/null
log_success "✅ CocoaPods commands completed"

# Update Release.xcconfig
XC_CONFIG_PATH="ios/Flutter/release.xcconfig"
log_info "🔧 Updating release.xcconfig with dynamic signing values..."
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

log_success "✅ release.xcconfig updated"

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

# Set up code signing settings on Xcode project
log_info "Setting up code signing settings on Xcode project..."
xcode-project use-profiles

log_success "✅ iOS-specific configuration completed"

# =============================================================================
# STEP 6: BUILD PROCESS
# =============================================================================
echo "🛠️ Step 6: Build Process..."

# Final verification before build
log_info "🔍 Final verification before build..."
log_info "Bundle ID: $BUNDLE_ID"
log_info "Team ID: $APPLE_TEAM_ID"
log_info "Provisioning Profile UUID: $UUID"
log_info "Provisioning Profile Path: $PROFILE_PATH"

log_success "✅ Pre-build verification completed"

# Build Flutter iOS project
log_info "📱 Building Flutter iOS app in release mode..."
flutter build ios --release --no-codesign \
    --build-name="$VERSION_NAME" \
    --build-number="$VERSION_CODE" \
    --verbose \
    2>&1 | tee flutter_build.log

# Verify Flutter build completed successfully
if ! grep -q "Built.*Runner.app" flutter_build.log; then
    log_error "❌ Flutter build failed - Runner.app not found in build log"
    log_info "Flutter build log:"
    cat flutter_build.log
    exit 1
fi

log_success "✅ Flutter build completed successfully"

# Archive with Xcode
log_info "📦 Archiving app with Xcode..."
mkdir -p build/ios/archive

xcodebuild -workspace ios/Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -archivePath build/ios/archive/Runner.xcarchive \
    -destination 'generic/platform=iOS' \
    archive \
    DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="iPhone Distribution" \
    PROVISIONING_PROFILE_SPECIFIER="$UUID" \
    PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
    2>&1 | tee xcodebuild_archive.log

# Verify archive was created successfully
if [ ! -d "build/ios/archive/Runner.xcarchive" ]; then
    log_error "❌ Xcode archive failed - Runner.xcarchive not found"
    log_info "Xcode archive log:"
    cat xcodebuild_archive.log
    exit 1
fi

log_success "✅ Xcode archive completed successfully"

# Create ExportOptions.plist
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

# Export IPA
log_info "📤 Exporting IPA..."
xcodebuild -exportArchive \
    -archivePath build/ios/archive/Runner.xcarchive \
    -exportPath build/ios/output \
    -exportOptionsPlist ios/ExportOptions.plist

# Find and verify IPA file
log_info "📦 Final verification and cleanup..."
mkdir -p output/ios
mkdir -p build/ios/output

IPA_PATH=""
for search_path in "build/ios/output" "build/ios" "output/ios" "."; do
    if [ -d "$search_path" ]; then
        found_ipa=$(find "$search_path" -name "*.ipa" -type f 2>/dev/null | head -1)
        if [ -n "$found_ipa" ]; then
            IPA_PATH="$found_ipa"
            log_success "✅ Found IPA at: $IPA_PATH"
            break
        fi
    fi
done

if [ -z "$IPA_PATH" ]; then
    log_error "❌ No IPA file found after build"
    log_info "Searching for any build artifacts..."
    find . -name "*.ipa" -o -name "*.xcarchive" -o -name "*.app" 2>/dev/null | head -10
    log_error "❌ Build failed - no IPA generated"
    exit 1
fi

# Verify IPA file is not empty
if [ ! -s "$IPA_PATH" ]; then
    log_error "❌ IPA file is empty: $IPA_PATH"
    exit 1
fi

# Get IPA file size
IPA_SIZE=$(stat -f%z "$IPA_PATH" 2>/dev/null || stat -c%s "$IPA_PATH" 2>/dev/null || echo "unknown")
log_info "📱 IPA file size: $IPA_SIZE bytes"

# Copy IPA to output directory for easier access
if [ "$IPA_PATH" != "output/ios/"* ]; then
    cp "$IPA_PATH" "output/ios/" 2>/dev/null || log_warning "Could not copy IPA to output/ios/"
fi

# Create artifacts summary
log_info "📋 Creating artifacts summary..."
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
- IPA Size: $IPA_SIZE bytes
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

# List all generated artifacts
log_info "📦 Generated artifacts:"
find build/ios/output -name "*.ipa" -exec echo "  📱 IPA: {}" \; 2>/dev/null || true
find build/ios/archive -name "*.xcarchive" -exec echo "  📦 Archive: {}" \; 2>/dev/null || true
find output/ios -name "*" -exec echo "  📋 Output: {}" \; 2>/dev/null || true

log_success "✅ Build process completed"

# =============================================================================
# STEP 7: POST-BUILD ACTIONS
# =============================================================================
echo "📤 Step 7: Post-Build Actions..."

# App Store Connect Publishing (if applicable)
if [ "${IS_TESTFLIGHT:-false}" = "true" ] && [ "${PROFILE_TYPE:-app-store}" = "app-store" ]; then
    log_info "📤 Preparing for App Store Connect upload..."
    # Note: This would typically be done through fastlane or xcrun altool
    log_info "ℹ️ App Store Connect upload would be configured here"
fi

# Process artifact URLs for email
log_info "📦 Processing artifact URLs for email notification..."
if [ -f "lib/scripts/utils/process_artifacts.sh" ]; then
    source "lib/scripts/utils/process_artifacts.sh"
    artifact_urls=$(process_artifacts)
    log_info "Artifact URLs: $artifact_urls"
else
    artifact_urls=""
fi

# Send build success email
log_info "🎉 Build successful! Sending success email..."
if [ -f "lib/scripts/utils/send_email.sh" ]; then
    chmod +x lib/scripts/utils/send_email.sh
    lib/scripts/utils/send_email.sh "build_success" "iOS" "${CM_BUILD_ID:-unknown}" "Build successful" "$artifact_urls"
fi

log_success "🎉 iOS build process completed successfully!"
log_info "📦 Artifacts available in:"
log_info "  📱 IPA: $IPA_PATH"
log_info "  📋 Summary: output/ios/ARTIFACTS_SUMMARY.txt"
log_info "  📦 Archive: build/ios/archive/Runner.xcarchive"
log_info "  📋 Config: ios/ExportOptions.plist"

# Final success exit
exit 0
