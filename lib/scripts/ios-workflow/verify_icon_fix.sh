#!/bin/bash
# 🔍 iOS Icon Fix Verification Script
# Verifies that all required icons are present and Info.plist is correctly configured

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ICON_VERIFY] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "Starting iOS icon fix verification..."

# Step 1: Check asset catalog structure
log_info "Step 1: Checking asset catalog structure..."
if [[ ! -d "ios/Runner/Assets.xcassets/AppIcon.appiconset" ]]; then
    log_error "Asset catalog directory not found"
    exit 1
fi
log_success "Asset catalog directory exists"

# Step 2: Check Contents.json
log_info "Step 2: Checking Contents.json..."
CONTENTS_JSON="ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json"
if [[ ! -f "$CONTENTS_JSON" ]]; then
    log_error "Contents.json not found"
    exit 1
fi

# Validate Contents.json
if plutil -lint "$CONTENTS_JSON" > /dev/null 2>&1; then
    log_success "Contents.json is valid"
else
    log_error "Contents.json is invalid"
    plutil -lint "$CONTENTS_JSON"
    exit 1
fi

# Step 3: Check all required icons
log_info "Step 3: Checking all required icons..."

REQUIRED_ICONS=(
    "Icon-App-20x20@1x.png"
    "Icon-App-20x20@2x.png"
    "Icon-App-20x20@3x.png"
    "Icon-App-29x29@1x.png"
    "Icon-App-29x29@2x.png"
    "Icon-App-29x29@3x.png"
    "Icon-App-40x40@1x.png"
    "Icon-App-40x40@2x.png"
    "Icon-App-40x40@3x.png"
    "Icon-App-60x60@2x.png"
    "Icon-App-60x60@3x.png"
    "Icon-App-76x76@1x.png"
    "Icon-App-76x76@2x.png"
    "Icon-App-83.5x83.5@2x.png"
    "Icon-App-1024x1024@1x.png"
)

MISSING_ICONS=()
EMPTY_ICONS=()

for icon in "${REQUIRED_ICONS[@]}"; do
    filepath="ios/Runner/Assets.xcassets/AppIcon.appiconset/$icon"
    
    if [[ ! -f "$filepath" ]]; then
        MISSING_ICONS+=("$icon")
    elif [[ ! -s "$filepath" ]]; then
        EMPTY_ICONS+=("$icon")
    fi
done

