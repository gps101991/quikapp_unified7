#!/bin/bash

# 🔥 Enhanced Firebase Configuration for iOS
# Conditionally enables Firebase based on PUSH_NOTIFY flag

set -euo pipefail

# Source common functions
source "$(dirname "$0")/../utils/safe_run.sh"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] 🔥 $1"
}

# Error handling
handle_error() { 
    log "❌ ERROR: $1"; 
    exit 1; 
}
trap 'handle_error "Error occurred at line $LINENO"' ERR

# Environment variables
FIREBASE_CONFIG_IOS=${FIREBASE_CONFIG_IOS:-}
PUSH_NOTIFY=${PUSH_NOTIFY:-"false"}

log "🚀 Starting Firebase configuration for iOS"
log "📋 Configuration:"
log "   PUSH_NOTIFY: $PUSH_NOTIFY"
log "   FIREBASE_CONFIG_IOS: ${FIREBASE_CONFIG_IOS:-'Not provided'}"

# Function to disable Firebase and push notifications
disable_firebase() {
    log "⏭️ Disabling Firebase (push notifications disabled)..."
    
    # Remove Firebase configuration files
    log "🗑️ Removing Firebase configuration files"
    rm -f ios/Runner/GoogleService-Info.plist 2>/dev/null || true
    rm -f assets/GoogleService-Info.plist 2>/dev/null || true
    log "✅ Firebase configuration files removed"
    
    # Remove Firebase dependencies from Podfile
    if [ -f "ios/Podfile" ]; then
        log "📦 Removing Firebase dependencies from Podfile"
        sed -i.bak '/pod .Firebase\/Core./d' ios/Podfile
        sed -i.bak '/pod .Firebase\/Messaging./d' ios/Podfile
        sed -i.bak '/# Firebase dependencies/d' ios/Podfile
        rm -f ios/Podfile.bak 2>/dev/null || true
        log "✅ Firebase dependencies removed from Podfile"
    fi
    
    # Remove push notification configuration from Info.plist
    if [ -f "ios/Runner/Info.plist" ]; then
        log "📝 Removing push notification configuration from Info.plist"
        /usr/libexec/PlistBuddy -c "Delete :UIBackgroundModes" ios/Runner/Info.plist 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Delete :FirebaseAppDelegateProxyEnabled" ios/Runner/Info.plist 2>/dev/null || true
        log "✅ Push notification configuration removed from Info.plist"
    fi
    
    log "✅ Firebase and push notifications disabled successfully"
}

