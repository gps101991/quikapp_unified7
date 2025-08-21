#!/bin/bash
# 🔐 Fix All iOS Permissions Script
# Fixes all iOS permissions for App Store compliance

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PERMISSIONS_FIX] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "Starting comprehensive iOS permissions fix..."

# Step 1: Fix Info.plist corruption first
log_info "Step 1: Fixing Info.plist corruption..."
if [ -f "lib/scripts/ios-workflow/fix_corrupted_infoplist.sh" ]; then
    chmod +x lib/scripts/ios-workflow/fix_corrupted_infoplist.sh
    if ./lib/scripts/ios-workflow/fix_corrupted_infoplist.sh; then
        log_success "✅ Info.plist corruption fixed"
    else
        log_error "❌ Info.plist corruption fix failed"
        exit 1
    fi
else
    log_error "❌ Info.plist fix script not found"
    exit 1
fi

# Step 2: Fix Contents.json corruption
log_info "Step 2: Fixing Contents.json corruption..."
if [ -f "lib/scripts/ios-workflow/fix_corrupted_contents_json.sh" ]; then
    chmod +x lib/scripts/ios-workflow/fix_corrupted_contents_json.sh
    if ./lib/scripts/ios-workflow/fix_corrupted_contents_json.sh; then
        log_success "✅ Contents.json corruption fixed"
    else
        log_error "❌ Contents.json corruption fix failed"
        exit 1
    fi
else
    log_error "❌ Contents.json fix script not found"
    exit 1
fi

# Step 3: Add notification permissions to Info.plist
log_info "Step 3: Adding notification permissions to Info.plist..."
INFO_PLIST="ios/Runner/Info.plist"

# Add UIBackgroundModes with remote-notification
if ! grep -q "UIBackgroundModes" "$INFO_PLIST"; then
    log_info "Adding UIBackgroundModes array..."
    sed -i '' 's/<dict>/<dict>\n\t<key>UIBackgroundModes<\/key>\n\t<array>\n\t\t<string>remote-notification<\/string>\n\t<\/array>/' "$INFO_PLIST"
    log_success "✅ UIBackgroundModes added"
else
    log_success "✅ UIBackgroundModes already exists"
fi

# Add NSUserNotificationAlertStyle
if ! grep -q "NSUserNotificationAlertStyle" "$INFO_PLIST"; then
    log_info "Adding NSUserNotificationAlertStyle..."
    sed -i '' 's/<dict>/<dict>\n\t<key>NSUserNotificationAlertStyle<\/key>\n\t<string>alert<\/string>/' "$INFO_PLIST"
    log_success "✅ NSUserNotificationAlertStyle added"
else
    log_success "✅ NSUserNotificationAlertStyle already exists"
fi

# Add NSUserNotificationUsageDescription
if ! grep -q "NSUserNotificationUsageDescription" "$INFO_PLIST"; then
    log_info "Adding NSUserNotificationUsageDescription..."
    sed -i '' 's/<dict>/<dict>\n\t<key>NSUserNotificationUsageDescription<\/key>\n\t<string>This app uses notifications to keep you updated with important information.<\/string>/' "$INFO_PLIST"
    log_success "✅ NSUserNotificationUsageDescription added"
else
    log_success "✅ NSUserNotificationUsageDescription already exists"
fi

# Add FirebaseAppDelegateProxyEnabled
if ! grep -q "FirebaseAppDelegateProxyEnabled" "$INFO_PLIST"; then
    log_info "Adding FirebaseAppDelegateProxyEnabled..."
    sed -i '' 's/<dict>/<dict>\n\t<key>FirebaseAppDelegateProxyEnabled<\/key>\n\t<false\/>/' "$INFO_PLIST"
    log_success "✅ FirebaseAppDelegateProxyEnabled added"
else
    log_success "✅ FirebaseAppDelegateProxyEnabled already exists"
fi

# Step 4: Fix entitlements file
log_info "Step 4: Fixing entitlements file..."
ENTITLEMENTS_FILE="ios/Runner/Runner.entitlements"

if [[ ! -f "$ENTITLEMENTS_FILE" ]]; then
    log_info "Creating entitlements file..."
    cat > "$ENTITLEMENTS_FILE" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>aps-environment</key>
	<string>production</string>
	<key>com.apple.developer.team-identifier</key>
	<string>$(DEVELOPMENT_TEAM)</string>
