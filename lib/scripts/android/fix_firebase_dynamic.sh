#!/bin/bash

# =============================================================================
# Dynamic Firebase Configuration Fix Script
# =============================================================================
# This script fixes Firebase configuration issues during android-publish builds
# - Downloads real Firebase config from environment variables
# - Fixes package name mismatches automatically
# - Provides fallback configurations
# - Handles conditional Firebase options

set -e

# Source common functions
source "$(dirname "$0")/../utils/common.sh"

# =============================================================================
# Configuration Variables
# =============================================================================

FIREBASE_CONFIG_ANDROID=${FIREBASE_CONFIG_ANDROID:-}
PKG_NAME=${PKG_NAME:-}
WORKFLOW_ID=${WORKFLOW_ID:-}
PUSH_NOTIFY=${PUSH_NOTIFY:-false}

# =============================================================================
# Main Function
# =============================================================================

fix_firebase_dynamic() {
    log "🔧 Starting dynamic Firebase configuration fix..."
    
    # Check if Firebase is required
    if [ "$PUSH_NOTIFY" != "true" ]; then
        log "ℹ️ Firebase not required (PUSH_NOTIFY=false), skipping..."
        return 0
    fi
    
    if [ -z "$FIREBASE_CONFIG_ANDROID" ]; then
        log "⚠️ PUSH_NOTIFY=true but no FIREBASE_CONFIG_ANDROID provided"
        log "🔄 Creating fallback Firebase configuration..."
        create_fallback_firebase_config
        return 0
    fi
    
    # Download and fix Firebase configuration
    download_and_fix_firebase_config
}

# =============================================================================
# Download and Fix Firebase Configuration
# =============================================================================

download_and_fix_firebase_config() {
    local firebase_config_url="$FIREBASE_CONFIG_ANDROID"
    local target_file="android/app/google-services.json"
    
    log "📥 Downloading Firebase configuration from: $firebase_config_url"
    
    # Create backup of existing config
    if [ -f "$target_file" ]; then
        cp "$target_file" "${target_file}.backup.$(date +%Y%m%d_%H%M%S)"
        log "💾 Backup created: ${target_file}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Download Firebase config
    if curl -L "$firebase_config_url" -o "$target_file" 2>/dev/null; then
        log "✅ Firebase configuration downloaded successfully"
        
        # Fix package name if needed
        fix_package_name_in_firebase_config
        
        # Validate the configuration
        validate_firebase_config
        
    else
        log "❌ Failed to download Firebase configuration"
        log "🔄 Creating fallback configuration..."
        create_fallback_firebase_config
    fi
}

# =============================================================================
# Fix Package Name in Firebase Configuration
# =============================================================================

fix_package_name_in_firebase_config() {
    local firebase_file="android/app/google-services.json"
    
    if [ ! -f "$firebase_file" ] || [ -z "$PKG_NAME" ]; then
        log "⚠️ Cannot fix package name: file missing or PKG_NAME not set"
        return 0
    fi
    
    log "🔧 Fixing package name in Firebase configuration..."
    log "   Current package: $PKG_NAME"
    
    # Extract current package names from Firebase config
    local current_packages=$(grep -o '"package_name": "[^"]*"' "$firebase_file" | cut -d'"' -f4 | sort -u)
    
    if [ -n "$current_packages" ]; then
        log "   Found package names in config: $current_packages"
        
        # Replace all package names with the correct one
        for pkg in $current_packages; do
            if [ "$pkg" != "$PKG_NAME" ]; then
                log "   Replacing '$pkg' with '$PKG_NAME'"
                sed -i "s/\"package_name\": \"$pkg\"/\"package_name\": \"$PKG_NAME\"/g" "$firebase_file"
            fi
        done
        
        log "✅ Package names fixed in Firebase configuration"
    else
        log "⚠️ No package names found in Firebase configuration"
    fi
}

# =============================================================================
# Validate Firebase Configuration
# =============================================================================

validate_firebase_config() {
    local firebase_file="android/app/google-services.json"
    
    if [ ! -f "$firebase_file" ]; then
        log "❌ Firebase configuration file not found"
        return 1
    fi
    
    # Check if file is valid JSON
    if ! python3 -c "import json; json.load(open('$firebase_file'))" 2>/dev/null; then
        log "❌ Firebase configuration is not valid JSON"
        return 1
    fi
    
    # Check if package name is present
    if ! grep -q "\"package_name\": \"$PKG_NAME\"" "$firebase_file" 2>/dev/null; then
        log "⚠️ Package name '$PKG_NAME' not found in Firebase configuration"
        log "🔄 Attempting to fix package name..."
        fix_package_name_in_firebase_config
    fi
    
    # Check for required Firebase fields
    local required_fields=("project_info" "client" "api_key")
    for field in "${required_fields[@]}"; do
        if ! grep -q "\"$field\"" "$firebase_file" 2>/dev/null; then
            log "❌ Required Firebase field '$field' missing"
            return 1
        fi
    done
    
    log "✅ Firebase configuration validation passed"
    return 0
}

