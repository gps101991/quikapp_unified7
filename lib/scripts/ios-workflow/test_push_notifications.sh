#!/usr/bin/env bash

# 🔔 iOS Push Notification Testing Script
# Tests push notifications in all three app states and provides debugging information

set -euo pipefail

# Logging functions
log_info() { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error() { echo "❌ $1"; }
log_warning() { echo "⚠️ $1"; }

echo "🔔 iOS Push Notification Testing Script"
echo "======================================"

# Check if we're in the right directory
if [[ ! -d "ios" ]]; then
    log_error "❌ iOS directory not found. Please run this script from the project root."
    exit 1
fi

echo ""
echo "📱 Phase 1: iOS Project Configuration Check"
echo "=========================================="

# Check Info.plist
if [[ -f "ios/Runner/Info.plist" ]]; then
    log_success "✅ Info.plist found"
    
    # Check UIBackgroundModes
    if /usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" ios/Runner/Info.plist >/dev/null 2>&1; then
        log_success "✅ UIBackgroundModes configured"
        /usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" ios/Runner/Info.plist | grep -q "remote-notification" && \
            log_success "✅ remote-notification background mode present" || \
            log_error "❌ remote-notification background mode missing"
    else
        log_error "❌ UIBackgroundModes not configured"
    fi
    
    # Check FirebaseAppDelegateProxyEnabled
    if /usr/libexec/PlistBuddy -c "Print :FirebaseAppDelegateProxyEnabled" ios/Runner/Info.plist >/dev/null 2>&1; then
        log_success "✅ FirebaseAppDelegateProxyEnabled configured"
    else
        log_warning "⚠️ FirebaseAppDelegateProxyEnabled not configured"
    fi
else
    log_error "❌ Info.plist not found"
fi

# Check entitlements
if [[ -f "ios/Runner/Runner.entitlements" ]]; then
    log_success "✅ Runner.entitlements found"
    
    # Check aps-environment
    if /usr/libexec/PlistBuddy -c "Print :aps-environment" ios/Runner/Runner.entitlements >/dev/null 2>&1; then
        ENV_VALUE=$(/usr/libexec/PlistBuddy -c "Print :aps-environment" ios/Runner/Runner.entitlements)
        log_success "✅ aps-environment: $ENV_VALUE"
    else
        log_error "❌ aps-environment not configured in entitlements"
    fi
    
    # Check background modes
    if /usr/libexec/PlistBuddy -c "Print :com.apple.developer.background-modes" ios/Runner/Runner.entitlements >/dev/null 2>&1; then
        if /usr/libexec/PlistBuddy -c "Print :com.apple.developer.background-modes" ios/Runner/Runner.entitlements | grep -q "remote-notification"; then
            log_success "✅ Background modes include remote-notification"
        else
            log_error "❌ Background modes missing remote-notification"
        fi
    else
        log_error "❌ Background modes not configured in entitlements"
    fi
else
    log_error "❌ Runner.entitlements not found"
fi

# Check Xcode project capability
if [[ -f "ios/Runner.xcodeproj/project.pbxproj" ]]; then
    if grep -q "com.apple.Push" ios/Runner.xcodeproj/project.pbxproj; then
        log_success "✅ Push notification capability enabled in Xcode project"
    else
        log_error "❌ Push notification capability not found in Xcode project"
    fi
else
    log_error "❌ Project file not found"
fi

echo ""
echo "🔥 Phase 2: Firebase Configuration Check"
echo "======================================="

# Check Firebase config
if [[ -f "ios/Runner/GoogleService-Info.plist" ]]; then
    log_success "✅ GoogleService-Info.plist found"
    
    # Check required keys
    REQUIRED_KEYS=("API_KEY" "BUNDLE_ID" "GOOGLE_APP_ID" "CLIENT_ID")
    for key in "${REQUIRED_KEYS[@]}"; do
        if /usr/libexec/PlistBuddy -c "Print :$key" ios/Runner/GoogleService-Info.plist >/dev/null 2>&1; then
            log_success "✅ Firebase $key configured"
        else
            log_error "❌ Firebase $key missing"
        fi
    done
    
    # Check bundle ID consistency
    if [[ -f "ios/Runner/Info.plist" ]]; then
        FIREBASE_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" ios/Runner/GoogleService-Info.plist 2>/dev/null || echo "")
        PROJECT_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" ios/Runner/Info.plist 2>/dev/null || echo "")
        
        if [[ -n "$FIREBASE_BUNDLE_ID" && -n "$PROJECT_BUNDLE_ID" ]]; then
            if [[ "$FIREBASE_BUNDLE_ID" == "$PROJECT_BUNDLE_ID" ]]; then
                log_success "✅ Bundle ID matches: $FIREBASE_BUNDLE_ID"
            else
                log_error "❌ Bundle ID mismatch: Firebase=$FIREBASE_BUNDLE_ID, Project=$PROJECT_BUNDLE_ID"
            fi
        fi
    fi
else
    log_error "❌ GoogleService-Info.plist not found"
fi

echo ""
echo "📦 Phase 3: Podfile Configuration Check"
echo "======================================"

# Check Podfile
if [[ -f "ios/Podfile" ]]; then
    if grep -q "pod 'Firebase/Core'" ios/Podfile; then
        log_success "✅ Firebase/Core dependency found"
    else
        log_error "❌ Firebase/Core dependency missing"
    fi
    
    if grep -q "pod 'Firebase/Messaging'" ios/Podfile; then
        log_success "✅ Firebase/Messaging dependency found"
    else
        log_error "❌ Firebase/Messaging dependency missing"
    fi
    
    if grep -q "use_modular_headers!" ios/Podfile; then
        log_success "✅ use_modular_headers! found"
    else
        log_warning "⚠️ use_modular_headers! missing"
    fi
else
    log_error "❌ Podfile not found"
fi

echo ""
echo "🍎 Phase 4: APNS Configuration Check"
echo "==================================="

# Check APNS configuration
if [[ -n "${APNS_KEY_ID:-}" ]]; then
    log_success "✅ APNS_KEY_ID configured: $APNS_KEY_ID"
else
    log_warning "⚠️ APNS_KEY_ID not configured"
fi

if [[ -n "${APNS_AUTH_KEY_URL:-}" ]]; then
    log_success "✅ APNS_AUTH_KEY_URL configured"
    
    # Test URL accessibility
    if curl --output /dev/null --silent --head --fail "$APNS_AUTH_KEY_URL" 2>/dev/null; then
        log_success "✅ APNS auth key URL is accessible"
    else
        log_warning "⚠️ APNS auth key URL is not accessible"
    fi
else
    log_warning "⚠️ APNS_AUTH_KEY_URL not configured"
fi

echo ""
echo "🔑 Phase 5: Certificate Configuration Check"
echo "=========================================="

# Check certificate configuration
if [[ -n "${CERT_PASSWORD:-}" ]]; then
    log_success "✅ CERT_PASSWORD configured"
else
    log_error "❌ CERT_PASSWORD not configured"
fi

if [[ -n "${PROFILE_URL:-}" ]]; then
    log_success "✅ PROFILE_URL configured"
    
    # Test URL accessibility
    if curl --output /dev/null --silent --head --fail "$PROFILE_URL" 2>/dev/null; then
        log_success "✅ Provisioning profile URL is accessible"
    else
        log_warning "⚠️ Provisioning profile URL is not accessible"
    fi
else
    log_error "❌ PROFILE_URL not configured"
fi

echo ""
echo "🔍 Phase 6: Environment Variables Check"
echo "======================================"

# Check critical environment variables
CRITICAL_VARS=("PUSH_NOTIFY" "FIREBASE_CONFIG_IOS" "BUNDLE_ID" "PROFILE_TYPE")
for var in "${CRITICAL_VARS[@]}"; do
    if [[ -n "${!var:-}" ]]; then
        log_success "✅ $var configured: ${!var}"
    else
        log_error "❌ $var not configured"
    fi
done

echo ""
echo "📊 Phase 7: Summary and Recommendations"
echo "======================================"

# Count issues
ERROR_COUNT=$(grep -c "❌" <<< "$(cat $0)" || echo "0")
WARNING_COUNT=$(grep -c "⚠️" <<< "$(cat $0)" || echo "0")

echo ""
echo "📊 Configuration Summary:"
echo "========================="

if [[ $ERROR_COUNT -eq 0 ]]; then
    echo "🎉 All critical configurations are properly set!"
    echo "📱 Your iOS app should be able to receive push notifications"
    echo ""
    echo "🚀 Next Steps:"
    echo "1. Build and install the app on a device"
    echo "2. Grant notification permissions when prompted"
    echo "3. Test push notifications in all three states:"
    echo "   - 🔵 Background state (app in background)"
    echo "   - 🔴 Closed state (app terminated)"
    echo "   - 🟢 Opened state (app active)"
else
    echo "⚠️ Some configuration issues were found"
    echo "🔧 Please fix the errors above before testing push notifications"
    echo ""
    echo "❌ Critical issues: $ERROR_COUNT"
    echo "⚠️ Warnings: $WARNING_COUNT"
fi

echo ""
echo "🔔 Testing Push Notifications"
echo "============================="

echo ""
echo "📱 To test push notifications:"
echo "1. Install the app on a physical iOS device (not simulator)"
echo "2. Grant notification permissions when prompted"
echo "3. Send a test push notification using one of these methods:"
echo ""
echo "🔥 Method 1: Firebase Console"
echo "   - Go to Firebase Console > Cloud Messaging"
echo "   - Send test message to your app"
echo ""
echo "🍎 Method 2: APNS Test (for development)"
echo "   - Use tools like Push Notification Tester"
echo "   - Send to your device token"
echo ""
echo "📱 Method 3: Your Backend Server"
echo "   - Send push notification through your server"
echo "   - Use FCM or APNS depending on your setup"

echo ""
echo "🔍 Debug Information:"
echo "====================="

echo ""
echo "📋 To debug push notification issues:"
echo "1. Check device logs in Xcode Console"
echo "2. Verify notification permissions in iOS Settings"
echo "3. Check if APNS token is generated"
echo "4. Verify FCM token is received"
echo "5. Test with different app states"

echo ""
log_success "🔔 Push notification testing script completed!"
