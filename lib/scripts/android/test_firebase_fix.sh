#!/bin/bash

# =============================================================================
# Test Firebase Fix Script
# =============================================================================
# Tests the dynamic Firebase configuration fix

set -e

# Source common functions
source "$(dirname "$0")/../utils/common.sh"

# Test configuration
FIREBASE_CONFIG_ANDROID="https://raw.githubusercontent.com/prasanna91/QuikApp/main/google-services-pixaware.json"
PKG_NAME="co.pixaware.pixaware"
WORKFLOW_ID="android-publish"
PUSH_NOTIFY="true"

log_info "🧪 Testing Firebase Fix Script..."
log_info "   FIREBASE_CONFIG_ANDROID: $FIREBASE_CONFIG_ANDROID"
log_info "   PKG_NAME: $PKG_NAME"
log_info "   WORKFLOW_ID: $WORKFLOW_ID"
log_info "   PUSH_NOTIFY: $PUSH_NOTIFY"

# Test the dynamic Firebase fix script
if [ -f "lib/scripts/android/fix_firebase_dynamic.sh" ]; then
    log_info "✅ Firebase fix script found, testing..."
    
    # Make it executable
    chmod +x lib/scripts/android/fix_firebase_dynamic.sh
    
    # Run the script
    if lib/scripts/android/fix_firebase_dynamic.sh; then
        log_success "✅ Firebase fix script executed successfully"
        
        # Check if files were created
        if [ -f "android/app/google-services.json" ]; then
            log_success "✅ google-services.json created/updated"
            
            # Check package name
            if grep -q "\"package_name\": \"$PKG_NAME\"" "android/app/google-services.json"; then
                log_success "✅ Package name correctly set to $PKG_NAME"
            else
                log_warning "⚠️ Package name not found or incorrect in google-services.json"
            fi
            
            # Check if it's valid JSON
            if python3 -c "import json; json.load(open('android/app/google-services.json'))" 2>/dev/null; then
                log_success "✅ google-services.json is valid JSON"
            else
                log_error "❌ google-services.json is not valid JSON"
            fi
        else
            log_error "❌ google-services.json not found"
        fi
        
        if [ -f "lib/config/firebase_conditional.dart" ]; then
            log_success "✅ firebase_conditional.dart created"
        else
            log_warning "⚠️ firebase_conditional.dart not found"
        fi
        
    else
        log_error "❌ Firebase fix script failed"
        exit 1
    fi
    
else
    log_error "❌ Firebase fix script not found: lib/scripts/android/fix_firebase_dynamic.sh"
    exit 1
fi

log_success "🎉 Firebase fix test completed successfully!"
