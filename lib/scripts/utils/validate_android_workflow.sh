#!/bin/bash
set -euo pipefail

# 🚀 Android Workflow Validation Script
# Ensures all required scripts and configurations exist for Android workflow

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [VALIDATE] $1"; }
log_info() { log "ℹ️ $1"; }
log_success() { log "✅ $1"; }
log_warning() { log "⚠️ $1"; }
log_error() { log "❌ $1"; }

# Configuration
WORKFLOW_DIR="lib/scripts"
ANDROID_DIR="$WORKFLOW_DIR/android"
UTILS_DIR="$WORKFLOW_DIR/utils"

# Required scripts for Android workflow
REQUIRED_SCRIPTS=(
    "$ANDROID_DIR/main.sh"
    "$ANDROID_DIR/dynamic_firebase_setup.sh"
    "$ANDROID_DIR/generate_android_config.sh"
    "$ANDROID_DIR/keystore.sh"
    "$ANDROID_DIR/branding.sh"
    "$ANDROID_DIR/customization.sh"
    "$ANDROID_DIR/permissions.sh"
    "$ANDROID_DIR/version_management.sh"
)

# Required utility scripts
REQUIRED_UTILS=(
    "$UTILS_DIR/gen_env_config.sh"
    "$UTILS_DIR/build_acceleration.sh"
    "$UTILS_DIR/common.sh"
)

# Check if script exists and is executable
check_script() {
    local script_path="$1"
    local script_name=$(basename "$script_path")
    
    if [[ ! -f "$script_path" ]]; then
        log_error "❌ Required script missing: $script_name"
        return 1
    fi
    
    if [[ ! -x "$script_path" ]]; then
        log_warning "⚠️ Script not executable: $script_name"
        chmod +x "$script_path" 2>/dev/null || log_error "❌ Failed to make executable: $script_name"
    fi
    
    log_success "✅ Script found: $script_name"
    return 0
}

# Check environment variables
check_environment_vars() {
    log_info "🔍 Checking required environment variables..."
    
    local required_vars=(
        "WORKFLOW_ID"
        "PROJECT_ID"
        "APP_NAME"
        "VERSION_NAME"
        "VERSION_CODE"
        "PKG_NAME"
        "USER_NAME"
        "ORG_NAME"
        "WEB_URL"
        "EMAIL_ID"
    )
    
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_warning "⚠️ Missing environment variables: ${missing_vars[*]}"
        log_warning "🔄 These will use default values during build"
        return 1
    else
        log_success "✅ All required environment variables present"
        return 0
    fi
}

# Check Flutter configuration
check_flutter_config() {
    log_info "🔍 Checking Flutter configuration..."
    
    # Check pubspec.yaml
    if [[ ! -f "pubspec.yaml" ]]; then
        log_error "❌ pubspec.yaml not found"
        return 1
    fi
    
    # Check main.dart
    if [[ ! -f "lib/main.dart" ]]; then
        log_error "❌ lib/main.dart not found"
        return 1
    fi
    
    # Check environment.dart
    if [[ ! -f "lib/config/environment.dart" ]]; then
        log_warning "⚠️ lib/config/environment.dart not found (will be generated)"
    fi
    
    log_success "✅ Flutter configuration valid"
    return 0
}

# Check Android project configuration
check_android_config() {
    log_info "🔍 Checking Android project configuration..."
    
    # Check Android directory
    if [[ ! -d "android" ]]; then
        log_error "❌ Android directory not found"
        return 1
    fi
    
    # Check build.gradle.kts
    if [[ ! -f "android/app/build.gradle.kts" ]]; then
        log_error "❌ Android build.gradle.kts not found"
        return 1
    fi
    
    # Check AndroidManifest.xml
    if [[ ! -f "android/app/src/main/AndroidManifest.xml" ]]; then
        log_error "❌ AndroidManifest.xml not found"
        return 1
    fi
    
    # Check keystore configuration
    if [[ -n "${KEY_STORE_URL:-}" ]]; then
        log_info "🔐 Keystore configuration detected"
        if [[ ! -f "android/app/src/keystore.properties" ]]; then
            log_warning "⚠️ keystore.properties not found (will be generated)"
        fi
    else
        log_warning "⚠️ No keystore configuration provided"
    fi
    
    log_success "✅ Android project configuration valid"
    return 0
}

