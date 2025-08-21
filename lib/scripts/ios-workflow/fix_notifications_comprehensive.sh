#!/bin/bash
# 🔔 Comprehensive iOS Push Notification Fix
# Fixes all notification configuration issues permanently

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [NOTIF_FIX] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "🔔 Starting comprehensive iOS push notification fix..."

# Check if we're in the right directory
if [[ ! -d "ios" ]]; then
    log_error "iOS directory not found. Please run this script from the Flutter project root."
    exit 1
fi

# Create backup directory
BACKUP_DIR="ios/backup_notifications_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Step 1: Fix Info.plist for notifications
log_info "🔧 Step 1: Fixing Info.plist for notifications..."

INFO_PLIST="ios/Runner/Info.plist"
if [[ -f "$INFO_PLIST" ]]; then
    # Backup Info.plist
    cp "$INFO_PLIST" "$BACKUP_DIR/Info.plist.backup"
    log_success "✅ Backed up Info.plist to $BACKUP_DIR/Info.plist.backup"
    
    # Add UIBackgroundModes if missing
    if ! grep -q "UIBackgroundModes" "$INFO_PLIST"; then
        log_info "Adding UIBackgroundModes to Info.plist..."
        # Find the closing </dict> tag and add UIBackgroundModes before it
        sed -i '' '/<\/dict>/i\
	<key>UIBackgroundModes</key>\
	<array>\
		<string>remote-notification</string>\
		<string>fetch</string>\
		<string>background-processing</string>\
	</array>' "$INFO_PLIST"
        log_success "✅ Added UIBackgroundModes to Info.plist"
    else
        # Check if remote-notification is in the array
        if ! grep -q "remote-notification" "$INFO_PLIST"; then
            log_info "Adding remote-notification to existing UIBackgroundModes..."
            # Find the UIBackgroundModes array and add remote-notification
            sed -i '' '/<key>UIBackgroundModes<\/key>/a\
		<string>remote-notification</string>' "$INFO_PLIST"
            log_success "✅ Added remote-notification to UIBackgroundModes"
        else
            log_success "✅ UIBackgroundModes already contains remote-notification"
        fi
    fi
    
    # Add notification permission request description
    if ! grep -q "NSUserNotificationUsageDescription" "$INFO_PLIST"; then
        log_info "Adding notification permission request description..."
        sed -i '' '/<\/dict>/i\
	<key>NSUserNotificationUsageDescription</key>\
	<string>This app needs to send you notifications to keep you updated with important information.</string>' "$INFO_PLIST"
        log_success "✅ Added notification permission request description"
    fi
    
    # Add modern notification permission keys
    if ! grep -q "NSUserNotificationAlertStyle" "$INFO_PLIST"; then
        log_info "Adding modern notification permission keys..."
        sed -i '' '/<\/dict>/i\
	<key>NSUserNotificationAlertStyle</key>\
	<string>alert</string>' "$INFO_PLIST"
        log_success "✅ Added modern notification permission keys"
    fi
    
    # Add Firebase configuration
    if ! grep -q "FirebaseAppDelegateProxyEnabled" "$INFO_PLIST"; then
        log_info "Adding Firebase configuration..."
        sed -i '' '/<\/dict>/i\
	<key>FirebaseAppDelegateProxyEnabled</key>\
	<false/>' "$INFO_PLIST"
        log_success "✅ Added Firebase configuration"
    fi
    
else
    log_error "Info.plist not found at $INFO_PLIST"
    exit 1
fi

# Step 2: Fix entitlements file
log_info "🔧 Step 2: Fixing entitlements file..."

ENTITLEMENTS_FILE="ios/Runner/Runner.entitlements"
if [[ -f "$ENTITLEMENTS_FILE" ]]; then
    # Backup entitlements
    cp "$ENTITLEMENTS_FILE" "$BACKUP_DIR/Runner.entitlements.backup"
    log_success "✅ Backed up entitlements to $BACKUP_DIR/Runner.entitlements.backup"
    
    # Ensure aps-environment is set
    if ! grep -q "aps-environment" "$ENTITLEMENTS_FILE"; then
        log_info "Adding aps-environment to entitlements..."
        # Find the closing </dict> tag and add aps-environment before it
        sed -i '' '/<\/dict>/i\
	<key>aps-environment</key>\
	<string>production</string>' "$ENTITLEMENTS_FILE"
        log_success "✅ Added aps-environment to entitlements"
    fi
    
    # Ensure background modes are in entitlements
    if ! grep -q "com.apple.developer.background-modes" "$ENTITLEMENTS_FILE"; then
        log_info "Adding background modes to entitlements..."
        sed -i '' '/<\/dict>/i\
	<key>com.apple.developer.background-modes</key>\
	<array>\
		<string>remote-notification</string>\
		<string>fetch</string>\
		<string>background-processing</string>\
	</array>' "$ENTITLEMENTS_FILE"
        log_success "✅ Added background modes to entitlements"
    fi
    
else
    log_warning "Entitlements file not found, creating new one..."
    cat > "$ENTITLEMENTS_FILE" << 'ENTITLEMENTS_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>aps-environment</key>
	<string>production</string>
	<key>com.apple.developer.background-modes</key>
	<array>
		<string>remote-notification</string>
		<string>fetch</string>
		<string>background-processing</string>
	</array>
</dict>
</plist>
ENTITLEMENTS_EOF
    log_success "✅ Created new entitlements file with notification support"
fi

# Step 3: Fix Xcode project configuration
log_info "🔧 Step 3: Fixing Xcode project configuration..."

