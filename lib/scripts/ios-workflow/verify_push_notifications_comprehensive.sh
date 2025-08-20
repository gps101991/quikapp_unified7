#!/usr/bin/env bash

# 🔔 Comprehensive Push Notification Verification Script for iOS Workflow
# Verifies ALL required configurations for iOS push notifications to work in:
# - Background state (app in background)
# - Closed state (app terminated)
# - Opened state (app active)

set -euo pipefail

# Logging functions
log_info() { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error() { echo "❌ $1"; }
log_warning() { echo "⚠️ $1"; }

echo "🔍 Comprehensive Push Notification Verification for iOS Workflow..."

# Initialize counters
SUCCESS_COUNT=0
ERROR_COUNT=0
WARNING_COUNT=0

# Check if push notifications are enabled
if [[ "${PUSH_NOTIFY:-false}" != "true" ]]; then
    log_warning "Push notifications are disabled (PUSH_NOTIFY=false)"
    log_info "This verification is not needed when push notifications are disabled"
    exit 0
fi

log_info "Push notifications are enabled, performing comprehensive verification..."

echo ""
echo "📱 Phase 1: Firebase Configuration Verification"
echo "=============================================="

# 1. Check Firebase configuration
if [[ -f "ios/Runner/GoogleService-Info.plist" ]]; then
    log_success "✅ GoogleService-Info.plist exists"
    ((SUCCESS_COUNT++))
    
    # Verify Firebase config has required keys
    if /usr/libexec/PlistBuddy -c "Print :API_KEY" ios/Runner/GoogleService-Info.plist >/dev/null 2>&1; then
        log_success "✅ Firebase API_KEY is configured"
        ((SUCCESS_COUNT++))
    else
        log_error "❌ Firebase API_KEY is missing"
        ((ERROR_COUNT++))
    fi
    
    if /usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" ios/Runner/GoogleService-Info.plist >/dev/null 2>&1; then
        FIREBASE_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" ios/Runner/GoogleService-Info.plist)
        log_success "✅ Firebase BUNDLE_ID is configured: $FIREBASE_BUNDLE_ID"
        ((SUCCESS_COUNT++))
    else
        log_error "❌ Firebase BUNDLE_ID is missing"
        ((ERROR_COUNT++))
    fi
    
    if /usr/libexec/PlistBuddy -c "Print :GOOGLE_APP_ID" ios/Runner/GoogleService-Info.plist >/dev/null 2>&1; then
        log_success "✅ Firebase GOOGLE_APP_ID is configured"
        ((SUCCESS_COUNT++))
    else
        log_error "❌ Firebase GOOGLE_APP_ID is missing"
        ((ERROR_COUNT++))
    fi
    
    if /usr/libexec/PlistBuddy -c "Print :CLIENT_ID" ios/Runner/GoogleService-Info.plist >/dev/null 2>&1; then
        log_success "✅ Firebase CLIENT_ID is configured"
        ((SUCCESS_COUNT++))
    else
        log_error "❌ Firebase CLIENT_ID is missing"
        ((ERROR_COUNT++))
    fi
else
    log_error "❌ GoogleService-Info.plist not found"
    ((ERROR_COUNT++))
fi

echo ""
echo "📝 Phase 2: Info.plist Configuration Verification"
echo "================================================"

# 2. Check Info.plist configuration
if [[ -f "ios/Runner/Info.plist" ]]; then
    # Check UIBackgroundModes for remote-notification
    if /usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" ios/Runner/Info.plist >/dev/null 2>&1; then
        if /usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" ios/Runner/Info.plist | grep -q "remote-notification"; then
            log_success "✅ UIBackgroundModes includes remote-notification"
            ((SUCCESS_COUNT++))
        else
            log_error "❌ UIBackgroundModes missing remote-notification"
            ((ERROR_COUNT++))
        fi
    else
        log_error "❌ UIBackgroundModes not configured"
        ((ERROR_COUNT++))
    fi
    
    # Check FirebaseAppDelegateProxyEnabled
    if /usr/libexec/PlistBuddy -c "Print :FirebaseAppDelegateProxyEnabled" ios/Runner/Info.plist >/dev/null 2>&1; then
        FIREBASE_PROXY=$(/usr/libexec/PlistBuddy -c "Print :FirebaseAppDelegateProxyEnabled" ios/Runner/Info.plist)
        log_success "✅ FirebaseAppDelegateProxyEnabled is configured: $FIREBASE_PROXY"
        ((SUCCESS_COUNT++))
    else
        log_warning "⚠️ FirebaseAppDelegateProxyEnabled not configured"
        ((WARNING_COUNT++))
    fi
    
    # Check aps-environment
    if /usr/libexec/PlistBuddy -c "Print :aps-environment" ios/Runner/Info.plist >/dev/null 2>&1; then
        APS_ENV=$(/usr/libexec/PlistBuddy -c "Print :aps-environment" ios/Runner/Info.plist)
        log_success "✅ aps-environment is configured: $APS_ENV"
        ((SUCCESS_COUNT++))
    else
        log_warning "⚠️ aps-environment not configured in Info.plist"
        ((WARNING_COUNT++))
    fi
else
    log_error "❌ Info.plist not found"
    ((ERROR_COUNT++))
fi

echo ""
echo "🔐 Phase 3: Entitlements Configuration Verification"
echo "=================================================="

# 3. Check entitlements file
if [[ -f "ios/Runner/Runner.entitlements" ]]; then
    log_success "✅ Runner.entitlements file exists"
    ((SUCCESS_COUNT++))
    
    # Check aps-environment in entitlements
    if /usr/libexec/PlistBuddy -c "Print :aps-environment" ios/Runner/Runner.entitlements >/dev/null 2>&1; then
        ENV_VALUE=$(/usr/libexec/PlistBuddy -c "Print :aps-environment" ios/Runner/Runner.entitlements)
        log_success "✅ aps-environment: $ENV_VALUE"
        ((SUCCESS_COUNT++))
    else
        log_error "❌ aps-environment not configured in entitlements"
        ((ERROR_COUNT++))
    fi
    
    # Check com.apple.developer.aps-environment
    if /usr/libexec/PlistBuddy -c "Print :com.apple.developer.aps-environment" ios/Runner/Runner.entitlements >/dev/null 2>&1; then
        DEV_ENV_VALUE=$(/usr/libexec/PlistBuddy -c "Print :com.apple.developer.aps-environment" ios/Runner/Runner.entitlements)
        log_success "✅ com.apple.developer.aps-environment: $DEV_ENV_VALUE"
        ((SUCCESS_COUNT++))
    else
        log_error "❌ com.apple.developer.aps-environment not configured in entitlements"
        ((ERROR_COUNT++))
    fi
    
    # Check background modes
    if /usr/libexec/PlistBuddy -c "Print :com.apple.developer.background-modes" ios/Runner/Runner.entitlements >/dev/null 2>&1; then
        if /usr/libexec/PlistBuddy -c "Print :com.apple.developer.background-modes" ios/Runner/Runner.entitlements | grep -q "remote-notification"; then
            log_success "✅ Background modes include remote-notification"
            ((SUCCESS_COUNT++))
        else
            log_error "❌ Background modes missing remote-notification"
            ((ERROR_COUNT++))
        fi
    else
        log_error "❌ Background modes not configured in entitlements"
        ((ERROR_COUNT++))
    fi
else
    log_error "❌ Runner.entitlements file not found"
    ((ERROR_COUNT++))
fi

echo ""
echo "📦 Phase 4: Podfile Configuration Verification"
echo "============================================="

# 4. Check Podfile for Firebase dependencies
if [[ -f "ios/Podfile" ]]; then
    if grep -q "pod 'Firebase/Core'" ios/Podfile; then
        log_success "✅ Firebase/Core dependency found"
        ((SUCCESS_COUNT++))
    else
        log_error "❌ Firebase/Core dependency missing"
        ((ERROR_COUNT++))
    fi
    
    if grep -q "pod 'Firebase/Messaging'" ios/Podfile; then
        log_success "✅ Firebase/Messaging dependency found"
        ((SUCCESS_COUNT++))
    else
        log_error "❌ Firebase/Messaging dependency missing"
        ((ERROR_COUNT++))
    fi
    
    # Check for use_modular_headers (important for Firebase)
    if grep -q "use_modular_headers!" ios/Podfile; then
        log_success "✅ use_modular_headers! found in Podfile"
        ((SUCCESS_COUNT++))
    else
        log_warning "⚠️ use_modular_headers! missing from Podfile"
        ((WARNING_COUNT++))
    fi
else
    log_error "❌ Podfile not found"
    ((ERROR_COUNT++))
fi

echo ""
echo "🍎 Phase 5: APNS Configuration Verification"
echo "=========================================="

# 5. Check APNS configuration
if [[ -n "${APNS_KEY_ID:-}" ]]; then
    log_success "✅ APNS_KEY_ID is configured: $APNS_KEY_ID"
    ((SUCCESS_COUNT++))
else
    log_warning "⚠️ APNS_KEY_ID not configured"
    ((WARNING_COUNT++))
fi

if [[ -n "${APNS_AUTH_KEY_URL:-}" ]]; then
    log_success "✅ APNS_AUTH_KEY_URL is configured"
    ((SUCCESS_COUNT++))
    
    # Test if the URL is accessible
    if curl --output /dev/null --silent --head --fail "$APNS_AUTH_KEY_URL" 2>/dev/null; then
        log_success "✅ APNS auth key URL is accessible"
        ((SUCCESS_COUNT++))
    else
        log_warning "⚠️ APNS auth key URL is not accessible"
        ((WARNING_COUNT++))
    fi
else
    log_warning "⚠️ APNS_AUTH_KEY_URL not configured"
    ((WARNING_COUNT++))
fi

echo ""
echo "🔑 Phase 6: Certificate Configuration Verification"
echo "================================================="

# 6. Check certificate configuration
if [[ -n "${CERT_PASSWORD:-}" ]]; then
    log_success "✅ CERT_PASSWORD is configured"
    ((SUCCESS_COUNT++))
else
    log_error "❌ CERT_PASSWORD not configured"
    ((ERROR_COUNT++))
fi

if [[ -n "${PROFILE_URL:-}" ]]; then
    log_success "✅ PROFILE_URL is configured"
    ((SUCCESS_COUNT++))
    
    # Test if the URL is accessible
    if curl --output /dev/null --silent --head --fail "$PROFILE_URL" 2>/dev/null; then
        log_success "✅ Provisioning profile URL is accessible"
        ((SUCCESS_COUNT++))
    else
        log_warning "⚠️ Provisioning profile URL is not accessible"
        ((WARNING_COUNT++))
    fi
else
    log_error "❌ PROFILE_URL not configured"
    ((ERROR_COUNT++))
fi

echo ""
echo "🏗️ Phase 7: Xcode Project Capability Verification"
echo "================================================="

# 7. Check if push notification capability is enabled in project
if [[ -f "ios/Runner.xcodeproj/project.pbxproj" ]]; then
    if grep -q "com.apple.Push" ios/Runner.xcodeproj/project.pbxproj; then
        log_success "✅ Push notification capability enabled in project"
        ((SUCCESS_COUNT++))
    else
        log_error "❌ Push notification capability not found in project"
        ((ERROR_COUNT++))
    fi
else
    log_error "❌ Project file not found"
    ((ERROR_COUNT++))
fi

echo ""
echo "🔍 Phase 8: Bundle ID Consistency Verification"
echo "============================================="

# 8. Check if bundle ID matches between Firebase config and project
if [[ -f "ios/Runner/GoogleService-Info.plist" && -f "ios/Runner/Info.plist" ]]; then
    FIREBASE_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" ios/Runner/GoogleService-Info.plist 2>/dev/null || echo "")
    PROJECT_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" ios/Runner/Info.plist 2>/dev/null || echo "")
    
    if [[ -n "$FIREBASE_BUNDLE_ID" && -n "$PROJECT_BUNDLE_ID" ]]; then
        if [[ "$FIREBASE_BUNDLE_ID" == "$PROJECT_BUNDLE_ID" ]]; then
            log_success "✅ Bundle ID matches between Firebase and project: $FIREBASE_BUNDLE_ID"
            ((SUCCESS_COUNT++))
        else
            log_error "❌ Bundle ID mismatch: Firebase=$FIREBASE_BUNDLE_ID, Project=$PROJECT_BUNDLE_ID"
            ((ERROR_COUNT++))
        fi
    else
        log_warning "⚠️ Could not verify bundle ID match"
        ((WARNING_COUNT++))
    fi
fi

echo ""
echo "📊 Phase 9: Final Verification Summary"
echo "====================================="

# Summary
echo ""
echo "📊 Push Notification Configuration Summary:"
echo "=========================================="

if [[ -f "ios/Runner/GoogleService-Info.plist" && -f "ios/Runner/Runner.entitlements" ]]; then
    echo "✅ Firebase configuration: Present"
    echo "✅ Entitlements file: Present"
    
    echo ""
    echo "✅ Successful checks: $SUCCESS_COUNT"
    echo "❌ Errors: $ERROR_COUNT"
    echo "⚠️ Warnings: $WARNING_COUNT"
    
    if [[ $ERROR_COUNT -eq 0 ]]; then
        echo ""
        echo "🎉 Push notification configuration is COMPLETE!"
        echo "📱 Your iOS app should now be able to receive push notifications in ALL states:"
        echo "   🔵 Background state (app in background)"
        echo "   🔴 Closed state (app terminated)"
        echo "   🟢 Opened state (app active)"
        echo ""
        echo "🚀 Ready for production push notification testing!"
    else
        echo ""
        echo "⚠️ Some configuration issues were found"
        echo "🔧 Please fix the errors above before testing push notifications"
        echo "❌ Push notifications will NOT work until all errors are resolved"
    fi
else
    echo "❌ Critical files missing - push notifications will not work"
    echo "❌ Required: GoogleService-Info.plist and Runner.entitlements"
fi

echo ""
echo "🔍 Comprehensive verification complete!"

# Exit with error code if there are critical errors
if [[ $ERROR_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
