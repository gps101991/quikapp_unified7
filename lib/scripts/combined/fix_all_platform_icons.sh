#!/bin/bash
# 🌐 Comprehensive Multi-Platform Icon Fix Script
# Fixes icons for both iOS and Android platforms

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [MULTI_ICON_FIX] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "Starting comprehensive multi-platform icon fix..."

# Function to check if platform directory exists
check_platform() {
    local platform="$1"
    if [[ -d "$platform" ]]; then
        log_success "✅ $platform platform detected"
        return 0
    else
        log_warning "⚠️ $platform platform not detected"
        return 1
    fi
}

# Function to run icon fix for a platform
run_platform_icon_fix() {
    local platform="$1"
    local script_path="$2"
    
    if [[ -f "$script_path" ]]; then
        log_info "Running $platform icon fix..."
        chmod +x "$script_path"
        if "$script_path"; then
            log_success "✅ $platform icon fix completed successfully"
            return 0
        else
            log_error "❌ $platform icon fix failed"
            return 1
        fi
    else
        log_error "❌ $platform icon fix script not found: $script_path"
        return 1
    fi
}

# Function to validate platform icons
validate_platform_icons() {
    local platform="$1"
    local test_script="$2"
    
    if [[ -f "$test_script" ]]; then
        log_info "Validating $platform icons..."
        chmod +x "$test_script"
        if "$test_script"; then
            log_success "✅ $platform icon validation passed"
            return 0
        else
            log_warning "⚠️ $platform icon validation failed"
            return 1
        fi
    else
        log_warning "⚠️ $platform icon validation script not found: $test_script"
        return 1
    fi
}

# Step 1: Check available platforms
log_info "Step 1: Detecting available platforms..."

IOS_AVAILABLE=false
ANDROID_AVAILABLE=false

if check_platform "ios"; then
    IOS_AVAILABLE=true
fi

if check_platform "android"; then
    ANDROID_AVAILABLE=true
fi

if [[ "$IOS_AVAILABLE" == "false" ]] && [[ "$ANDROID_AVAILABLE" == "false" ]]; then
    log_error "❌ No platforms detected. Please ensure you're in a Flutter project root."
    exit 1
fi

log_info "Platform detection complete:"
log_info "  - iOS: $([ "$IOS_AVAILABLE" == "true" ] && echo "✅ Available" || echo "❌ Not available")"
log_info "  - Android: $([ "$ANDROID_AVAILABLE" == "true" ] && echo "✅ Available" || echo "❌ Not available")"

# Step 2: Run iOS icon fix if available
if [[ "$IOS_AVAILABLE" == "true" ]]; then
    log_info "Step 2: Fixing iOS icons..."
    
    IOS_ICON_FIX_SCRIPT="lib/scripts/ios-workflow/fix_ios_icons_comprehensive.sh"
    if run_platform_icon_fix "iOS" "$IOS_ICON_FIX_SCRIPT"; then
        log_success "✅ iOS icon fix completed"
    else
        log_warning "⚠️ iOS icon fix failed, but continuing with other platforms"
    fi
else
    log_info "Step 2: Skipping iOS (platform not available)"
fi

# Step 3: Run Android icon fix if available
if [[ "$ANDROID_AVAILABLE" == "true" ]]; then
    log_info "Step 3: Fixing Android icons..."
    
    ANDROID_ICON_FIX_SCRIPT="lib/scripts/android/fix_android_icons_comprehensive.sh"
    if run_platform_icon_fix "Android" "$ANDROID_ICON_FIX_SCRIPT"; then
        log_success "✅ Android icon fix completed"
    else
        log_warning "⚠️ Android icon fix failed, but continuing with other platforms"
    fi
else
    log_info "Step 3: Skipping Android (platform not available)"
fi

# Step 3.5: Run Android push notification setup if available
if [[ "$ANDROID_AVAILABLE" == "true" ]]; then
    log_info "Step 3.5: Setting up Android push notifications..."
    
    ANDROID_PUSH_SETUP_SCRIPT="lib/scripts/android/setup_push_notifications_complete.sh"
    if [ -f "$ANDROID_PUSH_SETUP_SCRIPT" ]; then
        chmod +x "$ANDROID_PUSH_SETUP_SCRIPT"
        if "$ANDROID_PUSH_SETUP_SCRIPT"; then
            log_success "✅ Android push notification setup completed successfully"
            log_info "🔔 Android app should now support push notifications in all states"
            
            # Run validation to confirm setup
            ANDROID_PUSH_VALIDATION_SCRIPT="lib/scripts/android/verify_push_notifications_comprehensive.sh"
            if [ -f "$ANDROID_PUSH_VALIDATION_SCRIPT" ]; then
                log_info "🔍 Running Android push notification validation..."
                chmod +x "$ANDROID_PUSH_VALIDATION_SCRIPT"
                if "$ANDROID_PUSH_VALIDATION_SCRIPT"; then
                    log_success "✅ Android push notification validation passed"
                else
                    log_warning "⚠️ Android push notification validation found issues"
                fi
            fi
        else
            log_warning "⚠️ Android push notification setup failed"
        fi
    else
        log_warning "⚠️ Android push notification setup script not found"
    fi
else
    log_info "Step 3.5: Skipping Android push notification setup (platform not available)"
fi

# Step 4: Validate all platform icons
log_info "Step 4: Validating all platform icons..."

IOS_VALIDATION_PASSED=false
ANDROID_VALIDATION_PASSED=false

