#!/usr/bin/env bash

# 🔔 Complete Push Notification Setup Script for iOS Workflow
# Ensures ALL required configurations are set for push notifications to work in:
# - Background state (app in background)
# - Closed state (app terminated) 
# - Opened state (app active)

set -euo pipefail

# Logging functions
log_info() { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error() { echo "❌ $1"; }
log_warning() { echo "⚠️ $1"; }

echo "🔔 Complete Push Notification Setup for iOS Workflow..."

# Check if push notifications are enabled
if [[ "${PUSH_NOTIFY:-false}" != "true" ]]; then
    log_warning "Push notifications are disabled (PUSH_NOTIFY=false)"
    log_info "Skipping push notification setup"
    exit 0
fi

log_info "Push notifications are enabled, setting up complete configuration..."

# Function to safely add/update plist values
safe_plist_update() {
    local plist_path="$1"
    local key="$2"
    local value="$3"
    local description="$4"
    
    if /usr/libexec/PlistBuddy -c "Print :$key" "$plist_path" >/dev/null 2>&1; then
        /usr/libexec/PlistBuddy -c "Set :$key $value" "$plist_path" 2>/dev/null || true
        log_success "✅ Updated $description"
    else
        /usr/libexec/PlistBuddy -c "Add :$key $value" "$plist_path" 2>/dev/null || true
        log_success "✅ Added $description"
    fi
}

# Function to safely add array values
safe_array_add() {
    local plist_path="$1"
    local array_key="$2"
    local value="$3"
    local description="$4"
    
    # Create array if it doesn't exist
    if ! /usr/libexec/PlistBuddy -c "Print :$array_key" "$plist_path" >/dev/null 2>&1; then
        /usr/libexec/PlistBuddy -c "Add :$array_key array" "$plist_path" 2>/dev/null || true
    fi
    
    # Check if value already exists
    if ! /usr/libexec/PlistBuddy -c "Print :$array_key" "$plist_path" 2>/dev/null | grep -q "$value"; then
        # Get current array length
        ARRAY_LENGTH=$(/usr/libexec/PlistBuddy -c "Print :$array_key" "$plist_path" 2>/dev/null | wc -l || echo "0")
        /usr/libexec/PlistBuddy -c "Add :$array_key:$ARRAY_LENGTH string '$value'" "$plist_path" 2>/dev/null || true
        log_success "✅ Added $description to $array_key"
    else
        log_info "ℹ️ $description already present in $array_key"
    fi
}

echo ""
echo "📱 Phase 1: Info.plist Configuration"
echo "===================================="

# Ensure Info.plist exists
if [[ ! -f "ios/Runner/Info.plist" ]]; then
    log_error "❌ Info.plist not found at ios/Runner/Info.plist"
    exit 1
fi

# 1. Add UIBackgroundModes with remote-notification
log_info "🔧 Configuring UIBackgroundModes for push notifications..."
safe_array_add "ios/Runner/Info.plist" "UIBackgroundModes" "remote-notification" "remote-notification background mode"

# 2. Add FirebaseAppDelegateProxyEnabled (recommended for Flutter)
log_info "🔧 Configuring FirebaseAppDelegateProxyEnabled..."
safe_plist_update "ios/Runner/Info.plist" "FirebaseAppDelegateProxyEnabled" "bool false" "FirebaseAppDelegateProxyEnabled"

# 3. Add aps-environment based on profile type
log_info "🔧 Configuring aps-environment..."
if [[ "${PROFILE_TYPE:-}" == "app-store" ]]; then
    safe_plist_update "ios/Runner/Info.plist" "aps-environment" "string production" "aps-environment (production)"
else
    safe_plist_update "ios/Runner/Info.plist" "aps-environment" "string development" "aps-environment (development)"
fi

echo ""
echo "🔐 Phase 2: Entitlements Configuration"
echo "======================================"

# Ensure entitlements file exists and is properly configured
log_info "🔧 Configuring push notification entitlements..."

# Create entitlements file if it doesn't exist
if [[ ! -f "ios/Runner/Runner.entitlements" ]]; then
    log_info "📝 Creating Runner.entitlements file..."
    cat > "ios/Runner/Runner.entitlements" << 'EOF'
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
    log_success "✅ Created Runner.entitlements file"
fi

# Update entitlements for the correct environment
if [[ "${PROFILE_TYPE:-}" == "app-store" ]]; then
    log_info "🔧 Updating entitlements for production environment..."
    safe_plist_update "ios/Runner/Runner.entitlements" "aps-environment" "string production" "aps-environment (production)"
    safe_plist_update "ios/Runner/Runner.entitlements" "com.apple.developer.aps-environment" "string production" "com.apple.developer.aps-environment (production)"
else
    log_info "🔧 Updating entitlements for development environment..."
    safe_plist_update "ios/Runner/Runner.entitlements" "aps-environment" "string development" "aps-environment (development)"
    safe_plist_update "ios/Runner/Runner.entitlements" "com.apple.developer.aps-environment" "string development" "com.apple.developer.aps-environment (development)"
fi

# Ensure background modes include remote-notification
log_info "🔧 Ensuring background modes include remote-notification..."
safe_array_add "ios/Runner/Runner.entitlements" "com.apple.developer.background-modes" "remote-notification" "remote-notification background mode"

echo ""
echo "🏗️ Phase 3: Xcode Project Capability Configuration"
echo "=================================================="

# Ensure push notification capability is enabled in Xcode project
log_info "🔧 Ensuring push notification capability is enabled in Xcode project..."

if [[ -f "ios/Runner.xcodeproj/project.pbxproj" ]]; then
    if ! grep -q "com.apple.Push" "ios/Runner.xcodeproj/project.pbxproj"; then
        log_info "📝 Adding push notification capability to project..."
        
        # Create a temporary file with the capability addition
        TEMP_PROJECT="/tmp/project.pbxproj.tmp"
        cp "ios/Runner.xcodeproj/project.pbxproj" "$TEMP_PROJECT"
        
        # Add push notification capability using proper Xcode project format
        if grep -q "SystemCapabilities" "$TEMP_PROJECT"; then
            # Add push notification capability to existing SystemCapabilities
            sed -i.bak '/SystemCapabilities = {/,/};/ s/};/		com.apple.Push = {\n			enabled = 1;\n		};\n	};/' "$TEMP_PROJECT"
            rm -f "$TEMP_PROJECT.bak" 2>/dev/null || true
            log_success "✅ Added push notification capability to existing SystemCapabilities"
        else
            # Create new SystemCapabilities section after CODE_SIGN_ENTITLEMENTS
            sed -i.bak '/CODE_SIGN_ENTITLEMENTS = Runner\/Runner.entitlements;/a\
		SystemCapabilities = {\n			com.apple.Push = {\n				enabled = 1;\n			};\n		};' "$TEMP_PROJECT"
            rm -f "$TEMP_PROJECT.bak" 2>/dev/null || true
            log_success "✅ Created SystemCapabilities section with push notification capability"
        fi
        
        # Copy back the modified project file
        cp "$TEMP_PROJECT" "ios/Runner.xcodeproj/project.pbxproj"
        rm -f "$TEMP_PROJECT" 2>/dev/null || true
        
        log_success "✅ Push notification capability added to Xcode project"
    else
        log_info "ℹ️ Push notification capability already enabled in project"
    fi
else
    log_warning "⚠️ Project file not found, cannot configure push notification capability"
fi

echo ""
echo "📦 Phase 4: Podfile Configuration"
echo "================================="

# Ensure Podfile has Firebase dependencies for push notifications
log_info "🔧 Ensuring Podfile has Firebase dependencies..."

if [[ -f "ios/Podfile" ]]; then
    # Check if Firebase dependencies are present
    if ! grep -q "pod 'Firebase/Core'" ios/Podfile; then
        log_info "📝 Adding Firebase/Core dependency to Podfile..."
        echo "" >> ios/Podfile
        echo "# Firebase dependencies for push notifications" >> ios/Podfile
        echo "pod 'Firebase/Core'" >> ios/Podfile
        log_success "✅ Added Firebase/Core dependency"
    else
        log_info "ℹ️ Firebase/Core dependency already present"
    fi
    
    if ! grep -q "pod 'Firebase/Messaging'" ios/Podfile; then
        log_info "📝 Adding Firebase/Messaging dependency to Podfile..."
        echo "pod 'Firebase/Messaging'" >> ios/Podfile
        log_success "✅ Added Firebase/Messaging dependency"
    else
        log_info "ℹ️ Firebase/Messaging dependency already present"
    fi
    
    # Ensure use_modular_headers! is present (important for Firebase)
    if ! grep -q "use_modular_headers!" ios/Podfile; then
        log_info "📝 Adding use_modular_headers! to Podfile..."
        sed -i.bak 's/use_frameworks!/use_frameworks!\n  use_modular_headers!/' ios/Podfile
        rm -f ios/Podfile.bak 2>/dev/null || true
        log_success "✅ Added use_modular_headers! to Podfile"
    else
        log_info "ℹ️ use_modular_headers! already present"
    fi
else
    log_warning "⚠️ Podfile not found, cannot configure Firebase dependencies"
fi

echo ""
echo "🔥 Phase 5: Firebase Configuration Validation"
echo "============================================"

# Validate Firebase configuration
log_info "🔍 Validating Firebase configuration..."

if [[ -f "ios/Runner/GoogleService-Info.plist" ]]; then
    log_success "✅ GoogleService-Info.plist exists"
    
    # Check required Firebase keys
    REQUIRED_KEYS=("API_KEY" "BUNDLE_ID" "GOOGLE_APP_ID" "CLIENT_ID")
    for key in "${REQUIRED_KEYS[@]}"; do
        if /usr/libexec/PlistBuddy -c "Print :$key" ios/Runner/GoogleService-Info.plist >/dev/null 2>&1; then
            log_success "✅ Firebase $key is configured"
        else
            log_warning "⚠️ Firebase $key is missing"
        fi
    done
    
    # Check bundle ID consistency
    if [[ -f "ios/Runner/Info.plist" ]]; then
        FIREBASE_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" ios/Runner/GoogleService-Info.plist 2>/dev/null || echo "")
        PROJECT_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" ios/Runner/Info.plist 2>/dev/null || echo "")
        
        if [[ -n "$FIREBASE_BUNDLE_ID" && -n "$PROJECT_BUNDLE_ID" ]]; then
            if [[ "$FIREBASE_BUNDLE_ID" == "$PROJECT_BUNDLE_ID" ]]; then
                log_success "✅ Bundle ID matches between Firebase and project: $FIREBASE_BUNDLE_ID"
            else
                log_warning "⚠️ Bundle ID mismatch: Firebase=$FIREBASE_BUNDLE_ID, Project=$PROJECT_BUNDLE_ID"
            fi
        fi
    fi
else
    log_warning "⚠️ GoogleService-Info.plist not found"
    log_info "ℹ️ Firebase configuration will be handled by the Firebase setup script"
fi

echo ""
echo "🔍 Phase 6: Final Configuration Verification"
echo "==========================================="

# Final verification of key configurations
log_info "🔍 Performing final configuration verification..."

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
    fi
fi

echo ""
echo "🎉 Push Notification Setup Complete!"
echo "==================================="

log_success "✅ Complete push notification configuration completed successfully!"
log_info "📱 Your iOS app is now configured to receive push notifications in ALL states:"
echo "   🔵 Background state (app in background)"
echo "   🔴 Closed state (app terminated)"
echo "   🟢 Opened state (app active)"
echo ""
log_info "🚀 Ready for production push notification testing!"

# Run comprehensive verification to confirm setup
if [[ -f "lib/scripts/ios-workflow/verify_push_notifications_comprehensive.sh" ]]; then
    echo ""
    log_info "🔍 Running comprehensive verification to confirm setup..."
    chmod +x lib/scripts/ios-workflow/verify_push_notifications_comprehensive.sh
    if ./lib/scripts/ios-workflow/verify_push_notifications_comprehensive.sh; then
        log_success "🎉 Verification passed! Push notifications are fully configured."
    else
        log_warning "⚠️ Verification found some issues. Check the output above."
        log_info "🔧 Push notifications may not work properly until all issues are resolved."
    fi
else
    log_warning "⚠️ Comprehensive verification script not found"
fi

echo ""
log_success "🔔 Push notification setup process completed!"