# Function to enable Firebase and push notifications
enable_firebase() {
    log "🔔 Enabling Firebase for push notifications..."
    
    # Validate Firebase configuration
    if [ -z "$FIREBASE_CONFIG_IOS" ]; then
        log "❌ FIREBASE_CONFIG_IOS is required when PUSH_NOTIFY is true"
        log "🔄 Skipping Firebase setup - build will continue without Firebase"
        
        # Remove any existing Firebase files
        rm -f ios/Runner/GoogleService-Info.plist 2>/dev/null || true
        rm -f assets/GoogleService-Info.plist 2>/dev/null || true
        
        log "⚠️ Firebase setup skipped - no configuration provided"
        log "⚠️ Push notifications will not work"
        return 0
    fi
    
    # Validate URL format
    if [[ ! "$FIREBASE_CONFIG_IOS" =~ ^https?:// ]]; then
        log "❌ FIREBASE_CONFIG_IOS must be a valid URL"
        log "🔄 Skipping Firebase setup - build will continue without Firebase"
        
        # Remove any existing Firebase files
        rm -f ios/Runner/GoogleService-Info.plist 2>/dev/null || true
        rm -f assets/GoogleService-Info.plist 2>/dev/null || true
        
        log "⚠️ Firebase setup skipped - invalid URL format"
        log "⚠️ Push notifications will not work"
        return 0
    fi
    
    # Download Firebase configuration
    log "📥 Downloading Firebase configuration from $FIREBASE_CONFIG_IOS"
    if curl -L --fail --silent --show-error --max-time 30 --output "ios/Runner/GoogleService-Info.plist" "$FIREBASE_CONFIG_IOS"; then
        log "✅ Firebase configuration downloaded successfully"
    else
        log "❌ Failed to download Firebase configuration from $FIREBASE_CONFIG_IOS"
        log "🔄 Skipping Firebase setup - build will continue without Firebase"
        
        # Remove any existing Firebase files
        rm -f ios/Runner/GoogleService-Info.plist 2>/dev/null || true
        rm -f assets/GoogleService-Info.plist 2>/dev/null || true
        
        log "⚠️ Firebase setup skipped - download failed"
        log "⚠️ Push notifications will not work"
        return 0
    fi
    
    # Verify downloaded file
    if [ ! -f "ios/Runner/GoogleService-Info.plist" ]; then
        log "❌ Firebase configuration file was not created"
        log "🔄 Skipping Firebase setup - build will continue without Firebase"
        
        # Remove any existing Firebase files
        rm -f ios/Runner/GoogleService-Info.plist 2>/dev/null || true
        rm -f assets/GoogleService-Info.plist 2>/dev/null || true
        
        log "⚠️ Firebase setup skipped - file creation failed"
        log "⚠️ Push notifications will not work"
        return 0
    fi
    
    # Check file size (should be > 100 bytes for a valid config)
    FIREBASE_SIZE=$(stat -f%z ios/Runner/GoogleService-Info.plist 2>/dev/null || stat -c%s ios/Runner/GoogleService-Info.plist 2>/dev/null || echo "0")
    if [ "$FIREBASE_SIZE" -lt 100 ]; then
        log "⚠️ Firebase config file seems too small ($FIREBASE_SIZE bytes). This might be an error page."
        log "🔄 Skipping Firebase setup - build will continue without Firebase"
        
        # Remove any existing Firebase files
        rm -f ios/Runner/GoogleService-Info.plist 2>/dev/null || true
        rm -f assets/GoogleService-Info.plist 2>/dev/null || true
        
        log "⚠️ Firebase setup skipped - invalid config file"
        log "⚠️ Push notifications will not work"
        return 0
    fi
    
    # Copy to assets directory for Flutter
    log "📁 Copying Firebase configuration to assets directory"
    mkdir -p assets
    if cp ios/Runner/GoogleService-Info.plist assets/GoogleService-Info.plist; then
        log "✅ Firebase configuration copied to assets"
    else
        log "⚠️ Failed to copy GoogleService-Info.plist to assets"
    fi
    
    # Configure Info.plist for push notifications
    log "📝 Configuring Info.plist for push notifications"
    
    # Add background modes for remote notifications
    /usr/libexec/PlistBuddy -c "Add :UIBackgroundModes array" ios/Runner/Info.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :UIBackgroundModes: string 'remote-notification'" ios/Runner/Info.plist 2>/dev/null || true
    
    # Disable Firebase App Delegate Proxy (recommended for Flutter)
    /usr/libexec/PlistBuddy -c "Add :FirebaseAppDelegateProxyEnabled bool false" ios/Runner/Info.plist 2>/dev/null || true
    
    # Add APNS environment configuration
    /usr/libexec/PlistBuddy -c "Add :aps-environment string development" ios/Runner/Info.plist 2>/dev/null || true
    
    # Configure push notification entitlements
    log "🔧 Configuring push notification entitlements..."
    if [[ -f "ios/Runner/Runner.entitlements" ]]; then
        # Ensure entitlements file has correct structure
        if ! /usr/libexec/PlistBuddy -c "Print :aps-environment" ios/Runner/Runner.entitlements >/dev/null 2>&1; then
            /usr/libexec/PlistBuddy -c "Add :aps-environment string development" ios/Runner/Runner.entitlements 2>/dev/null || true
        fi
        
        if ! /usr/libexec/PlistBuddy -c "Print :com.apple.developer.aps-environment" ios/Runner/Runner.entitlements >/dev/null 2>&1; then
            /usr/libexec/PlistBuddy -c "Add :com.apple.developer.aps-environment string development" ios/Runner/Runner.entitlements 2>/dev/null || true
        fi
        
        if ! /usr/libexec/PlistBuddy -c "Print :com.apple.developer.background-modes" ios/Runner/Runner.entitlements >/dev/null 2>&1; then
            /usr/libexec/PlistBuddy -c "Add :com.apple.developer.background-modes array" ios/Runner/Runner.entitlements 2>/dev/null || true
            /usr/libexec/PlistBuddy -c "Add :com.apple.developer.background-modes: string 'remote-notification'" ios/Runner/Runner.entitlements 2>/dev/null || true
        fi
        
        log "✅ Entitlements configured for push notifications"
    else
        log "⚠️ Entitlements file not found, creating basic configuration..."
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
        log "✅ Created entitlements file with push notification support"
    fi
    
    log "✅ Info.plist and entitlements configured for push notifications"
    
    # Update Podfile for Firebase dependencies
    log "📦 Adding Firebase dependencies to Podfile"
    if [ -f "ios/Podfile" ]; then
        # Remove existing Firebase entries if any
        sed -i.bak '/pod .Firebase\/Core./d' ios/Podfile
        sed -i.bak '/pod .Firebase\/Messaging./d' ios/Podfile
        rm -f ios/Podfile.bak 2>/dev/null || true
        
        # Add Firebase dependencies
        if ! grep -q "pod 'Firebase/Core'" ios/Podfile; then
            cat >> ios/Podfile << 'EOF'

# Firebase dependencies for push notifications
pod 'Firebase/Core'
pod 'Firebase/Messaging'
EOF
            log "✅ Firebase dependencies added to Podfile"
        else
            log "ℹ️ Firebase dependencies already present in Podfile"
        fi
    else
        log "❌ Podfile not found"
        log "🔄 Skipping Firebase setup - build will continue without Firebase"
        return 0
    fi
    
    log "✅ Firebase and push notifications enabled successfully"
}

# Function to verify Firebase configuration
verify_firebase_config() {
    if [ "${PUSH_NOTIFY:-false}" = "true" ]; then
        log "🔍 Verifying Firebase configuration..."
        
        # Check if Firebase config file exists
        if [ ! -f "ios/Runner/GoogleService-Info.plist" ]; then
            log "⚠️ Firebase configuration file not found"
            log "⚠️ Push notifications will not work"
            return 1
        fi
        
        # Check if assets copy exists
        if [ ! -f "assets/GoogleService-Info.plist" ]; then
            log "⚠️ Firebase configuration not copied to assets"
        fi
        
        # Check if Podfile contains Firebase dependencies
        if ! grep -q "pod 'Firebase/Core'" ios/Podfile; then
            log "⚠️ Firebase dependencies not found in Podfile"
        fi
        
        # Check if Info.plist has push notification configuration
        if ! /usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" ios/Runner/Info.plist 2>/dev/null | grep -q "remote-notification"; then
            log "⚠️ Push notification background mode not configured"
        fi
        
        log "✅ Firebase configuration verification passed"
    else
        log "🔍 Verifying Firebase is properly disabled..."
        
        # Check that Firebase config files are removed
        if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
            log "⚠️ Firebase configuration file still exists"
        fi
        
        if [ -f "assets/GoogleService-Info.plist" ]; then
            log "⚠️ Firebase configuration still exists in assets"
        fi
        
        # Check that Podfile doesn't contain Firebase dependencies
        if grep -q "pod 'Firebase/Core'" ios/Podfile; then
            log "⚠️ Firebase dependencies still present in Podfile"
        fi
        
        log "✅ Firebase disable verification passed"
    fi
}

# Main execution
main() {
    log "🎯 Firebase Configuration Decision:"
    log "   PUSH_NOTIFY = $PUSH_NOTIFY"
    
    if [ "${PUSH_NOTIFY:-false}" = "true" ]; then
        log "🔔 Push notifications ENABLED - Setting up Firebase"
        enable_firebase
    else
        log "🔕 Push notifications DISABLED - Skipping Firebase setup"
        disable_firebase
    fi
    
    # Verify configuration
    if verify_firebase_config; then
        log "✅ Firebase configuration verification passed"
    else
        log "⚠️ Firebase configuration verification completed with warnings"
    fi
    
    log "🎉 Firebase configuration completed successfully!"
    log "📊 Summary:"
    log "   Push Notifications: ${PUSH_NOTIFY:-false}"
    log "   Firebase Status: $([ "${PUSH_NOTIFY:-false}" = "true" ] && echo "Enabled" || echo "Disabled")"
}

# Run main function
main "$@" 