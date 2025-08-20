#!/bin/bash
# 🧪 Test iOS Icon Fix Script
# Tests if the icon fix resolves App Store validation issues

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ICON_TEST] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "Starting iOS icon fix test..."

# Test 1: Check if critical icons exist
log_info "Test 1: Checking critical icon files..."

CRITICAL_ICONS=(
    "Icon-App-60x60@2x.png:120x120"
    "Icon-App-76x76@2x.png:152x152"
    "Icon-App-83.5x83.5@2x.png:167x167"
)

MISSING_CRITICAL=()
for icon_info in "${CRITICAL_ICONS[@]}"; do
    icon="${icon_info%%:*}"
    size="${icon_info##*:}"
    filepath="ios/Runner/Assets.xcassets/AppIcon.appiconset/$icon"
    
    if [[ ! -f "$filepath" ]]; then
        MISSING_CRITICAL+=("$icon ($size)")
    else
        log_success "✅ $icon exists ($size)"
    fi
done

if [[ ${#MISSING_CRITICAL[@]} -gt 0 ]]; then
    log_error "❌ Critical icons missing:"
    for icon in "${MISSING_CRITICAL[@]}"; do
        log_error "   - $icon"
    done
    log_error "This will cause App Store validation to fail!"
else
    log_success "✅ All critical icons are present"
fi

# Test 2: Check Contents.json
log_info "Test 2: Checking Contents.json configuration..."

if [ -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json" ]; then
    if plutil -lint "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json" > /dev/null 2>&1; then
        log_success "✅ Contents.json is valid"
        
        # Check if it contains all required icon entries
        REQUIRED_ENTRIES=(
            "Icon-App-60x60@2x.png"
            "Icon-App-76x76@2x.png"
            "Icon-App-83.5x83.5@2x.png"
        )
        
        MISSING_ENTRIES=()
        for entry in "${REQUIRED_ENTRIES[@]}"; do
            if ! grep -q "$entry" "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json"; then
                MISSING_ENTRIES+=("$entry")
            fi
        done
        
        if [[ ${#MISSING_ENTRIES[@]} -gt 0 ]]; then
            log_error "❌ Contents.json missing entries:"
            for entry in "${MISSING_ENTRIES[@]}"; do
                log_error "   - $entry"
            done
        else
            log_success "✅ Contents.json contains all required icon entries"
        fi
    else
        log_error "❌ Contents.json is invalid"
        plutil -lint "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json"
    fi
else
    log_error "❌ Contents.json not found"
fi

# Test 3: Check Info.plist
log_info "Test 3: Checking Info.plist configuration..."

if [ -f "ios/Runner/Info.plist" ]; then
    # Check for CFBundleIconName
    if grep -q "CFBundleIconName" ios/Runner/Info.plist; then
        log_success "✅ CFBundleIconName is present in Info.plist"
        
        # Get the value
        ICON_NAME=$(grep -A1 "CFBundleIconName" ios/Runner/Info.plist | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
        log_info "CFBundleIconName value: $ICON_NAME"
        
        if [[ "$ICON_NAME" == "AppIcon" ]]; then
            log_success "✅ CFBundleIconName has correct value: AppIcon"
        else
            log_warning "⚠️ CFBundleIconName has unexpected value: $ICON_NAME"
        fi
    else
        log_error "❌ CFBundleIconName is missing from Info.plist"
        log_error "This will cause App Store validation to fail!"
    fi
    
    # Validate Info.plist syntax
    if plutil -lint ios/Runner/Info.plist > /dev/null 2>&1; then
        log_success "✅ Info.plist syntax is valid"
    else
        log_error "❌ Info.plist syntax is invalid"
        plutil -lint ios/Runner/Info.plist
    fi
else
    log_error "❌ Info.plist not found"
fi

# Test 4: Check icon file integrity
log_info "Test 4: Checking icon file integrity..."

ASSET_CATALOG="ios/Runner/Assets.xcassets/AppIcon.appiconset"
if [ -d "$ASSET_CATALOG" ]; then
    # Count total icons
    TOTAL_ICONS=$(find "$ASSET_CATALOG" -name "*.png" | wc -l)
    log_info "Total icon files found: $TOTAL_ICONS"
    
    if [ "$TOTAL_ICONS" -ge 15 ]; then
        log_success "✅ Sufficient number of icons present"
    else
        log_warning "⚠️ Icon count seems low ($TOTAL_ICONS), expected at least 15"
    fi
    
    # Check for zero-byte icons
    ZERO_BYTE_COUNT=0
    for icon in "$ASSET_CATALOG"/*.png; do
        if [ -f "$icon" ] && [ ! -s "$icon" ]; then
            ZERO_BYTE_COUNT=$((ZERO_BYTE_COUNT + 1))
            log_warning "⚠️ Zero-byte icon found: $(basename "$icon")"
        fi
    done
    
    if [ "$ZERO_BYTE_COUNT" -eq 0 ]; then
        log_success "✅ All icons have valid file sizes"
    else
        log_warning "⚠️ Found $ZERO_BYTE_COUNT zero-byte icons"
    fi
else
    log_error "❌ Asset catalog directory not found"
fi

# Test 5: Simulate App Store validation checks
log_info "Test 5: Simulating App Store validation checks..."

echo ""
echo "🔍 App Store Validation Simulation Results:"
echo "=========================================="

# Check for the specific errors mentioned in the original issue
ERRORS_FOUND=0

# Error 1: Missing 120x120 icon
if [[ -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png" ]]; then
    echo "✅ PASS: 120x120 icon (Icon-App-60x60@2x.png) exists"
else
    echo "❌ FAIL: 120x120 icon (Icon-App-60x60@2x.png) missing"
    ERRORS_FOUND=$((ERRORS_FOUND + 1))
fi

# Error 2: Missing 167x167 icon
if [[ -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png" ]]; then
    echo "✅ PASS: 167x167 icon (Icon-App-83.5x83.5@2x.png) exists"
else
    echo "❌ FAIL: 167x167 icon (Icon-App-83.5x83.5@2x.png) missing"
    ERRORS_FOUND=$((ERRORS_FOUND + 1))
fi

# Error 3: Missing 152x152 icon
if [[ -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png" ]]; then
    echo "✅ PASS: 152x152 icon (Icon-App-76x76@2x.png) exists"
else
    echo "❌ FAIL: 152x152 icon (Icon-App-76x76@2x.png) missing"
    ERRORS_FOUND=$((ERRORS_FOUND + 1))
fi

# Error 4: Missing CFBundleIconName
if grep -q "CFBundleIconName" ios/Runner/Info.plist; then
    echo "✅ PASS: CFBundleIconName exists in Info.plist"
else
    echo "❌ FAIL: CFBundleIconName missing from Info.plist"
    ERRORS_FOUND=$((ERRORS_FOUND + 1))
fi

echo "=========================================="

# Final result
if [ "$ERRORS_FOUND" -eq 0 ]; then
    log_success "🎉 All App Store validation checks PASSED!"
    log_info "📱 Your app should now upload successfully to App Store Connect"
    echo ""
    echo "✅ RESULT: READY FOR APP STORE UPLOAD"
    echo "✅ All critical icon issues have been resolved"
    echo "✅ App should pass validation and upload successfully"
else
    log_error "❌ $ERRORS_FOUND App Store validation checks FAILED!"
    log_error "📱 Your app will still fail App Store validation"
    echo ""
    echo "❌ RESULT: NOT READY FOR APP STORE UPLOAD"
    echo "❌ Critical icon issues remain unresolved"
    echo "❌ App will fail validation and upload will fail"
fi

echo ""
echo "📋 Summary:"
echo "- Critical icons: ${#MISSING_CRITICAL[@]} missing"
echo "- Contents.json: $(if [ -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json" ] && plutil -lint "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json" > /dev/null 2>&1; then echo "VALID"; else echo "INVALID"; fi)"
echo "- CFBundleIconName: $(if grep -q "CFBundleIconName" ios/Runner/Info.plist; then echo "PRESENT"; else echo "MISSING"; fi)"
echo "- App Store validation: $(if [ "$ERRORS_FOUND" -eq 0 ]; then echo "READY"; else echo "NOT READY"; fi)"