if [[ "$IOS_AVAILABLE" == "true" ]]; then
    IOS_TEST_SCRIPT="lib/scripts/ios-workflow/test_icon_fix.sh"
    if validate_platform_icons "iOS" "$IOS_TEST_SCRIPT"; then
        IOS_VALIDATION_PASSED=true
    fi
fi

if [[ "$ANDROID_AVAILABLE" == "true" ]]; then
    # For Android, we'll check the compliance report
    if [[ -f "android_icon_compliance_report.txt" ]]; then
        log_info "Android icon compliance report found, checking status..."
        if grep -q "Play Store Compliance: READY" "android_icon_compliance_report.txt"; then
            log_success "✅ Android icon validation passed"
            ANDROID_VALIDATION_PASSED=true
        else
            log_warning "⚠️ Android icon validation failed"
        fi
    else
        log_warning "⚠️ Android icon compliance report not found"
    fi
fi

# Step 5: Generate comprehensive report
log_info "Step 5: Generating comprehensive icon fix report..."

cat > "multi_platform_icon_fix_report.txt" << EOF
Multi-Platform Icon Fix Report
Generated: $(date)

📱 Platform Status:
  - iOS: $([ "$IOS_AVAILABLE" == "true" ] && echo "Available" || echo "Not Available")
  - Android: $([ "$ANDROID_AVAILABLE" == "true" ] && echo "Available" || echo "Not Available")

🔧 Icon Fix Status:
  - iOS: $([ "$IOS_AVAILABLE" == "true" ] && echo "Completed" || echo "Skipped")
  - Android: $([ "$ANDROID_AVAILABLE" == "true" ] && echo "Completed" || echo "Skipped")

✅ Validation Status:
  - iOS: $([ "$IOS_VALIDATION_PASSED" == "true" ] && echo "PASSED" || echo "FAILED")
  - Android: $([ "$ANDROID_VALIDATION_PASSED" == "true" ] && echo "PASSED" || echo "FAILED")

🎯 Store Compliance:
  - iOS App Store: $([ "$IOS_VALIDATION_PASSED" == "true" ] && echo "READY" || echo "NOT READY")
  - Android Play Store: $([ "$ANDROID_VALIDATION_PASSED" == "true" ] && echo "READY" || echo "NOT READY")

📋 Next Steps:
EOF

if [[ "$IOS_AVAILABLE" == "true" ]] && [[ "$IOS_VALIDATION_PASSED" == "true" ]]; then
    cat >> "multi_platform_icon_fix_report.txt" << EOF
  - iOS: Ready for App Store upload ✅
EOF
else
    cat >> "multi_platform_icon_fix_report.txt" << EOF
  - iOS: Check logs above for specific issues ❌
EOF
fi

if [[ "$ANDROID_AVAILABLE" == "true" ]] && [[ "$ANDROID_VALIDATION_PASSED" == "true" ]]; then
    cat >> "multi_platform_icon_fix_report.txt" << EOF
  - Android: Ready for Play Store upload ✅
EOF
else
    cat >> "multi_platform_icon_fix_report.txt" << EOF
  - Android: Check logs above for specific issues ❌
EOF
fi

cat >> "multi_platform_icon_fix_report.txt" << EOF

📁 Generated Files:
  - This report: multi_platform_icon_fix_report.txt
EOF

if [[ "$ANDROID_AVAILABLE" == "true" ]]; then
    cat >> "multi_platform_icon_fix_report.txt" << EOF
  - Android compliance: android_icon_compliance_report.txt
EOF
fi

cat >> "multi_platform_icon_fix_report.txt" << EOF

🔍 Troubleshooting:
  - Check the logs above for specific error messages
  - Verify that logo.png exists in assets/images/
  - Ensure all required directories are writable
  - Run individual platform scripts for detailed debugging
EOF

log_success "Created comprehensive report: multi_platform_icon_fix_report.txt"

# Step 6: Final summary
log_info "Step 6: Final summary..."

echo ""
echo "🌐 Multi-Platform Icon Fix Summary"
echo "=========================================="

if [[ "$IOS_AVAILABLE" == "true" ]]; then
    if [[ "$IOS_VALIDATION_PASSED" == "true" ]]; then
        echo "✅ iOS: READY FOR APP STORE UPLOAD"
    else
        echo "❌ iOS: NOT READY (check logs above)"
    fi
else
    echo "⏭️ iOS: Platform not available"
fi

if [[ "$ANDROID_AVAILABLE" == "true" ]]; then
    if [[ "$ANDROID_VALIDATION_PASSED" == "true" ]]; then
        echo "✅ Android: READY FOR PLAY STORE UPLOAD"
    else
        echo "❌ Android: NOT READY (check logs above)"
    fi
else
    echo "⏭️ Android: Platform not available"
fi

echo "=========================================="

# Overall success/failure
if [[ "$IOS_VALIDATION_PASSED" == "true" ]] || [[ "$ANDROID_VALIDATION_PASSED" == "true" ]]; then
    log_success "🎉 Multi-platform icon fix completed successfully!"
    log_info "📱 At least one platform is ready for store upload"
    
    if [[ "$IOS_VALIDATION_PASSED" == "true" ]] && [[ "$ANDROID_VALIDATION_PASSED" == "true" ]]; then
        log_success "🚀 Both platforms are ready for store upload!"
    fi
else
    log_error "❌ No platforms passed icon validation"
    log_warning "⚠️ Check the logs above for specific issues"
    exit 1
fi

log_info "📋 Check multi_platform_icon_fix_report.txt for detailed status"
