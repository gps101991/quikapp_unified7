#!/bin/bash
# =============================================================================
# Dynamic Firebase Configuration Script for Android Workflow
# =============================================================================
# This script automatically configures Firebase based on environment variables:
# - PUSH_NOTIFY: true/false (enables push notifications)
# - IS_GOOGLE_AUTH: true/false (enables Google authentication)
# - FIREBASE_CONFIG_ANDROID: URL to google-services.json
# 
# Firebase is only configured if either PUSH_NOTIFY or IS_GOOGLE_AUTH is true
set -e

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Configuration variables
PUSH_NOTIFY=${PUSH_NOTIFY:-false}
IS_GOOGLE_AUTH=${IS_GOOGLE_AUTH:-false}
FIREBASE_CONFIG_ANDROID=${FIREBASE_CONFIG_ANDROID:-}
WORKFLOW_ID=${WORKFLOW_ID:-unknown}
PKG_NAME=${PKG_NAME:-}

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [FIREBASE_SETUP] $1"; }

# Check if Firebase is needed
is_firebase_needed() {
    if [ "$PUSH_NOTIFY" = "true" ] || [ "$IS_GOOGLE_AUTH" = "true" ]; then
        return 0  # Firebase is needed
    else
        return 1  # Firebase is not needed
    fi
}

# Download and configure Firebase
setup_firebase() {
    local firebase_config_url="$FIREBASE_CONFIG_ANDROID"
    local target_file="android/app/google-services.json"
    local target_dir="android/app"
    
    log "🔥 Setting up Firebase configuration..."
    log "   - PUSH_NOTIFY: $PUSH_NOTIFY"
    log "   - IS_GOOGLE_AUTH: $IS_GOOGLE_AUTH"
    log "   - Firebase Config URL: $firebase_config_url"
    
    # Create target directory if it doesn't exist
    mkdir -p "$target_dir"
    
    # Backup existing file if it exists
    if [ -f "$target_file" ]; then
        cp "$target_file" "${target_file}.backup.$(date +%Y%m%d_%H%M%S)"
        log "💾 Backup created for existing google-services.json"
    fi
    
    # Download Firebase configuration
    if [ -n "$firebase_config_url" ]; then
        log "📥 Downloading Firebase configuration from: $firebase_config_url"
        
        if curl -L "$firebase_config_url" -o "$target_file" --silent --show-error --max-time 30; then
            log "✅ Firebase configuration downloaded successfully"
            
            # Validate and fix package name if needed
            fix_package_name_in_firebase_config
            
            # Validate JSON format
            if validate_firebase_config; then
                log "✅ Firebase configuration validated successfully"
                return 0
            else
                log "❌ Firebase configuration validation failed"
                log "🔄 Skipping Firebase setup - build will continue without Firebase"
                return 1
            fi
        else
            log "❌ Failed to download Firebase configuration"
            log "🔄 Skipping Firebase setup - build will continue without Firebase"
            return 1
        fi
    else
        log "⚠️ No Firebase config URL provided"
        log "🔄 Skipping Firebase setup - build will continue without Firebase"
        return 1
    fi
}

# Fix package name in Firebase configuration
fix_package_name_in_firebase_config() {
    local firebase_file="android/app/google-services.json"
    
    if [ ! -f "$firebase_file" ] || [ -z "$PKG_NAME" ]; then
        log "⚠️ Cannot fix package name: file missing or PKG_NAME not set"
        return 0
    fi
    
    log "🔧 Fixing package name in Firebase configuration..."
    log "   Target package: $PKG_NAME"
    
    # Find current package names in the config
    local current_packages=$(grep -o '"package_name": "[^"]*"' "$firebase_file" | cut -d'"' -f4 | sort -u)
    
    if [ -n "$current_packages" ]; then
        log "   Found package names: $current_packages"
        
        for pkg in $current_packages; do
            if [ "$pkg" != "$PKG_NAME" ]; then
                log "   Replacing '$pkg' with '$PKG_NAME'"
                # Use proper sed escaping for special characters
                sed -i "s|\"package_name\": \"$pkg\"|\"package_name\": \"$PKG_NAME\"|g" "$firebase_file"
            fi
        done
        
        log "✅ Package names fixed in Firebase configuration"
    else
        log "⚠️ No package names found in Firebase configuration"
    fi
}

# Validate Firebase configuration
validate_firebase_config() {
    local firebase_file="android/app/google-services.json"
    
    if [ ! -f "$firebase_file" ]; then
        log "❌ Firebase configuration file not found"
        return 1
    fi
    
    # Check if it's valid JSON
    if ! python3 -c "import json; json.load(open('$firebase_file'))" 2>/dev/null; then
        log "❌ Firebase configuration is not valid JSON"
        return 1
    fi
    
    # Check required fields
    local required_fields=("project_info" "client" "api_key")
    for field in "${required_fields[@]}"; do
        if ! grep -q "\"$field\"" "$firebase_file" 2>/dev/null; then
            log "❌ Required Firebase field '$field' missing"
            return 1
        fi
    done
    
    # Check if package name is correct
    if [ -n "$PKG_NAME" ] && ! grep -q "\"package_name\": \"$PKG_NAME\"" "$firebase_file" 2>/dev/null; then
        log "⚠️ Package name '$PKG_NAME' not found in Firebase configuration"
        log "🔄 Attempting to fix package name..."
        fix_package_name_in_firebase_config
        
        # Check again after fixing
        if ! grep -q "\"package_name\": \"$PKG_NAME\"" "$firebase_file" 2>/dev/null; then
            log "❌ Package name fix failed"
            return 1
        fi
    fi
    
    log "✅ Firebase configuration validation passed"
    return 0
}