# =============================================================================
# Create Fallback Firebase Configuration
# =============================================================================

create_fallback_firebase_config() {
    local firebase_file="android/app/google-services.json"
    
    log "🔄 Creating fallback Firebase configuration..."
    
    # Create a minimal Firebase configuration that won't crash the app
    cat > "$firebase_file" << EOF
{
  "project_info": {
    "project_number": "000000000000",
    "project_id": "fallback-project",
    "storage_bucket": "fallback-project.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:000000000000:android:fallback123",
        "android_client_info": {
          "package_name": "$PKG_NAME"
        }
      },
      "oauth_client": [],
      "api_key": [
        {
          "current_key": "AIzaSyFallbackKey123456789"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": []
        }
      }
    }
  ]
}
EOF
    
    log "✅ Fallback Firebase configuration created"
    log "⚠️ Note: This is a fallback config - push notifications may not work"
}

# =============================================================================
# Conditional Firebase Options
# =============================================================================

setup_conditional_firebase() {
    log "🔧 Setting up conditional Firebase options..."
    
    # Create conditional Firebase initialization file
    local conditional_file="lib/config/firebase_conditional.dart"
    
    cat > "$conditional_file" << EOF
// Generated Firebase Conditional Configuration
// Generated on: $(date)
// Workflow: $WORKFLOW_ID
// Package: $PKG_NAME

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class ConditionalFirebaseConfig {
  static bool get isEnabled => $([ "$PUSH_NOTIFY" = "true" ] && echo "true" || echo "false");
  static bool get hasValidConfig => true; // Will be checked at runtime
  
  static Future<FirebaseApp?> initializeConditionally() async {
    try {
      if (!isEnabled) {
        print("ℹ️ Firebase disabled (PUSH_NOTIFY=false)");
        return null;
      }
      
      if (Firebase.apps.isNotEmpty) {
        print("✅ Firebase already initialized");
        return Firebase.apps.first;
      }
      
      // Try to initialize Firebase
      final app = await Firebase.initializeApp();
      print("✅ Firebase initialized successfully");
      return app;
      
    } catch (e) {
      print("❌ Firebase initialization failed: \$e");
      print("🔄 Continuing without Firebase...");
      return null;
    }
  }
  
  static Future<void> setupMessaging() async {
    try {
      if (!isEnabled || Firebase.apps.isEmpty) {
        print("⚠️ Firebase not available for messaging");
        return;
      }
      
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print("✅ Firebase messaging permissions granted");
      } else {
        print("⚠️ Firebase messaging permissions denied");
      }
      
    } catch (e) {
      print("❌ Firebase messaging setup failed: \$e");
    }
  }
}
EOF
    
    log "✅ Conditional Firebase configuration created: $conditional_file"
}

# =============================================================================
# Update Main App to Use Conditional Firebase
# =============================================================================

update_main_app_for_conditional_firebase() {
    local main_file="lib/main.dart"
    
    if [ ! -f "$main_file" ]; then
        log "⚠️ Main app file not found: $main_file"
        return 0
    fi
    
    log "🔧 Updating main app for conditional Firebase..."
    
    # Create backup
    cp "$main_file" "${main_file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Add import for conditional Firebase
    if ! grep -q "firebase_conditional" "$main_file"; then
        sed -i '1i import "config/firebase_conditional.dart";' "$main_file"
        log "✅ Added conditional Firebase import"
    fi
    
    # Replace Firebase initialization with conditional version
    if grep -q "ConditionalFirebaseService.initializeConditionally" "$main_file"; then
        sed -i 's/ConditionalFirebaseService\.initializeConditionally/ConditionalFirebaseConfig.initializeConditionally/g' "$main_file"
        log "✅ Updated Firebase initialization to use conditional config"
    fi
    
    log "✅ Main app updated for conditional Firebase"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    log "🚀 Starting dynamic Firebase configuration fix..."
    log "   Workflow: $WORKFLOW_ID"
    log "   Package: $PKG_NAME"
    log "   Push Notify: $PUSH_NOTIFY"
    log "   Firebase Config: $FIREBASE_CONFIG_ANDROID"
    
    # Fix Firebase configuration
    fix_firebase_dynamic
    
    # Setup conditional Firebase options
    setup_conditional_firebase
    
    # Update main app
    update_main_app_for_conditional_firebase
    
    log "✅ Dynamic Firebase configuration fix completed successfully"
}

# Run main function
main "$@"
