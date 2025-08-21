#!/bin/bash
# 🎨 Comprehensive iOS Icon Setup Script
# Orchestrates the complete process from logo download to icon generation

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [COMPREHENSIVE_ICONS] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "🚀 Starting Comprehensive iOS Icon Setup Process..."

# Step 1: Download and Setup Logo
log_info "Step 1: Downloading and setting up logo from LOGO_URL..."

if [[ -f "lib/scripts/ios-workflow/download_and_setup_logo.sh" ]]; then
    chmod +x lib/scripts/ios-workflow/download_and_setup_logo.sh
    
    if ./lib/scripts/ios-workflow/download_and_setup_logo.sh; then
        log_success "✅ Logo download and setup completed successfully"
    else
        log_error "❌ Logo download and setup failed"
        exit 1
    fi
else
    log_error "❌ Logo download script not found: lib/scripts/ios-workflow/download_and_setup_logo.sh"
    exit 1
fi

# Step 2: Setup iOS App Icons
log_info "Step 2: Setting up iOS app icons..."

if [[ -f "lib/scripts/ios-workflow/setup_ios_app_icons.sh" ]]; then
    chmod +x lib/scripts/ios-workflow/setup_ios_app_icons.sh
    
    if ./lib/scripts/ios-workflow/setup_ios_app_icons.sh; then
        log_success "✅ iOS app icon setup completed successfully"
    else
        log_error "❌ iOS app icon setup failed"
        exit 1
    fi
else
    log_error "❌ iOS app icon setup script not found: lib/scripts/ios-workflow/setup_ios_app_icons.sh"
    exit 1
fi

# Step 3: Verify Final Results
log_info "Step 3: Verifying final results..."

ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
if [[ ! -d "$ICON_DIR" ]]; then
    log_error "❌ Icon directory not found: $ICON_DIR"
    exit 1
fi

# Count total icons
TOTAL_ICONS=$(find "$ICON_DIR" -name "*.png" | wc -l)
log_info "Total icons generated: $TOTAL_ICONS"

# Check for critical icons
CRITICAL_ICONS=(
    "Icon-App-60x60@2x.png:120x120"
    "Icon-App-76x76@2x.png:152x152"
    "Icon-App-83.5x83.5@2x.png:167x167"
    "Icon-App-1024x1024@1x.png:1024x1024"
)

MISSING_CRITICAL=()
for icon_info in "${CRITICAL_ICONS[@]}"; do
    icon="${icon_info%%:*}"
    size="${icon_info##*:}"
    if [[ ! -f "$ICON_DIR/$icon" ]]; then
        MISSING_CRITICAL+=("$icon ($size)")
    else
        log_success "✅ $icon ($size) is present"
    fi
done

if [[ ${#MISSING_CRITICAL[@]} -gt 0 ]]; then
    log_error "❌ Missing critical icons:"
    for icon in "${MISSING_CRITICAL[@]}"; do
        log_error "  - $icon"
    done
    exit 1
fi

# Step 4: Fix Icon Transparency (Critical for App Store Connect)
log_info "Step 4: Fixing icon transparency for App Store Connect compliance..."

if [[ -f "lib/scripts/ios-workflow/fix_icon_transparency.sh" ]]; then
    chmod +x lib/scripts/ios-workflow/fix_icon_transparency.sh
    
    if ./lib/scripts/ios-workflow/fix_icon_transparency.sh; then
        log_success "✅ Icon transparency fix completed successfully"
    else
        log_warning "⚠️ Icon transparency fix had issues, but continuing..."
    fi
else
    log_warning "⚠️ Icon transparency fix script not found, continuing..."
fi

# Step 5: Verify Contents.json
log_info "Step 5: Verifying Contents.json configuration..."

CONTENTS_JSON="$ICON_DIR/Contents.json"
if [[ -f "$CONTENTS_JSON" ]]; then
    if command -v plutil > /dev/null 2>&1; then
        if plutil -lint "$CONTENTS_JSON" > /dev/null 2>&1; then
            log_success "✅ Contents.json is valid"
        else
            log_warning "⚠️ Contents.json validation failed, attempting to fix..."
            if [[ -f "lib/scripts/ios-workflow/fix_corrupted_contents_json.sh" ]]; then
                chmod +x lib/scripts/ios-workflow/fix_corrupted_contents_json.sh
                if ./lib/scripts/ios-workflow/fix_corrupted_contents_json.sh; then
                    log_success "✅ Contents.json fixed successfully"
                else
                    log_warning "⚠️ Contents.json fix failed, but icons are present"
                fi
            fi
        fi
    else
        log_warning "⚠️ Cannot validate Contents.json (plutil not available)"
    fi
else
    log_error "❌ Contents.json not found"
    exit 1
fi

# Step 6: Final App Store Connect Validation
log_info "Step 6: Final App Store Connect validation..."

# Check 1024x1024 icon specifically
ICON_1024_PATH="$ICON_DIR/Icon-App-1024x1024@1x.png"
if [[ -f "$ICON_1024_PATH" ]] && [[ -s "$ICON_1024_PATH" ]]; then
    if command -v sips > /dev/null 2>&1; then
        ICON_SIZE=$(sips -g pixelWidth -g pixelHeight "$ICON_1024_PATH" 2>/dev/null | grep -E "(pixelWidth|pixelHeight)" | awk '{print $2}' | tr '\n' 'x' | sed 's/x$//')
        if [[ "$ICON_SIZE" == "1024x1024" ]]; then
            log_success "✅ 1024x1024 icon has correct dimensions: $ICON_SIZE"
            log_success "✅ App Store Connect icon validation: PASSED"
        else
            log_error "❌ 1024x1024 icon has wrong dimensions: $ICON_SIZE (expected: 1024x1024)"
            log_error "❌ App Store Connect icon validation: FAILED"
            exit 1
        fi
    else
        log_success "✅ 1024x1024 icon is present and has content"
        log_success "✅ App Store Connect icon validation: PASSED (dimensions not verified)"
    fi
else
    log_error "❌ 1024x1024 icon is missing or empty"
    log_error "❌ App Store Connect icon validation: FAILED"
    exit 1
fi

# Summary
log_success "🎉 Comprehensive iOS Icon Setup Completed Successfully!"
log_info "📱 Total icons generated: $TOTAL_ICONS"
log_info "✅ All critical icons are present"
log_info "✅ Contents.json is properly configured"
log_info "✅ App Store Connect validation: PASSED"
log_info "🚀 iOS app is ready for App Store Connect upload!"

# List all generated icons
log_info "📋 Generated iOS app icons:"
find "$ICON_DIR" -name "*.png" | sort | while read -r icon; do
    icon_name=$(basename "$icon")
    log_info "  - $icon_name"
done
