#!/bin/bash
# 🔧 Fix Corrupted Info.plist Script
# Repairs corrupted Info.plist files that cause iOS workflow failures

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFOPLIST_FIX] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "Starting corrupted Info.plist fix..."

# Step 1: Check if Info.plist exists and is readable
log_info "Step 1: Checking Info.plist status..."
INFO_PLIST="ios/Runner/Info.plist"

if [[ ! -f "$INFO_PLIST" ]]; then
    log_error "Info.plist not found at: $INFO_PLIST"
    exit 1
fi

if [[ ! -r "$INFO_PLIST" ]]; then
    log_error "Info.plist is not readable"
    exit 1
fi

log_success "Info.plist found and readable"

# Step 2: Create backup of current Info.plist
log_info "Step 2: Creating backup of current Info.plist..."
BACKUP_FILE="ios/Runner/Info.plist.backup.$(date +%Y%m%d_%H%M%S)"
cp "$INFO_PLIST" "$BACKUP_FILE"
log_success "Backup created: $BACKUP_FILE"

# Step 3: Try to validate Info.plist
log_info "Step 3: Validating Info.plist structure..."
if plutil -lint "$INFO_PLIST" > /dev/null 2>&1; then
    log_success "Info.plist is valid, no corruption detected"
    log_info "Checking for bundle ID consistency..."
    
    # Check bundle ID
    if grep -q "CFBundleIdentifier" "$INFO_PLIST"; then
        BUNDLE_ID=$(grep -A1 "CFBundleIdentifier" "$INFO_PLIST" | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
        log_info "Current bundle ID: $BUNDLE_ID"
    else
        log_warning "CFBundleIdentifier not found in Info.plist"
    fi
    
    exit 0
else
    log_warning "Info.plist validation failed, attempting repair..."
fi

# Step 4: Attempt to repair corrupted Info.plist
log_info "Step 4: Attempting to repair corrupted Info.plist..."

# Try to extract valid content and rebuild
TEMP_FILE="ios/Runner/Info.plist.temp"

# Create a clean Info.plist template
cat > "$TEMP_FILE" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>$(CFBundleDevelopmentRegion)</string>
	<key>CFBundleDisplayName</key>
	<string>$(CFBundleDisplayName)</string>
	<key>CFBundleExecutable</key>
	<string>$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>$(PRODUCT_NAME)</string>
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
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsArbitraryLoads</key>
		<true/>
	</dict>
</dict>
</plist>
EOF

log_success "Created clean Info.plist template"

# Step 5: Replace corrupted Info.plist with clean template
log_info "Step 5: Replacing corrupted Info.plist..."
mv "$TEMP_FILE" "$INFO_PLIST"
log_success "Info.plist replaced with clean template"

# Step 6: Validate the new Info.plist
log_info "Step 6: Validating repaired Info.plist..."
if plutil -lint "$INFO_PLIST" > /dev/null 2>&1; then
    log_success "Repaired Info.plist is now valid"
else
    log_error "Repaired Info.plist is still invalid"
    log_info "Restoring from backup..."
    cp "$BACKUP_FILE" "$INFO_PLIST"
    exit 1
fi

# Step 7: Add dynamic bundle ID if environment variable is set
log_info "Step 7: Setting dynamic bundle ID..."
if [[ -n "${BUNDLE_ID:-}" ]]; then
    log_info "Setting bundle ID to: $BUNDLE_ID"
    
    # Update bundle ID in Info.plist
    plutil -replace CFBundleIdentifier -string "$BUNDLE_ID" "$INFO_PLIST"
    
    # Verify the change
    UPDATED_BUNDLE_ID=$(plutil -extract CFBundleIdentifier raw "$INFO_PLIST")
    if [[ "$UPDATED_BUNDLE_ID" == "$BUNDLE_ID" ]]; then
        log_success "Bundle ID updated successfully to: $UPDATED_BUNDLE_ID"
    else
        log_error "Failed to update bundle ID"
        exit 1
    fi
else
    log_warning "BUNDLE_ID environment variable not set, using default"
fi

# Step 8: Add permission descriptions if environment variables are set
log_info "Step 8: Adding permission descriptions..."

# Camera permission
if [[ "${IS_CAMERA:-false}" == "true" ]]; then
    plutil -replace NSCameraUsageDescription -string "This app needs camera access to take photos" "$INFO_PLIST"
    log_success "Added camera permission description"
fi

# Location permission
if [[ "${IS_LOCATION:-false}" == "true" ]]; then
    plutil -replace NSLocationWhenInUseUsageDescription -string "This app needs location access to provide location-based services" "$INFO_PLIST"
    plutil -replace NSLocationAlwaysAndWhenInUseUsageDescription -string "This app needs location access to provide location-based services" "$INFO_PLIST"
    log_success "Added location permission descriptions"
fi

# Microphone permission
if [[ "${IS_MIC:-false}" == "true" ]]; then
    plutil -replace NSMicrophoneUsageDescription -string "This app needs microphone access for voice features" "$INFO_PLIST"
    log_success "Added microphone permission description"
fi

# Contacts permission
if [[ "${IS_CONTACT:-false}" == "true" ]]; then
    plutil -replace NSContactsUsageDescription -string "This app needs contacts access to manage contacts" "$INFO_PLIST"
    log_success "Added contacts permission description"
fi

# Biometric permission
if [[ "${IS_BIOMETRIC:-false}" == "true" ]]; then
    plutil -replace NSFaceIDUsageDescription -string "This app uses Face ID for secure authentication" "$INFO_PLIST"
    log_success "Added biometric permission description"
fi

# Calendar permission
if [[ "${IS_CALENDAR:-false}" == "true" ]]; then
    plutil -replace NSCalendarsUsageDescription -string "This app needs calendar access to manage events" "$INFO_PLIST"
    log_success "Added calendar permission description"
fi

# Storage permission
if [[ "${IS_STORAGE:-false}" == "true" ]]; then
    plutil -replace NSPhotoLibraryUsageDescription -string "This app needs photo library access to save and manage photos" "$INFO_PLIST"
    plutil -replace NSPhotoLibraryAddUsageDescription -string "This app needs photo library access to save photos" "$INFO_PLIST"
    log_success "Added storage permission descriptions"
fi

# Step 9: Final validation
log_info "Step 9: Final validation..."

# Validate Info.plist syntax
if plutil -lint "$INFO_PLIST" > /dev/null 2>&1; then
    log_success "Final Info.plist validation passed"
else
    log_error "Final Info.plist validation failed"
    log_info "Restoring from backup..."
    cp "$BACKUP_FILE" "$INFO_PLIST"
    exit 1
fi

# Check bundle ID
if [[ -n "${BUNDLE_ID:-}" ]]; then
    CURRENT_BUNDLE_ID=$(plutil -extract CFBundleIdentifier raw "$INFO_PLIST")
    if [[ "$CURRENT_BUNDLE_ID" == "$BUNDLE_ID" ]]; then
        log_success "Bundle ID verification passed: $CURRENT_BUNDLE_ID"
    else
        log_error "Bundle ID verification failed. Expected: $BUNDLE_ID, Got: $CURRENT_BUNDLE_ID"
        exit 1
    fi
fi

# Step 10: Summary
log_info "📋 Info.plist Fix Summary:"
echo "=========================================="
echo "✅ Corrupted Info.plist detected and repaired"
echo "✅ Clean template applied"
echo "✅ Bundle ID set to: ${BUNDLE_ID:-default}"
echo "✅ Permission descriptions added based on environment"
echo "✅ Final validation passed"
echo "✅ Backup created at: $BACKUP_FILE"
echo "=========================================="

log_success "🎉 Corrupted Info.plist fix completed successfully!"
log_info "📱 Your iOS workflow should now proceed without Info.plist errors"
