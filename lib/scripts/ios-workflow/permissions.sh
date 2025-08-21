#!/bin/bash
# 🔐 iOS Permissions Script
# Dynamically configures iOS permissions in Info.plist based on environment variables

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PERMISSIONS] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

# Function to safely get environment variable with fallback
get_env_var() {
    local var_name="$1"
    local fallback="$2"
    local value="${!var_name:-}"
    
    if [ -n "$value" ]; then
        printf "%s" "$value"
    else
        printf "%s" "$fallback"
    fi
}

# Function to add or update Info.plist key
update_info_plist() {
    local key="$1"
    local value="$2"
    local plist_path="ios/Runner/Info.plist"
    
    if /usr/libexec/PlistBuddy -c "Print :$key" "$plist_path" 2>/dev/null; then
        /usr/libexec/PlistBuddy -c "Set :$key '$value'" "$plist_path"
        log_success "Updated $key in Info.plist"
    else
        /usr/libexec/PlistBuddy -c "Add :$key string '$value'" "$plist_path"
        log_success "Added $key to Info.plist"
    fi
}

log_info "Starting iOS permissions configuration..."

# Get permission flags from environment
IS_CAMERA=$(get_env_var "IS_CAMERA" "false")
IS_LOCATION=$(get_env_var "IS_LOCATION" "false")
IS_MIC=$(get_env_var "IS_MIC" "false")
IS_NOTIFICATION=$(get_env_var "IS_NOTIFICATION" "false")
IS_CONTACT=$(get_env_var "IS_CONTACT" "false")
IS_BIOMETRIC=$(get_env_var "IS_BIOMETRIC" "false")
IS_CALENDAR=$(get_env_var "IS_CALENDAR" "false")
IS_STORAGE=$(get_env_var "IS_STORAGE" "false")
IS_CHATBOT=$(get_env_var "IS_CHATBOT" "false")

# Get app name for permission descriptions
APP_NAME=$(get_env_var "APP_NAME" "")

log_info "Permission flags:"
log_info "  Camera: $IS_CAMERA"
log_info "  Location: $IS_LOCATION"
log_info "  Microphone: $IS_MIC"
log_info "  Notifications: $IS_NOTIFICATION"
log_info "  Contacts: $IS_CONTACT"
log_info "  Biometric: $IS_BIOMETRIC"
log_info "  Calendar: $IS_CALENDAR"
log_info "  Storage: $IS_STORAGE"
log_info "  Chat Bot: $IS_CHATBOT"

# Always add network security settings for Flutter apps
log_info "Adding network security settings..."
update_info_plist "NSAppTransportSecurity" "NSAppTransportSecurity"
update_info_plist "NSAppTransportSecurity:NSAllowsArbitraryLoads" "true"

# Camera Permission
if [[ "$IS_CAMERA" == "true" ]]; then
    log_info "Adding camera permission..."
    update_info_plist "NSCameraUsageDescription" "$APP_NAME needs access to your camera to take photos and videos."
fi

# Location Permissions
if [[ "$IS_LOCATION" == "true" ]]; then
    log_info "Adding location permissions..."
    update_info_plist "NSLocationWhenInUseUsageDescription" "$APP_NAME needs access to your location to provide location-based services."
    update_info_plist "NSLocationAlwaysAndWhenInUseUsageDescription" "$APP_NAME needs access to your location to provide location-based services."
    update_info_plist "NSLocationAlwaysUsageDescription" "$APP_NAME needs access to your location to provide location-based services."
fi

# Microphone Permission
if [[ "$IS_MIC" == "true" ]]; then
    log_info "Adding microphone permission..."
    update_info_plist "NSMicrophoneUsageDescription" "$APP_NAME needs access to your microphone for voice recording and communication."
fi

# Speech Recognition Permission (for Chat Bot)
if [[ "$IS_CHATBOT" == "true" ]]; then
    log_info "Adding speech recognition permission for chat bot..."
    update_info_plist "NSSpeechRecognitionUsageDescription" "$APP_NAME needs access to speech recognition to convert your voice to text for the chat bot feature."
