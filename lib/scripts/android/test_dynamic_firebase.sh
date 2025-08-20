#!/bin/bash
# =============================================================================
# Test Dynamic Firebase Configuration Script
# =============================================================================
# Tests the dynamic Firebase configuration with different flag combinations
set -e

source "$(dirname "$0")/../utils/common.sh"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [TEST_FIREBASE] $1"; }

# Test scenarios
test_scenario_1() {
    log "🧪 Testing Scenario 1: PUSH_NOTIFY=true, IS_GOOGLE_AUTH=false (Firebase needed)"
    export PUSH_NOTIFY="true"
    export IS_GOOGLE_AUTH="false"
    export FIREBASE_CONFIG_ANDROID="https://raw.githubusercontent.com/prasanna91/QuikApp/main/google-services-pixaware.json"
    export WORKFLOW_ID="android-publish"
    export PKG_NAME="co.pixaware.pixaware"
    
    log "   - PUSH_NOTIFY: $PUSH_NOTIFY"
    log "   - IS_GOOGLE_AUTH: $IS_GOOGLE_AUTH"
    log "   - Expected: Firebase should be configured"
    
    if lib/scripts/android/dynamic_firebase_setup.sh; then
        log "✅ Scenario 1 passed: Firebase configured successfully"
        
        # Verify files were created
        if [ -f "android/app/google-services.json" ]; then
            log "✅ google-services.json created"
        else
            log "❌ google-services.json not created"
            return 1
        fi
        
        if grep -q 'id("com.google.gms.google-services")' "android/app/build.gradle.kts"; then
            log "✅ Firebase plugin added to build.gradle.kts"
        else
            log "❌ Firebase plugin not added to build.gradle.kts"
            return 1
        fi
        
        return 0
    else
        log "❌ Scenario 1 failed"
        return 1
    fi
}

test_scenario_2() {
    log "🧪 Testing Scenario 2: PUSH_NOTIFY=false, IS_GOOGLE_AUTH=true (Firebase needed)"
    export PUSH_NOTIFY="false"
    export IS_GOOGLE_AUTH="true"
    export FIREBASE_CONFIG_ANDROID="https://raw.githubusercontent.com/prasanna91/QuikApp/main/google-services-pixaware.json"
    export WORKFLOW_ID="android-publish"
    export PKG_NAME="co.pixaware.pixaware"
    
    log "   - PUSH_NOTIFY: $PUSH_NOTIFY"
    log "   - IS_GOOGLE_AUTH: $IS_GOOGLE_AUTH"
    log "   - Expected: Firebase should be configured"
    
    if lib/scripts/android/dynamic_firebase_setup.sh; then
        log "✅ Scenario 2 passed: Firebase configured successfully"
        return 0
    else
        log "❌ Scenario 2 failed"
        return 1
    fi
}

test_scenario_3() {
    log "🧪 Testing Scenario 3: PUSH_NOTIFY=false, IS_GOOGLE_AUTH=false (Firebase not needed)"
    export PUSH_NOTIFY="false"
    export IS_GOOGLE_AUTH="false"
    export FIREBASE_CONFIG_ANDROID=""
    export WORKFLOW_ID="android-free"
    export PKG_NAME="co.pixaware.pixaware"
    
    log "   - PUSH_NOTIFY: $PUSH_NOTIFY"
    log "   - IS_GOOGLE_AUTH: $IS_GOOGLE_AUTH"
    log "   - Expected: Firebase should be skipped"
    
    if lib/scripts/android/dynamic_firebase_setup.sh; then
        log "✅ Scenario 3 passed: Firebase skipped successfully"
        
        # Verify Firebase files were removed
        if [ ! -f "android/app/google-services.json" ]; then
            log "✅ google-services.json removed (Firebase not needed)"
        else
            log "❌ google-services.json still exists (should be removed)"
            return 1
        fi
        
        return 0
    else
        log "❌ Scenario 3 failed"
        return 1
    fi
}

test_scenario_4() {
    log "🧪 Testing Scenario 4: Invalid Firebase config URL (should create fallback)"
    export PUSH_NOTIFY="true"
    export IS_GOOGLE_AUTH="false"
    export FIREBASE_CONFIG_ANDROID="https://invalid-url-that-does-not-exist.com/config.json"
    export WORKFLOW_ID="android-publish"
    export PKG_NAME="co.pixaware.pixaware"
    
    log "   - PUSH_NOTIFY: $PUSH_NOTIFY"
    log "   - IS_GOOGLE_AUTH: $IS_GOOGLE_AUTH"
    log "   - Invalid URL: $FIREBASE_CONFIG_ANDROID"
    log "   - Expected: Fallback Firebase config should be created"
    
    if lib/scripts/android/dynamic_firebase_setup.sh; then
        log "✅ Scenario 4 passed: Fallback config created successfully"
        
        # Verify fallback config was created
        if [ -f "android/app/google-services.json" ]; then
            if grep -q "fallback-project" "android/app/google-services.json"; then
                log "✅ Fallback Firebase config created"
                return 0
            else
                log "❌ Fallback config doesn't contain expected content"
                return 1
            fi
        else
            log "❌ Fallback config not created"
            return 1
        fi
    else
        log "❌ Scenario 4 failed"
        return 1
    fi
}

# Cleanup function
cleanup() {
    log "🧹 Cleaning up test files..."
    
    # Remove test Firebase config
    if [ -f "android/app/google-services.json" ]; then
        rm "android/app/google-services.json"
        log "🗑️ Removed test google-services.json"
    fi
    
    # Restore original build.gradle.kts if backup exists
    local backup_file=$(find android/app -name "build.gradle.kts.backup.*" | head -1)
    if [ -n "$backup_file" ]; then
        cp "$backup_file" "android/app/build.gradle.kts"
        log "🔄 Restored original build.gradle.kts"
    fi
    
    # Restore original settings.gradle.kts if backup exists
    local settings_backup=$(find android -name "settings.gradle.kts.backup.*" | head -1)
    if [ -n "$settings_backup" ]; then
        cp "$settings_backup" "android/settings.gradle.kts"
        log "🔄 Restored original settings.gradle.kts"
    fi
}

# Main test execution
main() {
    log "🚀 Starting Dynamic Firebase Configuration Tests..."
    
    local total_tests=4
    local passed_tests=0
    local failed_tests=0
    
    # Test 1: PUSH_NOTIFY=true, IS_GOOGLE_AUTH=false
    if test_scenario_1; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
    
    # Test 2: PUSH_NOTIFY=false, IS_GOOGLE_AUTH=true
    if test_scenario_2; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
    
    # Test 3: PUSH_NOTIFY=false, IS_GOOGLE_AUTH=false
    if test_scenario_3; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
    
    # Test 4: Invalid Firebase config URL
    if test_scenario_4; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
    
    # Results
    log "📊 Test Results:"
    log "   - Total Tests: $total_tests"
    log "   - Passed: $passed_tests"
    log "   - Failed: $failed_tests"
    
    if [ $failed_tests -eq 0 ]; then
        log "🎉 All tests passed! Dynamic Firebase configuration is working correctly."
        return 0
    else
        log "❌ Some tests failed. Please check the logs above."
        return 1
    fi
}

# Trap cleanup on exit
trap cleanup EXIT

# Execute main function
main "$@"
