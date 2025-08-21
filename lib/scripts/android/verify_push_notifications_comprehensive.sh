#!/bin/bash
# 🔍 Comprehensive Push Notification Validation Script for Android
# Validates all push notification configurations and provides detailed compliance report

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ANDROID_PUSH_VALIDATION] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

echo "🔍 Comprehensive Android Push Notification Validation..."
echo "======================================================"

# Initialize validation counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Function to run a validation check
run_check() {
    local check_name="$1"
    local check_function="$2"
    local description="$3"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    log_info "🔍 Running: $check_name"
    
    if $check_function; then
        log_success "✅ PASS: $description"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        log_error "❌ FAIL: $description"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

# Function to run a warning check
run_warning_check() {
    local check_name="$1"
    local check_function="$2"
    local description="$3"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    log_info "🔍 Running: $check_name"
    
    if $check_function; then
        log_success "✅ PASS: $description"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        log_warning "⚠️ WARNING: $description"
        WARNING_CHECKS=$((WARNING_CHECKS + 1))
        return 0  # Warning doesn't fail the validation
    fi
}

echo ""
echo "📱 Phase 1: Environment Configuration Validation"
echo "================================================"

# Check 1: PUSH_NOTIFY environment variable
check_push_notify_enabled() {
    if [[ "${PUSH_NOTIFY:-false}" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# Check 2: Firebase configuration URL
check_firebase_config_url() {
    if [[ -n "${FIREBASE_CONFIG_ANDROID:-}" ]]; then
        return 0
    else
        return 1
    fi
}

# Check 3: Package name configuration
check_package_name_config() {
    if [[ -n "${PKG_NAME:-}" ]]; then
        return 0
    else
        return 1
    fi
}

run_check "PUSH_NOTIFY Environment" check_push_notify_enabled "Push notifications are enabled (PUSH_NOTIFY=true)"
run_check "Firebase Config URL" check_firebase_config_url "Firebase configuration URL is provided (FIREBASE_CONFIG_ANDROID)"
run_check "Package Name Config" check_package_name_config "Package name is configured (PKG_NAME)"

echo ""
echo "🔐 Phase 2: AndroidManifest.xml Validation"
echo "=========================================="

# Check 4: AndroidManifest.xml exists
check_manifest_exists() {
    [[ -f "android/app/src/main/AndroidManifest.xml" ]]
}

# Check 5: FCM service configured
check_fcm_service_configured() {
    grep -q "MyFirebaseMessagingService" android/app/src/main/AndroidManifest.xml
}

# Check 6: Notification receiver configured
check_notification_receiver_configured() {
    grep -q "NotificationReceiver" android/app/src/main/AndroidManifest.xml
}

# Check 7: WAKE_LOCK permission
check_wake_lock_permission() {
    grep -q "android.permission.WAKE_LOCK" android/app/src/main/AndroidManifest.xml
}

# Check 8: VIBRATE permission
check_vibrate_permission() {
    grep -q "android.permission.VIBRATE" android/app/src/main/AndroidManifest.xml
}

# Check 9: POST_NOTIFICATIONS permission
check_post_notifications_permission() {
    grep -q "android.permission.POST_NOTIFICATIONS" android/app/src/main/AndroidManifest.xml
}

run_check "Manifest Exists" check_manifest_exists "AndroidManifest.xml file exists"
run_check "FCM Service" check_fcm_service_configured "FCM service is configured in manifest"
run_check "Notification Receiver" check_notification_receiver_configured "Notification receiver is configured in manifest"
run_check "WAKE_LOCK Permission" check_wake_lock_permission "WAKE_LOCK permission is configured"
run_check "VIBRATE Permission" check_vibrate_permission "VIBRATE permission is configured"
run_check "POST_NOTIFICATIONS Permission" check_post_notifications_permission "POST_NOTIFICATIONS permission is configured"

echo ""
echo "🏗️ Phase 3: Source Code Validation"
echo "=================================="

# Check 10: NotificationChannelManager exists
check_notification_channel_manager() {
    if [[ -z "${PKG_NAME:-}" ]]; then
        return 1
    fi
    local package_dir=$(echo "$PKG_NAME" | sed 's/\./\//g')
    [[ -f "android/app/src/main/kotlin/$package_dir/NotificationChannelManager.kt" ]]
}

# Check 11: FCM service class exists
check_fcm_service_class() {
    if [[ -z "${PKG_NAME:-}" ]]; then
        return 1
    fi
    local package_dir=$(echo "$PKG_NAME" | sed 's/\./\//g')
    [[ -f "android/app/src/main/kotlin/$package_dir/MyFirebaseMessagingService.kt" ]]
}

# Check 12: Notification receiver class exists
check_notification_receiver_class() {
    if [[ -z "${PKG_NAME:-}" ]]; then
        return 1
    fi
    local package_dir=$(echo "$PKG_NAME" | sed 's/\./\//g')
    [[ -f "android/app/src/main/kotlin/$package_dir/NotificationReceiver.kt" ]]
}

# Check 13: MainActivity integration
check_mainactivity_integration() {
    if [[ -z "${PKG_NAME:-}" ]]; then
        return 1
    fi
    local main_activity_found=false
    local package_dir=$(echo "$PKG_NAME" | sed 's/\./\//g')
    
    for file in android/app/src/main/kotlin/$package_dir/MainActivity.kt \
                 android/app/src/main/java/$package_dir/MainActivity.java; do
        if [[ -f "$file" ]] && grep -q "NotificationChannelManager" "$file"; then
            main_activity_found=true
            break
        fi
    done
    
    [[ "$main_activity_found" == "true" ]]
}

run_check "NotificationChannelManager" check_notification_channel_manager "NotificationChannelManager.kt class exists"
run_check "FCM Service Class" check_fcm_service_class "MyFirebaseMessagingService.kt class exists"
run_check "Notification Receiver Class" check_notification_receiver_class "NotificationReceiver.kt class exists"
run_check "MainActivity Integration" check_mainactivity_integration "Notification channels are integrated in MainActivity"

echo ""
echo "📦 Phase 4: Build Configuration Validation"
echo "=========================================="

# Check 14: build.gradle.kts exists
check_build_gradle_exists() {
    [[ -f "android/app/build.gradle.kts" ]]
}

# Check 15: Firebase messaging dependency
check_firebase_messaging_dependency() {
    if [[ -f "android/app/build.gradle.kts" ]]; then
        grep -q "implementation.*firebase.*messaging" android/app/build.gradle.kts
    else
        return 1
    fi
}

# Check 16: Google services plugin
check_google_services_plugin() {
    if [[ -f "android/app/build.gradle.kts" ]]; then
        grep -q "apply.*google-services" android/app/build.gradle.kts
    else
        return 1
    fi
}

# Check 17: Project level build.gradle.kts
check_project_build_gradle() {
    [[ -f "android/build.gradle.kts" ]]
}

# Check 18: Google services classpath
check_google_services_classpath() {
    if [[ -f "android/build.gradle.kts" ]]; then
        grep -q "classpath.*google-services" android/build.gradle.kts
    else
        return 1
    fi
}

run_check "App Build.gradle.kts" check_build_gradle_exists "app/build.gradle.kts file exists"
run_check "Firebase Messaging Dependency" check_firebase_messaging_dependency "Firebase messaging dependency is configured"
run_check "Google Services Plugin" check_google_services_plugin "Google services plugin is applied"
run_check "Project Build.gradle.kts" check_project_build_gradle "project build.gradle.kts file exists"
run_check "Google Services Classpath" check_google_services_classpath "Google services classpath is configured"

echo ""
echo "🔥 Phase 5: Firebase Configuration Validation"
echo "============================================"

# Check 19: google-services.json exists
check_google_services_exists() {
    [[ -f "android/app/google-services.json" ]]
}

# Check 20: Firebase API key
check_firebase_api_key() {
    if [[ -f "android/app/google-services.json" ]]; then
        grep -q '"api_key"' android/app/google-services.json
    else
        return 1
    fi
}

# Check 21: Firebase project ID
check_firebase_project_id() {
    if [[ -f "android/app/google-services.json" ]]; then
        grep -q '"project_id"' android/app/google-services.json
    else
        return 1
    fi
}

# Check 22: Firebase client configuration
check_firebase_client() {
    if [[ -f "android/app/google-services.json" ]]; then
        grep -q '"client"' android/app/google-services.json
    else
        return 1
    fi
}

# Check 23: Package name consistency
check_package_name_consistency() {
    if [[ -f "android/app/google-services.json" ]] && [[ -f "android/app/src/main/AndroidManifest.xml" ]]; then
        local firebase_package=$(grep -o '"package_name": "[^"]*"' android/app/google-services.json | head -1 | cut -d'"' -f4)
        local manifest_package=$(grep -o 'package="[^"]*"' android/app/src/main/AndroidManifest.xml | cut -d'"' -f2)
        
        if [[ -n "$firebase_package" && -n "$manifest_package" ]]; then
            [[ "$firebase_package" == "$manifest_package" ]]
        else
            return 1
        fi
    else
        return 1
    fi
}

run_check "Google Services JSON" check_google_services_exists "google-services.json file exists"
run_check "Firebase API Key" check_firebase_api_key "Firebase API key is configured"
run_check "Firebase Project ID" check_firebase_project_id "Firebase project ID is configured"
run_check "Firebase Client" check_firebase_client "Firebase client configuration exists"
run_check "Package Name Consistency" check_package_name_consistency "Package names match between Firebase and manifest"

echo ""
echo "🔔 Phase 6: Notification Channel Validation"
echo "==========================================="

# Check 24: Notification channels are properly configured
check_notification_channels_config() {
    if [[ -f "android/app/src/main/kotlin/co/pixaware/pixaware/NotificationChannelManager.kt" ]]; then
        grep -q "push_notifications" android/app/src/main/kotlin/co/pixaware/pixaware/NotificationChannelManager.kt
    else
        return 1
    fi
}

# Check 25: Default notification channel
check_default_notification_channel() {
    if [[ -f "android/app/src/main/kotlin/co/pixaware/pixaware/NotificationChannelManager.kt" ]]; then
        grep -q '"default"' android/app/src/main/kotlin/co/pixaware/pixaware/NotificationChannelManager.kt
    else
        return 1
    fi
}

# Check 26: Background message channel
check_background_message_channel() {
    if [[ -f "android/app/src/main/kotlin/co/pixaware/pixaware/NotificationChannelManager.kt" ]]; then
        grep -q "background_messages" android/app/src/main/kotlin/co/pixaware/pixaware/NotificationChannelManager.kt
    else
        return 1
    fi
}

run_check "Push Notifications Channel" check_notification_channels_config "Push notifications channel is configured"
run_check "Default Channel" check_default_notification_channel "Default notification channel is configured"
run_check "Background Messages Channel" check_background_message_channel "Background messages channel is configured"

echo ""
echo "📱 Phase 7: Play Store Compliance Validation"
echo "==========================================="

# Check 27: Notification icon configuration
check_notification_icon() {
    if [[ -f "android/app/src/main/kotlin/co/pixaware/pixaware/MyFirebaseMessagingService.kt" ]]; then
        grep -q "setSmallIcon" android/app/src/main/kotlin/co/pixaware/pixaware/MyFirebaseMessagingService.kt
    else
        return 1
    fi
}

# Check 28: Notification priority configuration
check_notification_priority() {
    if [[ -f "android/app/src/main/kotlin/co/pixaware/pixaware/MyFirebaseMessagingService.kt" ]]; then
        grep -q "PRIORITY_HIGH" android/app/src/main/kotlin/co/pixaware/pixaware/MyFirebaseMessagingService.kt
    else
        return 1
    fi
}

# Check 29: Auto-cancel configuration
check_notification_auto_cancel() {
    if [[ -f "android/app/src/main/kotlin/co/pixaware/pixaware/MyFirebaseMessagingService.kt" ]]; then
        grep -q "setAutoCancel" android/app/src/main/kotlin/co/pixaware/pixaware/MyFirebaseMessagingService.kt
    else
        return 1
    fi
}

# Check 30: Sound configuration
check_notification_sound() {
    if [[ -f "android/app/src/main/kotlin/co/pixaware/pixaware/MyFirebaseMessagingService.kt" ]]; then
        grep -q "setSound" android/app/src/main/kotlin/co/pixaware/pixaware/MyFirebaseMessagingService.kt
    else
        return 1
    fi
}

run_check "Notification Icon" check_notification_icon "Notification icon is properly configured"
run_check "Notification Priority" check_notification_priority "Notification priority is set to HIGH"
run_check "Auto Cancel" check_notification_auto_cancel "Notifications are configured to auto-cancel"
run_check "Notification Sound" check_notification_sound "Notification sound is configured"

echo ""
echo "🔍 Phase 8: Final Validation Summary"
echo "===================================="

# Calculate validation results
log_info "📊 Validation Results Summary:"
echo "=========================================="
echo "✅ PASSED: $PASSED_CHECKS"
echo "❌ FAILED: $FAILED_CHECKS"
echo "⚠️ WARNINGS: $WARNING_CHECKS"
echo "🔍 TOTAL CHECKS: $TOTAL_CHECKS"
echo "=========================================="

# Calculate success percentage
if [[ $TOTAL_CHECKS -gt 0 ]]; then
    SUCCESS_PERCENTAGE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    echo "📈 SUCCESS RATE: $SUCCESS_PERCENTAGE%"
else
    SUCCESS_PERCENTAGE=0
    echo "📈 SUCCESS RATE: 0%"
fi

# Determine overall status
if [[ $FAILED_CHECKS -eq 0 ]]; then
    if [[ $WARNING_CHECKS -eq 0 ]]; then
        OVERALL_STATUS="✅ FULLY COMPLIANT"
        log_success "🎉 All validation checks passed! Your Android app is fully compliant for push notifications."
    else
        OVERALL_STATUS="⚠️ COMPLIANT WITH WARNINGS"
        log_warning "⚠️ All critical checks passed, but there are some warnings to address."
    fi
else
    OVERALL_STATUS="❌ NOT COMPLIANT"
    log_error "❌ Some validation checks failed. Please address the issues above before proceeding."
fi

echo ""
echo "🎯 OVERALL STATUS: $OVERALL_STATUS"
echo "=========================================="

# Generate detailed compliance report
log_info "📋 Generating detailed compliance report..."

cat > "android_push_notification_compliance_report.txt" << EOF
Android Push Notification Compliance Report
Generated: $(date)

📊 Validation Summary:
  - Total Checks: $TOTAL_CHECKS
  - Passed: $PASSED_CHECKS
  - Failed: $FAILED_CHECKS
  - Warnings: $WARNING_CHECKS
  - Success Rate: $SUCCESS_PERCENTAGE%

🎯 Overall Status: $OVERALL_STATUS

📱 Environment Configuration:
  - PUSH_NOTIFY: ${PUSH_NOTIFY:-false}
  - FIREBASE_CONFIG_ANDROID: ${FIREBASE_CONFIG_ANDROID:-not set}
  - PKG_NAME: ${PKG_NAME:-not set}

🔐 AndroidManifest.xml Status:
  - Manifest Exists: $(check_manifest_exists && echo "✅" || echo "❌")
  - FCM Service: $(check_fcm_service_configured && echo "✅" || echo "❌")
  - Notification Receiver: $(check_notification_receiver_configured && echo "✅" || echo "❌")
  - WAKE_LOCK Permission: $(check_wake_lock_permission && echo "✅" || echo "❌")
  - VIBRATE Permission: $(check_vibrate_permission && echo "✅" || echo "❌")
  - POST_NOTIFICATIONS Permission: $(check_post_notifications_permission && echo "✅" || echo "❌")

🏗️ Source Code Status:
  - NotificationChannelManager: $(check_notification_channel_manager && echo "✅" || echo "❌")
  - FCM Service Class: $(check_fcm_service_class && echo "✅" || echo "❌")
  - Notification Receiver Class: $(check_notification_receiver_class && echo "✅" || echo "❌")
  - MainActivity Integration: $(check_mainactivity_integration && echo "✅" || echo "❌")

📦 Build Configuration Status:
  - App Build.gradle.kts: $(check_build_gradle_exists && echo "✅" || echo "❌")
  - Firebase Messaging Dependency: $(check_firebase_messaging_dependency && echo "✅" || echo "❌")
  - Google Services Plugin: $(check_google_services_plugin && echo "✅" || echo "❌")
  - Project Build.gradle.kts: $(check_project_build_gradle && echo "✅" || echo "❌")
  - Google Services Classpath: $(check_google_services_classpath && echo "✅" || echo "❌")

🔥 Firebase Configuration Status:
  - Google Services JSON: $(check_google_services_exists && echo "✅" || echo "❌")
  - Firebase API Key: $(check_firebase_api_key && echo "✅" || echo "❌")
  - Firebase Project ID: $(check_firebase_project_id && echo "✅" || echo "❌")
  - Firebase Client: $(check_firebase_client && echo "✅" || echo "❌")
  - Package Name Consistency: $(check_package_name_consistency && echo "✅" || echo "❌")

🔔 Notification Channel Status:
  - Push Notifications Channel: $(check_notification_channels_config && echo "✅" || echo "❌")
  - Default Channel: $(check_default_notification_channel && echo "✅" || echo "❌")
  - Background Messages Channel: $(check_background_message_channel && echo "✅" || echo "❌")

📱 Play Store Compliance Status:
  - Notification Icon: $(check_notification_icon && echo "✅" || echo "❌")
  - Notification Priority: $(check_notification_priority && echo "✅" || echo "❌")
  - Auto Cancel: $(check_notification_auto_cancel && echo "✅" || echo "❌")
  - Notification Sound: $(check_notification_sound && echo "✅" || echo "❌")

📋 Next Steps:
EOF

if [[ $FAILED_CHECKS -gt 0 ]]; then
    cat >> "android_push_notification_compliance_report.txt" << EOF
  - Address all FAILED checks above before proceeding
  - Review the validation output for specific error details
  - Re-run validation after fixing issues
EOF
else
    cat >> "android_push_notification_compliance_report.txt" << EOF
  - All critical checks passed! ✅
  - Your app is ready for push notification testing
  - Consider addressing any warnings for optimal performance
EOF
fi

cat >> "android_push_notification_compliance_report.txt" << EOF

🔍 Troubleshooting:
  - Check the validation output above for specific error messages
  - Ensure all required files exist and are properly configured
  - Verify Firebase configuration is correct and accessible
  - Confirm package names match between Firebase and manifest

📱 Production Readiness:
  - Minimum Required: 80% success rate
  - Current Status: $SUCCESS_PERCENTAGE%
  - Production Ready: $([ $SUCCESS_PERCENTAGE -ge 80 ] && echo "✅ YES" || echo "❌ NO")
EOF

log_success "✅ Compliance report generated: android_push_notification_compliance_report.txt"

# Final status
echo ""
if [[ $FAILED_CHECKS -eq 0 ]]; then
    log_success "🎉 Android Push Notification Validation COMPLETED SUCCESSFULLY!"
    log_info "📱 Your Android app is ready for push notification testing and production deployment"
    exit 0
else
    log_error "❌ Android Push Notification Validation FAILED"
    log_warning "⚠️ Please address the failed checks above before proceeding"
    exit 1
fi
