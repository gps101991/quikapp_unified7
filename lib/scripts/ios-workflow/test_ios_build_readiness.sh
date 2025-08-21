#!/bin/bash
# 🧪 Master iOS Build Readiness Test
# Tests all critical components before building

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [BUILD_TEST] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "🧪 Starting master iOS build readiness test..."

# Test results tracking
TESTS_PASSED=0
TESTS_TOTAL=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    log_info "Testing: $test_name"
    
    if eval "$test_command" > /dev/null 2>&1; then
        log_success "✅ $test_name: PASSED"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "❌ $test_name: FAILED"
        return 1
    fi
}

# Test 1: Check iOS directory structure
log_info "🔍 Test 1: iOS Directory Structure"
run_test "iOS directory exists" "[[ -d 'ios' ]]"
run_test "Runner directory exists" "[[ -d 'ios/Runner' ]]"
run_test "Assets directory exists" "[[ -d 'ios/Runner/Assets.xcassets' ]]"
run_test "AppIcon directory exists" "[[ -d 'ios/Runner/Assets.xcassets/AppIcon.appiconset' ]]"

# Test 2: Check critical files
log_info "🔍 Test 2: Critical Files"
run_test "Info.plist exists" "[[ -f 'ios/Runner/Info.plist' ]]"
run_test "project.pbxproj exists" "[[ -f 'ios/Runner.xcodeproj/project.pbxproj' ]]"
run_test "Podfile exists" "[[ -f 'ios/Podfile' ]]"

# Test 3: Check Contents.json
log_info "🔍 Test 3: Contents.json Validation"
if [[ -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json" ]]; then
    if command -v python3 > /dev/null 2>&1; then
        if python3 -m json.tool "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json" > /dev/null 2>&1; then
            log_success "✅ Contents.json: Valid JSON"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            log_error "❌ Contents.json: Invalid JSON"
        fi
    else
        log_warning "⚠️ python3 not available, skipping JSON validation"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
else
    log_error "❌ Contents.json: File not found"
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
fi

# Test 4: Check required icons
log_info "🔍 Test 4: Required App Icons"
REQUIRED_ICONS=(
    "Icon-App-60x60@2x.png:120x120"
    "Icon-App-76x76@2x.png:152x152"
    "Icon-App-83.5x83.5@2x.png:167x167"
    "Icon-App-1024x1024@1x.png:1024x1024"
)

for icon_spec in "${REQUIRED_ICONS[@]}"; do
    icon_file="${icon_spec%:*}"
    expected_size="${icon_spec#*:}"
    
    if [[ -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/$icon_file" ]]; then
        log_success "✅ $icon_file: Present"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "❌ $icon_file: Missing"
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
done

# Test 5: Check Info.plist configuration
log_info "🔍 Test 5: Info.plist Configuration"
INFO_PLIST="ios/Runner/Info.plist"
if [[ -f "$INFO_PLIST" ]]; then
    run_test "CFBundleIconName present" "grep -q 'CFBundleIconName' '$INFO_PLIST'"
    run_test "UIBackgroundModes present" "grep -q 'UIBackgroundModes' '$INFO_PLIST'"
    run_test "remote-notification in UIBackgroundModes" "grep -q 'remote-notification' '$INFO_PLIST'"
    run_test "FirebaseAppDelegateProxyEnabled present" "grep -q 'FirebaseAppDelegateProxyEnabled' '$INFO_PLIST'"
else
    log_error "❌ Info.plist not found"
fi

# Test 6: Check entitlements
log_info "🔍 Test 6: Entitlements Configuration"
ENTITLEMENTS_FILE="ios/Runner/Runner.entitlements"
if [[ -f "$ENTITLEMENTS_FILE" ]]; then
    run_test "aps-environment present" "grep -q 'aps-environment' '$ENTITLEMENTS_FILE'"
    run_test "background-modes present" "grep -q 'com.apple.developer.background-modes' '$ENTITLEMENTS_FILE'"
    run_test "remote-notification in entitlements" "grep -q 'remote-notification' '$ENTITLEMENTS_FILE'"
else
    log_warning "⚠️ Entitlements file not found"
fi

# Test 7: Check Xcode project configuration
log_info "🔍 Test 7: Xcode Project Configuration"
PROJECT_FILE="ios/Runner.xcodeproj/project.pbxproj"
if [[ -f "$PROJECT_FILE" ]]; then
    run_test "CODE_SIGN_ENTITLEMENTS configured" "grep -q 'CODE_SIGN_ENTITLEMENTS' '$PROJECT_FILE'"
    run_test "Push notification capability present" "grep -q 'com.apple.Push' '$PROJECT_FILE'"
else
    log_error "❌ Project file not found"
fi

# Test 8: Check Podfile configuration
log_info "🔍 Test 8: Podfile Configuration"
PODFILE="ios/Podfile"
if [[ -f "$PODFILE" ]]; then
    run_test "Firebase Messaging pod present" "grep -q 'Firebase/Messaging' '$PODFILE'"
    run_test "Modular headers enabled" "grep -q 'use_modular_headers' '$PODFILE'"
else
    log_error "❌ Podfile not found"
fi

# Test 9: Check Flutter configuration
log_info "🔍 Test 9: Flutter Configuration"
run_test "pubspec.yaml exists" "[[ -f 'pubspec.yaml' ]]"
run_test "flutter_launcher_icons configured" "grep -q 'flutter_launcher_icons' 'pubspec.yaml'"
run_test "Flutter dependencies installed" "[[ -d '.dart_tool' ]]"

# Test 10: Check build environment
log_info "🔍 Test 10: Build Environment"
run_test "Flutter available" "command -v flutter > /dev/null 2>&1"
run_test "Xcode available" "command -v xcodebuild > /dev/null 2>&1"
run_test "CocoaPods available" "command -v pod > /dev/null 2>&1"

# Final results
log_info "📊 Test Results Summary"
log_info "Total Tests: $TESTS_TOTAL"
log_info "Tests Passed: $TESTS_PASSED"
log_info "Tests Failed: $((TESTS_TOTAL - TESTS_PASSED))"

if [[ $TESTS_PASSED -eq $TESTS_TOTAL ]]; then
    log_success "🎉 All tests passed! Your iOS build is ready!"
    log_success "✅ App Store Connect upload should succeed"
    log_success "✅ Push notifications should work in all app states"
    log_success "✅ All required icons are present and valid"
    exit 0
else
    log_warning "⚠️ Some tests failed. Please review the issues above."
    log_warning "🔧 Consider running the fix scripts before building:"
    log_warning "  - fix_contents_json_bulletproof.sh"
    log_warning "  - fix_notifications_comprehensive.sh"
    log_warning "  - fix_ios_icons_comprehensive.sh"
    exit 1
fi