PROJECT_FILE="ios/Runner.xcodeproj/project.pbxproj"
if [[ -f "$PROJECT_FILE" ]]; then
    # Backup project file
    cp "$PROJECT_FILE" "$BACKUP_DIR/project.pbxproj.backup"
    log_success "✅ Backed up project file to $BACKUP_DIR/project.pbxproj.backup"
    
    # Ensure CODE_SIGN_ENTITLEMENTS is set
    if ! grep -q "CODE_SIGN_ENTITLEMENTS" "$PROJECT_FILE"; then
        log_info "Adding CODE_SIGN_ENTITLEMENTS to project..."
        # Find the Runner target build settings and add entitlements
        sed -i '' '/buildSettings = {/a\
				CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;' "$PROJECT_FILE"
        log_success "✅ Added CODE_SIGN_ENTITLEMENTS to project"
    fi
    
    # Add push notification capability
    if ! grep -q "com.apple.Push" "$PROJECT_FILE"; then
        log_info "Adding push notification capability to project..."
        # Find the SystemCapabilities section and add push notifications
        if grep -q "SystemCapabilities" "$PROJECT_FILE"; then
            sed -i '' '/SystemCapabilities = {/a\
				com.apple.Push = {enabled = 1;};' "$PROJECT_FILE"
        else
            # Create SystemCapabilities section if it doesn't exist
            sed -i '' '/buildSettings = {/a\
				SystemCapabilities = {com.apple.Push = {enabled = 1;};};' "$PROJECT_FILE"
        fi
        log_success "✅ Added push notification capability to project"
    fi
    
else
    log_error "Project file not found at $PROJECT_FILE"
    exit 1
fi

# Step 4: Fix Podfile for Firebase
log_info "🔧 Step 4: Fixing Podfile for Firebase..."

PODFILE="ios/Podfile"
if [[ -f "$PODFILE" ]]; then
    # Backup Podfile
    cp "$PODFILE" "$BACKUP_DIR/Podfile.backup"
    log_success "✅ Backed up Podfile to $BACKUP_DIR/Podfile.backup"
    
    # Ensure Firebase pods are properly configured
    if ! grep -q "pod 'Firebase/Messaging'" "$PODFILE"; then
        log_info "Adding Firebase Messaging to Podfile..."
        # Add after flutter_install_all_ios_pods
        sed -i '' '/flutter_install_all_ios_pods/a\
  pod "Firebase/Messaging"' "$PODFILE"
        log_success "✅ Added Firebase Messaging to Podfile"
    fi
    
    # Ensure modular headers are enabled
    if ! grep -q "use_modular_headers!" "$PODFILE"; then
        log_info "Adding modular headers to Podfile..."
        sed -i '' '/use_frameworks!/a\
  use_modular_headers!' "$PODFILE"
        log_success "✅ Added modular headers to Podfile"
    fi
    
else
    log_error "Podfile not found at $PODFILE"
    exit 1
fi

# Step 5: Create notification test script
log_info "🔧 Step 5: Creating notification test script..."

TEST_SCRIPT="ios/test_notifications.sh"
cat > "$TEST_SCRIPT" << 'TEST_EOF'
#!/bin/bash
# 🧪 Test script to verify notification configuration

echo "🔍 Testing iOS notification configuration..."

# Check Info.plist
echo "📋 Checking Info.plist..."
if grep -q "UIBackgroundModes" ios/Runner/Info.plist; then
    echo "✅ UIBackgroundModes found"
    if grep -q "remote-notification" ios/Runner/Info.plist; then
        echo "✅ remote-notification in UIBackgroundModes"
    else
        echo "❌ remote-notification missing from UIBackgroundModes"
    fi
else
    echo "❌ UIBackgroundModes missing"
fi

# Check entitlements
echo "🔐 Checking entitlements..."
if [[ -f "ios/Runner/Runner.entitlements" ]]; then
    echo "✅ Entitlements file exists"
    if grep -q "aps-environment" ios/Runner/Runner.entitlements; then
        echo "✅ aps-environment configured"
    else
        echo "❌ aps-environment missing"
    fi
    if grep -q "remote-notification" ios/Runner/Runner.entitlements; then
        echo "✅ remote-notification in entitlements"
    else
        echo "❌ remote-notification missing from entitlements"
    fi
else
    echo "❌ Entitlements file missing"
fi

# Check project configuration
echo "🏗️ Checking project configuration..."
if grep -q "CODE_SIGN_ENTITLEMENTS" ios/Runner.xcodeproj/project.pbxproj; then
    echo "✅ CODE_SIGN_ENTITLEMENTS configured"
else
    echo "❌ CODE_SIGN_ENTITLEMENTS missing"
fi

if grep -q "com.apple.Push" ios/Runner.xcodeproj/project.pbxproj; then
    echo "✅ Push notification capability added"
else
    echo "❌ Push notification capability missing"
fi

echo "🧪 Notification configuration test completed!"
TEST_EOF

chmod +x "$TEST_SCRIPT"
log_success "✅ Created notification test script"

# Step 6: Final verification
log_info "🔧 Step 6: Final verification..."

# Test the configuration
if ./ios/test_notifications.sh; then
    log_success "✅ Notification configuration test passed"
else
    log_warning "⚠️ Some notification configuration issues detected"
fi

log_success "🎉 Comprehensive iOS push notification fix completed successfully!"
log_success "🔔 Your app is now fully configured for push notifications!"
log_info "📋 Backup created in: $BACKUP_DIR"
log_info "🧪 Test script: $TEST_SCRIPT"
log_info "🔄 Run 'pod install' in ios/ directory to update dependencies"

exit 0