fi

# Contacts Permission
if [[ "$IS_CONTACT" == "true" ]]; then
    log_info "Adding contacts permission..."
    update_info_plist "NSContactsUsageDescription" "$APP_NAME needs access to your contacts to help you connect with friends and family."
fi

# Face ID Permission
if [[ "$IS_BIOMETRIC" == "true" ]]; then
    log_info "Adding Face ID permission..."
    update_info_plist "NSFaceIDUsageDescription" "$APP_NAME uses Face ID to securely authenticate you and protect your personal information."
fi

# Calendar Permission
if [[ "$IS_CALENDAR" == "true" ]]; then
    log_info "Adding calendar permission..."
    update_info_plist "NSCalendarsUsageDescription" "$APP_NAME needs access to your calendar to help you manage your schedule and events."
fi

# Photo Library Permissions
if [[ "$IS_STORAGE" == "true" ]]; then
    log_info "Adding photo library permissions..."
    update_info_plist "NSPhotoLibraryUsageDescription" "$APP_NAME needs access to your photo library to save and share images."
    update_info_plist "NSPhotoLibraryAddUsageDescription" "$APP_NAME needs access to your photo library to save images and videos."
fi

# Notification Permission (always add for push notifications)
if [[ "$IS_NOTIFICATION" == "true" ]]; then
    log_info "Adding notification permission..."
    # Note: iOS automatically requests notification permission, no Info.plist key needed
    log_info "Notification permission will be requested at runtime"
    
    # 🔔 CRITICAL: Add push notification background mode for all three states (bg, closed, opened)
    log_info "🔔 Adding push notification background mode for all app states..."
    
    # Add UIBackgroundModes array if it doesn't exist
    if ! /usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" "ios/Runner/Info.plist" 2>/dev/null; then
        /usr/libexec/PlistBuddy -c "Add :UIBackgroundModes array" "ios/Runner/Info.plist"
        log_success "✅ Added UIBackgroundModes array to Info.plist"
    fi
    
    # Add remote-notification background mode for push notifications
    if ! /usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" "ios/Runner/Info.plist" 2>/dev/null | grep -q "remote-notification"; then
        # Get current array length to add at the end
        ARRAY_LENGTH=$(/usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" "ios/Runner/Info.plist" 2>/dev/null | wc -l || echo "0")
        /usr/libexec/PlistBuddy -c "Add :UIBackgroundModes:$ARRAY_LENGTH string 'remote-notification'" "ios/Runner/Info.plist" 2>/dev/null || \
        /usr/libexec/PlistBuddy -c "Set :UIBackgroundModes:$ARRAY_LENGTH 'remote-notification'" "ios/Runner/Info.plist" 2>/dev/null || true
        log_success "✅ Added remote-notification background mode to Info.plist"
    else
        log_info "ℹ️ remote-notification background mode already present"
    fi
    
    # 🔐 CRITICAL: Ensure push notification entitlements are properly configured
    log_info "🔐 Configuring push notification entitlements..."
    if [[ -f "ios/Runner/Runner.entitlements" ]]; then
        # Update entitlements for production if needed
        if [[ "${PROFILE_TYPE:-}" == "app-store" ]]; then
            /usr/libexec/PlistBuddy -c "Set :aps-environment production" "ios/Runner/Runner.entitlements" 2>/dev/null || \
            /usr/libexec/PlistBuddy -c "Add :aps-environment string production" "ios/Runner/Runner.entitlements" 2>/dev/null || true
            
            /usr/libexec/PlistBuddy -c "Set :com.apple.developer.aps-environment production" "ios/Runner/Runner.entitlements" 2>/dev/null || \
            /usr/libexec/PlistBuddy -c "Add :com.apple.developer.aps-environment string production" "ios/Runner/Runner.entitlements" 2>/dev/null || true
            log_info "✅ Updated entitlements for production environment"
        else
            /usr/libexec/PlistBuddy -c "Set :aps-environment development" "ios/Runner/Runner.entitlements" 2>/dev/null || \
            /usr/libexec/PlistBuddy -c "Add :aps-environment string development" "ios/Runner/Runner.entitlements" 2>/dev/null || true
            
            /usr/libexec/PlistBuddy -c "Set :com.apple.developer.aps-environment development" "ios/Runner/Runner.entitlements" 2>/dev/null || \
            /usr/libexec/PlistBuddy -c "Add :com.apple.developer.aps-environment string development" "ios/Runner/Runner.entitlements" 2>/dev/null || true
            log_info "✅ Updated entitlements for development environment"
        fi
        
        # Ensure background modes include remote-notification
        if ! /usr/libexec/PlistBuddy -c "Print :com.apple.developer.background-modes" "ios/Runner/Runner.entitlements" 2>/dev/null | grep -q "remote-notification"; then
            if ! /usr/libexec/PlistBuddy -c "Print :com.apple.developer.background-modes" "ios/Runner/Runner.entitlements" 2>/dev/null; then
                /usr/libexec/PlistBuddy -c "Add :com.apple.developer.background-modes array" "ios/Runner/Runner.entitlements" 2>/dev/null || true
            fi
            ARRAY_LENGTH=$(/usr/libexec/PlistBuddy -c "Print :com.apple.developer.background-modes" "ios/Runner/Runner.entitlements" 2>/dev/null | wc -l || echo "0")
            /usr/libexec/PlistBuddy -c "Add :com.apple.developer.background-modes:$ARRAY_LENGTH string 'remote-notification'" "ios/Runner/Runner.entitlements" 2>/dev/null || true
            log_success "✅ Added remote-notification to entitlements background modes"
        else
            log_info "ℹ️ remote-notification already in entitlements background modes"
        fi
    else
        log_warning "⚠️ Entitlements file not found, creating basic entitlements..."
        # Create basic entitlements if missing
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
        log_success "✅ Created basic entitlements file with push notification support"
    fi
    
    # 🏗️ CRITICAL: Ensure push notification capability is enabled in Xcode project
    log_info "🏗️ Ensuring push notification capability is enabled in Xcode project..."
    if [[ -f "ios/Runner.xcodeproj/project.pbxproj" ]]; then
        if ! grep -q "com.apple.Push" "ios/Runner.xcodeproj/project.pbxproj"; then
            log_info "📝 Adding push notification capability to project..."
            
            # Create a temporary file with the capability addition
            TEMP_PROJECT="/tmp/project.pbxproj.tmp"
            cp "ios/Runner.xcodeproj/project.pbxproj" "$TEMP_PROJECT"
            
            # Add push notification capability using proper Xcode project format
            # Look for the capabilities section and add push notifications
            if grep -q "SystemCapabilities" "$TEMP_PROJECT"; then
                # Add push notification capability to existing SystemCapabilities
                sed -i.bak '/SystemCapabilities = {/,/};/ s/};/		com.apple.Push = {\n			enabled = 1;\n		};\n	};/' "$TEMP_PROJECT"
                rm -f "$TEMP_PROJECT.bak" 2>/dev/null || true
                log_success "✅ Added push notification capability to existing SystemCapabilities"
            else
                # Create new SystemCapabilities section
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
        log_warning "⚠️ Project file not found, cannot verify push notification capability"
    fi
    
    # 📱 CRITICAL: Ensure Info.plist has all required push notification keys
    log_info "📱 Ensuring Info.plist has all required push notification keys..."
    
    # Add FirebaseAppDelegateProxyEnabled if not present (recommended for Flutter)
    if ! /usr/libexec/PlistBuddy -c "Print :FirebaseAppDelegateProxyEnabled" "ios/Runner/Info.plist" 2>/dev/null; then
        /usr/libexec/PlistBuddy -c "Add :FirebaseAppDelegateProxyEnabled bool false" "ios/Runner/Info.plist" 2>/dev/null || true
        log_success "✅ Added FirebaseAppDelegateProxyEnabled to Info.plist"
    fi
    
    # Add aps-environment if not present
    if ! /usr/libexec/PlistBuddy -c "Print :aps-environment" "ios/Runner/Info.plist" 2>/dev/null; then
        if [[ "${PROFILE_TYPE:-}" == "app-store" ]]; then
            /usr/libexec/PlistBuddy -c "Add :aps-environment string production" "ios/Runner/Info.plist" 2>/dev/null || true
        else
            /usr/libexec/PlistBuddy -c "Add :aps-environment string development" "ios/Runner/Info.plist" 2>/dev/null || true
        fi
        log_success "✅ Added aps-environment to Info.plist"
    fi
    
    log_success "✅ Push notification configuration completed for all app states"
else
    log_info "ℹ️ Push notifications disabled (IS_NOTIFICATION=false)"
fi

# Add required background modes if needed
if [[ "$IS_LOCATION" == "true" ]]; then
    log_info "Adding background location mode..."
    # Add background modes array if it doesn't exist
    if ! /usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" "ios/Runner/Info.plist" 2>/dev/null; then
        /usr/libexec/PlistBuddy -c "Add :UIBackgroundModes array" "ios/Runner/Info.plist"
    fi
    
    # Add location background mode
    /usr/libexec/PlistBuddy -c "Add :UIBackgroundModes:0 string location" "ios/Runner/Info.plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :UIBackgroundModes:0 location" "ios/Runner/Info.plist"
fi

# Add audio background mode for microphone/chat bot
if [[ "$IS_MIC" == "true" ]] || [[ "$IS_CHATBOT" == "true" ]]; then
    log_info "Adding audio background mode..."
    if ! /usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" "ios/Runner/Info.plist" 2>/dev/null; then
        /usr/libexec/PlistBuddy -c "Add :UIBackgroundModes array" "ios/Runner/Info.plist"
    fi
    
    # Add audio background mode
    /usr/libexec/PlistBuddy -c "Add :UIBackgroundModes:1 string audio" "ios/Runner/Info.plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :UIBackgroundModes:1 audio" "ios/Runner/Info.plist"
fi

# Add required device capabilities
log_info "Adding required device capabilities..."

# Add device capabilities array if it doesn't exist
if ! /usr/libexec/PlistBuddy -c "Print :UIRequiredDeviceCapabilities" "ios/Runner/Info.plist" 2>/dev/null; then
    /usr/libexec/PlistBuddy -c "Add :UIRequiredDeviceCapabilities array" "ios/Runner/Info.plist"
fi

# Add required capabilities
capabilities=("armv7")

if [[ "$IS_BIOMETRIC" == "true" ]]; then
    capabilities+=("faceid")
fi

# Add capabilities to Info.plist
for i in "${!capabilities[@]}"; do
    capability="${capabilities[$i]}"
    /usr/libexec/PlistBuddy -c "Add :UIRequiredDeviceCapabilities:$i string $capability" "ios/Runner/Info.plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :UIRequiredDeviceCapabilities:$i $capability" "ios/Runner/Info.plist"
done

# Verify Info.plist is valid
log_info "Verifying Info.plist configuration..."
if /usr/libexec/PlistBuddy -c "Print" "ios/Runner/Info.plist" >/dev/null 2>&1; then
    log_success "Info.plist is valid"
else
    log_error "Info.plist is invalid"
    exit 1
fi

# Display final configuration
log_info "Final Info.plist configuration:"
/usr/libexec/PlistBuddy -c "Print" "ios/Runner/Info.plist" | grep -E "(UsageDescription|UIBackgroundModes|UIRequiredDeviceCapabilities)" || true

log_success "iOS permissions configuration completed successfully" 