# Update build.gradle.kts with Firebase configuration
update_build_gradle_kts() {
    local build_file="android/app/build.gradle.kts"
    
    if [ ! -f "$build_file" ]; then
        log "❌ build.gradle.kts not found"
        return 1
    fi
    
    log "🔧 Updating build.gradle.kts with Firebase configuration..."
    
    # Backup original file
    cp "$build_file" "${build_file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Check if Firebase plugin is already added
    if ! grep -q 'id("com.google.gms.google-services")' "$build_file"; then
        log "📝 Adding Firebase plugin to build.gradle.kts..."
        
        # Add Firebase plugin after flutter plugin
        sed -i '/id("dev.flutter.flutter-gradle-plugin")/a\    id("com.google.gms.google-services")' "$build_file"
        log "✅ Firebase plugin added to build.gradle.kts"
    else
        log "✅ Firebase plugin already present in build.gradle.kts"
    fi
    
    # Check if Firebase dependencies are present
    if ! grep -q 'firebase-bom' "$build_file"; then
        log "📝 Adding Firebase dependencies to build.gradle.kts..."
        
        # Add Firebase dependencies before the closing brace of dependencies block
        sed -i '/^}$/i\\n    // Firebase dependencies\n    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))\n    implementation("com.google.firebase:firebase-analytics")\n    implementation("com.google.firebase:firebase-messaging")' "$build_file"
        log "✅ Firebase dependencies added to build.gradle.kts"
    else
        log "✅ Firebase dependencies already present in build.gradle.kts"
    fi
    
    log "✅ build.gradle.kts updated successfully"
}

# Update settings.gradle.kts with Firebase plugin
update_settings_gradle_kts() {
    local settings_file="android/settings.gradle.kts"
    
    if [ ! -f "$settings_file" ]; then
        log "❌ settings.gradle.kts not found"
        return 1
    fi
    
    log "🔧 Updating settings.gradle.kts with Firebase plugin..."
    
    # Check if Firebase plugin is already added
    if ! grep -q 'id("com.google.gms.google-services")' "$settings_file"; then
        log "📝 Adding Firebase plugin to settings.gradle.kts..."
        
        # Add Firebase plugin to plugins block
        sed -i '/id("org.jetbrains.kotlin.android")/a\    id("com.google.gms.google-services") version "4.4.0" apply false' "$settings_file"
        log "✅ Firebase plugin added to settings.gradle.kts"
    else
        log "✅ Firebase plugin already present in settings.gradle.kts"
    fi
}

# Main execution function
main() {
    log "🚀 Starting dynamic Firebase configuration setup..."
    log "   Workflow: $WORKFLOW_ID"
    log "   Package: $PKG_NAME"
    log "   PUSH_NOTIFY: $PUSH_NOTIFY"
    log "   IS_GOOGLE_AUTH: $IS_GOOGLE_AUTH"
    
    # Check if Firebase is needed
    if is_firebase_needed; then
        log "✅ Firebase setup required (PUSH_NOTIFY=$PUSH_NOTIFY, IS_GOOGLE_AUTH=$IS_GOOGLE_AUTH)"
        
        # Setup Firebase configuration
        if setup_firebase; then
            log "✅ Firebase configuration setup completed successfully"
            
            # Update Gradle files
            update_build_gradle_kts
            update_settings_gradle_kts
            
            log "✅ Firebase setup completed for android-publish workflow"
        else
            log "⚠️ Firebase configuration setup failed"
            log "🔄 Skipping Firebase setup - build will continue without Firebase"
            
            # Remove Firebase files if they exist
            rm -f android/app/google-services.json 2>/dev/null || true
            rm -f assets/google-services.json 2>/dev/null || true
            
            log "⚠️ Firebase features (push notifications, Google auth) will not work"
        fi
    else
        log "ℹ️ Firebase not required (PUSH_NOTIFY=$PUSH_NOTIFY, IS_GOOGLE_AUTH=$IS_GOOGLE_AUTH)"
        log "🔄 Skipping Firebase configuration..."
        
        # Remove Firebase files if they exist
        if [ -f "android/app/google-services.json" ]; then
            rm "android/app/google-services.json"
            log "🗑️ Removed existing google-services.json (Firebase not needed)"
        fi
        
        log "✅ Firebase setup skipped - not required for this configuration"
    fi
    
    log "🎉 Dynamic Firebase configuration setup completed"
}

# Execute main function
main "$@"
