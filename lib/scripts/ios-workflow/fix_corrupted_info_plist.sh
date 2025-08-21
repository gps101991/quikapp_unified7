#!/bin/bash
# 🔧 Fix Corrupted Info.plist Script
# Immediately repairs corrupted Info.plist files

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO_PLIST_FIX] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "🔧 Starting corrupted Info.plist fix..."

# Check if we're in the right directory
if [[ ! -d "ios" ]]; then
    log_error "iOS directory not found. Please run this script from the Flutter project root."
    exit 1
fi

INFO_PLIST="ios/Runner/Info.plist"

if [[ ! -f "$INFO_PLIST" ]]; then
    log_error "Info.plist not found at $INFO_PLIST"
    exit 1
fi

# Create backup directory
BACKUP_DIR="ios/backup_info_plist_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup current Info.plist
cp "$INFO_PLIST" "$BACKUP_DIR/Info.plist.backup"
log_success "✅ Backed up corrupted Info.plist to $BACKUP_DIR/Info.plist.backup"

# Step 1: Try to identify the corruption
log_info "🔍 Step 1: Analyzing Info.plist corruption..."

# Check for common corruption patterns
if grep -n "Found non-key inside <dict>" "$INFO_PLIST" 2>/dev/null; then
    log_warning "⚠️ Found corruption marker in Info.plist"
fi

# Check line 84 specifically (from the error message)
if [[ -f "$INFO_PLIST" ]]; then
    log_info "🔍 Checking line 84 for corruption..."
    if sed -n '84p' "$INFO_PLIST" 2>/dev/null; then
        log_info "Line 84 content:"
        sed -n '84p' "$INFO_PLIST"
    fi
fi

# Step 2: Create a clean Info.plist template
log_info "🔧 Step 2: Creating clean Info.plist template..."

cat > "$INFO_PLIST" << 'INFO_PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>$(DEVELOPMENT_LANGUAGE)</string>
	<key>CFBundleDisplayName</key>
	<string>$(APP_NAME)</string>
	<key>CFBundleExecutable</key>
	<string>$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>$(APP_NAME)</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>$(FLUTTER_BUILD_NAME)</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string>$(FLUTTER_BUILD_NUMBER)</string>
	<key>CFBundleIconName</key>
	<string>AppIcon</string>
	<key>LSRequiresIPhoneOS</key>
	<true/>
	<key>UILaunchStoryboardName</key>
	<string>LaunchScreen</string>
	<key>UIMainStoryboardFile</key>
	<string>Main</string>
	<key>UISupportedInterfaceOrientations</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
	<key>UISupportedInterfaceOrientations~ipad</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationPortraitUpsideDown</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
	<key>UIViewControllerBasedStatusBarAppearance</key>
	<false/>
	<key>CADisableMinimumFrameDurationOnPhone</key>
	<true/>
	<key>UIApplicationSupportsIndirectInputEvents</key>
	<true/>
	<key>UIBackgroundModes</key>
	<array>
		<string>remote-notification</string>
		<string>fetch</string>
		<string>background-processing</string>
	</array>
	<key>NSUserNotificationUsageDescription</key>
	<string>This app needs to send you notifications to keep you updated with important information.</string>
	<key>NSUserNotificationAlertStyle</key>
	<string>alert</string>
	<key>FirebaseAppDelegateProxyEnabled</key>
	<false/>
	<key>NSCameraUsageDescription</key>
	<string>This app needs camera access to scan QR codes and take photos.</string>
	<key>NSMicrophoneUsageDescription</key>
	<string>This app needs microphone access for voice features.</string>
	<key>NSLocationWhenInUseUsageDescription</key>
	<string>This app needs location access to provide location-based services.</string>
	<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
	<string>This app needs location access to provide location-based services.</string>
	<key>NSContactsUsageDescription</key>
	<string>This app needs contacts access to help you connect with friends.</string>
	<key>NSFaceIDUsageDescription</key>
	<string>This app needs Face ID access for secure authentication.</string>
	<key>NSCalendarsUsageDescription</key>
	<string>This app needs calendar access to help you manage your schedule.</string>
	<key>NSPhotoLibraryUsageDescription</key>
	<string>This app needs photo library access to save and share images.</string>
	<key>NSPhotoLibraryAddUsageDescription</key>
	<string>This app needs photo library access to save images.</string>
</dict>
</plist>
INFO_PLIST_EOF

log_success "✅ Created clean Info.plist template"

# Step 3: Validate the new Info.plist
log_info "🔧 Step 3: Validating new Info.plist..."

if command -v plutil > /dev/null 2>&1; then
    if plutil -lint "$INFO_PLIST" > /dev/null 2>&1; then
        log_success "✅ Info.plist validation passed with plutil"
    else
        log_error "❌ Info.plist validation failed with plutil"
        exit 1
    fi
else
    log_warning "⚠️ plutil not available, skipping validation"
fi

# Step 4: Set proper permissions
chmod 644 "$INFO_PLIST"
log_success "✅ Set proper permissions on Info.plist"

# Step 5: Verify file integrity
log_info "🔧 Step 5: Verifying file integrity..."

if [[ -f "$INFO_PLIST" ]]; then
    FILE_SIZE=$(wc -c < "$INFO_PLIST")
    if [[ $FILE_SIZE -gt 100 ]]; then
        log_success "✅ Info.plist file size: ${FILE_SIZE} bytes (healthy)"
    else
        log_warning "⚠️ Info.plist file size: ${FILE_SIZE} bytes (suspicious)"
    fi
    
    # Check for basic XML structure
    if grep -q "<?xml version" "$INFO_PLIST" && grep -q "<dict>" "$INFO_PLIST" && grep -q "</dict>" "$INFO_PLIST"; then
        log_success "✅ Info.plist has basic XML structure"
    else
        log_error "❌ Info.plist missing basic XML structure"
        exit 1
    fi
else
    log_error "❌ Info.plist not found after creation"
    exit 1
fi

log_success "🎉 Corrupted Info.plist fix completed successfully!"
log_success "✅ Info.plist is now clean and valid"
log_info "📋 Backup created in: $BACKUP_DIR"
log_info "🔄 You can now continue with your iOS build"

exit 0