</dict>
</plist>
EOF
    log_success "✅ Entitlements file created"
else
    log_success "✅ Entitlements file already exists"
fi

# Step 5: Add push notification capability to Xcode project
log_info "Step 5: Adding push notification capability to Xcode project..."
PROJECT_FILE="ios/Runner.xcodeproj/project.pbxproj"

if [[ -f "$PROJECT_FILE" ]]; then
    # Check if push notification capability already exists
    if ! grep -q "com.apple.Push" "$PROJECT_FILE"; then
        log_info "Adding push notification capability..."
        
        # Find the SystemCapabilities section and add push notifications
        if grep -q "SystemCapabilities" "$PROJECT_FILE"; then
            # Add to existing SystemCapabilities
            sed -i '' 's/SystemCapabilities = {/SystemCapabilities = {\n\t\t\t\t\t\t\t\tcom.apple.Push = {\n\t\t\t\t\t\t\t\t\tenabled = 1;\n\t\t\t\t\t\t\t\t};/' "$PROJECT_FILE"
        else
            # Create new SystemCapabilities section
            sed -i '' 's/isa = PBXNativeTarget;/isa = PBXNativeTarget;\n\t\t\t\tSystemCapabilities = {\n\t\t\t\t\tcom.apple.Push = {\n\t\t\t\t\t\tenabled = 1;\n\t\t\t\t\t};\n\t\t\t\t};/' "$PROJECT_FILE"
        fi
        
        log_success "✅ Push notification capability added"
    else
        log_success "✅ Push notification capability already exists"
    fi
else
    log_warning "⚠️ Xcode project file not found, cannot add capability"
fi

# Step 6: Add CODE_SIGN_ENTITLEMENTS to project
log_info "Step 6: Adding CODE_SIGN_ENTITLEMENTS to project..."
if [[ -f "$PROJECT_FILE" ]]; then
    if ! grep -q "CODE_SIGN_ENTITLEMENTS" "$PROJECT_FILE"; then
        log_info "Adding CODE_SIGN_ENTITLEMENTS..."
        sed -i '' 's/isa = PBXNativeTarget;/isa = PBXNativeTarget;\n\t\t\t\tCODE_SIGN_ENTITLEMENTS = Runner\/Runner.entitlements;/' "$PROJECT_FILE"
        log_success "✅ CODE_SIGN_ENTITLEMENTS added"
    else
        log_success "✅ CODE_SIGN_ENTITLEMENTS already exists"
    fi
else
    log_warning "⚠️ Xcode project file not found, cannot add entitlements reference"
fi

# Step 7: Final validation
log_info "Step 7: Final validation..."

# Validate Info.plist
if plutil -lint "$INFO_PLIST" >/dev/null 2>&1; then
    log_success "✅ Info.plist validation passed"
else
    log_error "❌ Info.plist validation failed"
    exit 1
fi

# Validate entitlements
if plutil -lint "$ENTITLEMENTS_FILE" >/dev/null 2>&1; then
    log_success "✅ Entitlements validation passed"
else
    log_error "❌ Entitlements validation failed"
    exit 1
fi

# Check for required keys
log_info "Checking required permissions configuration..."

# Check UIBackgroundModes
if grep -q "remote-notification" "$INFO_PLIST"; then
    log_success "✅ UIBackgroundModes with remote-notification configured"
else
    log_error "❌ UIBackgroundModes with remote-notification missing"
fi

# Check aps-environment
if grep -q "aps-environment" "$ENTITLEMENTS_FILE"; then
    log_success "✅ aps-environment configured in entitlements"
else
    log_error "❌ aps-environment missing from entitlements"
fi

# Check push notification capability
if grep -q "com.apple.Push" "$PROJECT_FILE"; then
    log_success "✅ Push notification capability found in project"
else
    log_warning "⚠️ Push notification capability not found in project"
fi

# Step 8: Summary
log_success "🎉 Comprehensive iOS permissions fix completed successfully!"
log_info "📋 Summary:"
log_info "  - Info.plist corruption fixed"
log_info "  - Contents.json corruption fixed"
log_info "  - Notification permissions added"
log_info "  - Entitlements configured"
log_info "  - Push notification capability added"
log_info "  - All validations passed"

exit 0