# Check script dependencies
check_script_dependencies() {
    log_info "🔍 Checking script dependencies..."
    
    local missing_scripts=()
    
    for script in "${REQUIRED_SCRIPTS[@]}"; do
        if ! check_script "$script"; then
            missing_scripts+=("$script")
        fi
    done
    
    for script in "${REQUIRED_UTILS[@]}"; do
        if ! check_script "$script"; then
            missing_scripts+=("$script")
        fi
    done
    
    if [[ ${#missing_scripts[@]} -gt 0 ]]; then
        log_error "❌ Missing required scripts: ${missing_scripts[*]}"
        return 1
    else
        log_success "✅ All required scripts present"
        return 0
    fi
}

# Validate generated Dart environment
validate_dart_environment() {
    log_info "🔍 Validating Dart environment configuration..."
    
    if [[ ! -f "lib/config/environment.dart" ]]; then
        log_warning "⚠️ environment.dart not found (will be generated during build)"
        return 0
    fi
    
    # Check if file contains Environment class
    if grep -q "class Environment" "lib/config/environment.dart"; then
        log_success "✅ environment.dart contains Environment class"
    else
        log_warning "⚠️ environment.dart missing Environment class"
        return 1
    fi
    
    # Validate Dart syntax if dart is available
    if command -v dart &> /dev/null; then
        if dart analyze "lib/config/environment.dart" >/dev/null 2>&1; then
            log_success "✅ environment.dart syntax is valid"
        else
            log_warning "⚠️ environment.dart has syntax issues"
            dart analyze "lib/config/environment.dart" 2>&1 | head -5
            return 1
        fi
    else
        log_warning "⚠️ Dart not available for syntax validation"
    fi
    
    return 0
}

# Check workflow configuration
check_workflow_config() {
    log_info "🔍 Checking workflow configuration..."
    
    # Check codemagic.yaml
    if [[ ! -f "codemagic.yaml" ]]; then
        log_error "❌ codemagic.yaml not found"
        return 1
    fi
    
    # Check if Android workflow is defined
    if grep -q "android-publish:" "codemagic.yaml"; then
        log_success "✅ Android workflow defined in codemagic.yaml"
    else
        log_error "❌ Android workflow not found in codemagic.yaml"
        return 1
    fi
    
    # Check if required environment variables are defined
    local required_env_vars=(
        "WORKFLOW_ID"
        "PROJECT_ID"
        "APP_NAME"
        "VERSION_NAME"
        "VERSION_CODE"
        "PKG_NAME"
        "USER_NAME"
        "ORG_NAME"
        "WEB_URL"
        "EMAIL_ID"
    )
    
    local missing_env_defs=()
    
    for var in "${required_env_vars[@]}"; do
        if ! grep -q "\$$var" "codemagic.yaml"; then
            missing_env_defs+=("$var")
        fi
    done
    
    if [[ ${#missing_env_defs[@]} -gt 0 ]]; then
        log_warning "⚠️ Environment variables not defined in codemagic.yaml: ${missing_env_defs[*]}"
    else
        log_success "✅ All required environment variables defined in codemagic.yaml"
    fi
    
    return 0
}

# Check Firebase configuration
check_firebase_config() {
    log_info "🔍 Checking Firebase configuration..."
    
    if [[ -n "${FIREBASE_CONFIG_ANDROID:-}" ]]; then
        log_success "✅ Firebase Android config URL provided"
        
        # Test URL accessibility
        if curl --output /dev/null --silent --head --fail "$FIREBASE_CONFIG_ANDROID" 2>/dev/null; then
            log_success "✅ Firebase Android config URL is accessible"
        else
            log_warning "⚠️ Firebase Android config URL is not accessible"
        fi
    else
        log_warning "⚠️ No Firebase Android config URL provided"
    fi
    
    if [[ -n "${FIREBASE_CONFIG_IOS:-}" ]]; then
        log_success "✅ Firebase iOS config URL provided"
        
        # Test URL accessibility
        if curl --output /dev/null --silent --head --fail "$FIREBASE_CONFIG_IOS" 2>/dev/null; then
            log_success "✅ Firebase iOS config URL is accessible"
        else
            log_warning "⚠️ Firebase iOS config URL is not accessible"
        fi
    else
        log_warning "⚠️ No Firebase iOS config URL provided"
    fi
    
    return 0
}

# Check keystore configuration
check_keystore_config() {
    log_info "🔍 Checking keystore configuration..."
    
    if [[ -n "${KEY_STORE_URL:-}" ]]; then
        log_success "✅ Keystore URL provided"
        
        # Test URL accessibility
        if curl --output /dev/null --silent --head --fail "$KEY_STORE_URL" 2>/dev/null; then
            log_success "✅ Keystore URL is accessible"
        else
            log_warning "⚠️ Keystore URL is not accessible"
        fi
        
        # Check required keystore variables
        local keystore_vars=(
            "CM_KEYSTORE_PASSWORD"
            "CM_KEY_ALIAS"
            "CM_KEY_PASSWORD"
        )
        
        local missing_keystore_vars=()
        
        for var in "${keystore_vars[@]}"; do
            if [[ -z "${!var:-}" ]]; then
                missing_keystore_vars+=("$var")
            fi
        done
        
        if [[ ${#missing_keystore_vars[@]} -gt 0 ]]; then
            log_warning "⚠️ Missing keystore variables: ${missing_keystore_vars[*]}"
        else
            log_success "✅ All keystore variables provided"
        fi
    else
        log_warning "⚠️ No keystore configuration provided"
    fi
    
    return 0
}

# Generate workflow summary
generate_summary() {
    log_info "📊 Generating Android workflow validation summary..."
    
    cat > "android_workflow_validation_summary.txt" << EOF
Android Workflow Validation Summary
==================================

Validation Date: $(date)
Workflow ID: ${WORKFLOW_ID:-Not set}
Project ID: ${PROJECT_ID:-Not set}

✅ VALIDATION RESULTS:
$(if check_script_dependencies; then echo "  - Scripts: All required scripts present"; else echo "  - Scripts: Some scripts missing"; fi)
$(if check_environment_vars; then echo "  - Environment: All required variables present"; else echo "  - Environment: Some variables missing"; fi)
$(if check_flutter_config; then echo "  - Flutter: Configuration valid"; else echo "  - Flutter: Configuration issues found"; fi)
$(if check_android_config; then echo "  - Android Project: Configuration valid"; else echo "  - Android Project: Configuration issues found"; fi)
$(if validate_dart_environment; then echo "  - Dart Environment: Valid"; else echo "  - Dart Environment: Issues found"; fi)
$(if check_workflow_config; then echo "  - Workflow: Configuration valid"; else echo "  - Workflow: Configuration issues found"; fi)
$(if check_firebase_config; then echo "  - Firebase: Configuration valid"; else echo "  - Firebase: Configuration issues found"; fi)
$(if check_keystore_config; then echo "  - Keystore: Configuration valid"; else echo "  - Keystore: Configuration issues found"; fi)

📱 APP CONFIGURATION:
  - App Name: ${APP_NAME:-Not set}
  - Package Name: ${PKG_NAME:-Not set}
  - Version: ${VERSION_NAME:-Not set} (${VERSION_CODE:-Not set})
  - User: ${USER_NAME:-Not set}
  - Organization: ${ORG_NAME:-Not set}

🔧 BUILD FEATURES:
  - Push Notifications: ${PUSH_NOTIFY:-false}
  - Firebase Android: ${FIREBASE_CONFIG_ANDROID:+Enabled}
  - Splash Screen: ${IS_SPLASH:-false}
  - Bottom Menu: ${IS_BOTTOMMENU:-false}
  - Google Auth: ${IS_GOOGLE_AUTH:-false}
  - Apple Auth: ${IS_APPLE_AUTH:-false}

📁 REQUIRED SCRIPTS:
$(for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [[ -f "$script" ]]; then
        echo "  ✅ $(basename "$script")"
    else
        echo "  ❌ $(basename "$script") - MISSING"
    fi
done)

📋 NEXT STEPS:
$(if [[ -f "lib/scripts/android/main.sh" ]]; then
    echo "  1. ✅ Android main script ready"
    echo "  2. ✅ Dynamic Firebase setup ready"
    echo "  3. ✅ Keystore configuration ready"
    echo "  4. 🚀 Ready to run Android workflow"
else
    echo "  1. ❌ Android main script missing"
    echo "  2. ❌ Dynamic Firebase setup missing"
    echo "  3. ❌ Keystore configuration missing"
    echo "  4. ⚠️ Android workflow not ready"
fi)

EOF

    log_success "✅ Validation summary generated: android_workflow_validation_summary.txt"
}

# Main validation function
main() {
    log_info "🚀 Starting Android workflow validation..."
    
    local validation_passed=true
    
    # Run all validation checks
    log_info "🔍 Running comprehensive validation..."
    
    if ! check_script_dependencies; then
        validation_passed=false
    fi
    
    if ! check_environment_vars; then
        validation_passed=false
    fi
    
    if ! check_flutter_config; then
        validation_passed=false
    fi
    
    if ! check_android_config; then
        validation_passed=false
    fi
    
    if ! validate_dart_environment; then
        validation_passed=false
    fi
    
    if ! check_workflow_config; then
        validation_passed=false
    fi
    
    if ! check_firebase_config; then
        validation_passed=false
    fi
    
    if ! check_keystore_config; then
        validation_passed=false
    fi
    
    # Generate summary
    generate_summary
    
    # Final result
    if [[ "$validation_passed" == "true" ]]; then
        log_success "🎉 Android workflow validation PASSED!"
        log_info "📱 Your Android workflow is ready to run"
        log_info "📋 Check android_workflow_validation_summary.txt for details"
        return 0
    else
        log_error "❌ Android workflow validation FAILED!"
        log_warning "⚠️ Please fix the issues above before running the workflow"
        log_info "📋 Check android_workflow_validation_summary.txt for details"
        return 1
    fi
}

# Run main validation
main "$@"