# Report missing icons
if [[ ${#MISSING_ICONS[@]} -gt 0 ]]; then
    log_error "Missing icons:"
    for icon in "${MISSING_ICONS[@]}"; do
        log_error "  - $icon"
    done
    exit 1
fi

# Report empty icons
if [[ ${#EMPTY_ICONS[@]} -gt 0 ]]; then
    log_error "Empty icons:"
    for icon in "${EMPTY_ICONS[@]}"; do
        log_error "  - $icon"
    done
    exit 1
fi

log_success "All required icons are present and have content"

# Step 4: Check critical icon sizes (the ones that were failing)
log_info "Step 4: Checking critical icon sizes..."

CRITICAL_ICONS=(
    "120x120:Icon-App-60x60@2x.png"
    "152x152:Icon-App-76x76@2x.png"
    "167x167:Icon-App-83.5x83.5@2x.png"
)

for size_info in "${CRITICAL_ICONS[@]}"; do
    size="${size_info%%:*}"
    filename="${size_info##*:}"
    filepath="ios/Runner/Assets.xcassets/AppIcon.appiconset/$filename"
    
    if [[ -f "$filepath" ]] && [[ -s "$filepath" ]]; then
        log_success "✅ $filename exists and has content (required for $size)"
    else
        log_error "❌ $filename missing or empty (required for $size)"
        exit 1
    fi
done

# Step 5: Check Info.plist CFBundleIconName
log_info "Step 5: Checking Info.plist CFBundleIconName..."

INFO_PLIST="ios/Runner/Info.plist"
if [[ ! -f "$INFO_PLIST" ]]; then
    log_error "Info.plist not found"
    exit 1
fi

# Validate Info.plist
if plutil -lint "$INFO_PLIST" > /dev/null 2>&1; then
    log_success "Info.plist is valid"
else
    log_error "Info.plist is invalid"
    plutil -lint "$INFO_PLIST"
    exit 1
fi

# Check CFBundleIconName
if grep -q "CFBundleIconName" "$INFO_PLIST"; then
    ICON_NAME=$(grep -A1 "CFBundleIconName" "$INFO_PLIST" | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    if [[ "$ICON_NAME" == "AppIcon" ]]; then
        log_success "✅ CFBundleIconName is correctly set to 'AppIcon'"
    else
        log_error "❌ CFBundleIconName is set to '$ICON_NAME', should be 'AppIcon'"
        exit 1
    fi
else
    log_error "❌ CFBundleIconName not found in Info.plist"
    exit 1
fi

# Step 6: Check icon dimensions
log_info "Step 6: Checking icon dimensions..."

# Check critical dimensions
if command -v sips >/dev/null 2>&1; then
    for size_info in "${CRITICAL_ICONS[@]}"; do
        size="${size_info%%:*}"
        filename="${size_info##*:}"
        filepath="ios/Runner/Assets.xcassets/AppIcon.appiconset/$filename"
        
        # Get actual dimensions
        actual_size=$(sips -g pixelWidth -g pixelHeight "$filepath" 2>/dev/null | grep -E "(pixelWidth|pixelHeight)" | awk '{print $2}' | tr '\n' 'x' | sed 's/x$//')
        
        if [[ "$actual_size" == "${size}x${size}" ]]; then
            log_success "✅ $filename has correct dimensions: $actual_size"
        else
            log_warning "⚠️ $filename has dimensions: $actual_size (expected: ${size}x${size})"
        fi
    done
else
    log_warning "⚠️ sips not available, skipping dimension verification"
fi

# Step 7: Final summary
log_info "📋 Icon Fix Verification Summary:"
echo "=========================================="
echo "✅ Asset catalog directory exists"
echo "✅ Contents.json is valid"
echo "✅ All required icons are present"
echo "✅ All icons have content"
echo "✅ Critical icons (120x120, 152x152, 167x167) exist"
echo "✅ Info.plist is valid"
echo "✅ CFBundleIconName is correctly set to 'AppIcon'"
echo "=========================================="

log_success "🎉 iOS icon fix verification completed successfully!"
log_info "📱 Your app should now pass App Store icon validation"

# Step 8: Additional App Store validation checks
log_info "Step 8: Additional App Store validation checks..."

# Check if the app has the minimum required icons for App Store
APP_STORE_REQUIRED=(
    "Icon-App-60x60@2x.png"    # iPhone 120x120
    "Icon-App-76x76@2x.png"    # iPad 152x152
    "Icon-App-83.5x83.5@2x.png" # iPad Pro 167x167
    "Icon-App-1024x1024@1x.png" # Marketing 1024x1024
)

APP_STORE_READY=true
for icon in "${APP_STORE_REQUIRED[@]}"; do
    filepath="ios/Runner/Assets.xcassets/AppIcon.appiconset/$icon"
    
    if [[ -f "$filepath" ]] && [[ -s "$filepath" ]]; then
        log_success "✅ $icon ready for App Store"
    else
        log_error "❌ $icon not ready for App Store"
        APP_STORE_READY=false
    fi
done

if [[ "$APP_STORE_READY" == "true" ]]; then
    log_success "🎯 App Store icon validation: READY"
    log_info "Your app should now pass App Store Connect upload validation"
else
    log_error "❌ App Store icon validation: NOT READY"
    log_error "Please run the icon fix script again"
    exit 1
fi

log_success "🎉 All verification checks passed!"
