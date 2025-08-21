#!/bin/bash
# 🍎 iOS Workflow Icon Integration Script
# Integrates icon fixes into the main iOS workflow

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ICON_INTEGRATION] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "Starting iOS workflow icon integration..."

# Step 1: Run comprehensive icon fix
log_info "Step 1: Running comprehensive icon fix..."

if [ -f "lib/scripts/ios-workflow/fix_ios_icons_comprehensive.sh" ]; then
    chmod +x lib/scripts/ios-workflow/fix_ios_icons_comprehensive.sh
    if ./lib/scripts/ios-workflow/fix_ios_icons_comprehensive.sh; then
        log_success "Comprehensive icon fix completed successfully"
    else
        log_error "Comprehensive icon fix failed"
        exit 1
    fi
else
    log_error "Comprehensive icon fix script not found"
    exit 1
fi

# Step 2: Run icon verification
log_info "Step 2: Running icon verification..."

if [ -f "lib/scripts/ios-workflow/verify_icon_fix.sh" ]; then
    chmod +x lib/scripts/ios-workflow/verify_icon_fix.sh
    if ./lib/scripts/ios-workflow/verify_icon_fix.sh; then
        log_success "Icon verification completed successfully"
    else
        log_error "Icon verification failed"
        exit 1
    fi
else
    log_warning "Icon verification script not found, running basic checks..."
    
    # Basic verification as fallback
    # Check if all critical icons exist
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
        fi
    done

    if [[ ${#MISSING_CRITICAL[@]} -gt 0 ]]; then
        log_error "Critical icons still missing:"
        for icon in "${MISSING_CRITICAL[@]}"; do
            log_error "  - $icon"
        done
        exit 1
    else
        log_success "All critical icons are present"
    fi
fi

# Step 3: Verify Contents.json
log_info "Step 3: Verifying Contents.json..."

if [ -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json" ]; then
    if plutil -lint "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json" > /dev/null 2>&1; then
        log_success "Contents.json is valid"
    else
        log_error "Contents.json is invalid"
        plutil -lint "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json"
        exit 1
    fi
else
    log_error "Contents.json not found"
    exit 1
fi

# Step 4: Verify Info.plist configuration
log_info "Step 4: Verifying Info.plist configuration..."

if [ -f "ios/Runner/Info.plist" ]; then
    # Check for CFBundleIconName
    if grep -q "CFBundleIconName" ios/Runner/Info.plist; then
        log_success "CFBundleIconName is present in Info.plist"
    else
        log_error "CFBundleIconName is missing from Info.plist"
        exit 1
    fi
    
    # Validate Info.plist syntax
    if plutil -lint ios/Runner/Info.plist > /dev/null 2>&1; then
        log_success "Info.plist syntax is valid"
    else
        log_error "Info.plist syntax is invalid"
        plutil -lint ios/Runner/Info.plist
        exit 1
    fi
else
    log_error "Info.plist not found"
    exit 1
fi

# Step 5: Verify asset catalog structure
log_info "Step 5: Verifying asset catalog structure..."

ASSET_CATALOG="ios/Runner/Assets.xcassets/AppIcon.appiconset"
if [ -d "$ASSET_CATALOG" ]; then
    log_success "Asset catalog directory exists"
    
    # Count icon files
    ICON_COUNT=$(find "$ASSET_CATALOG" -name "*.png" | wc -l)
    log_info "Found $ICON_COUNT icon files in asset catalog"
    
    if [ "$ICON_COUNT" -ge 15 ]; then
        log_success "Sufficient number of icons present"
    else
        log_warning "Icon count seems low ($ICON_COUNT), expected at least 15"
    fi
else
    log_error "Asset catalog directory not found: $ASSET_CATALOG"
    exit 1
fi

# Step 6: Final validation summary
log_info "Step 6: Final validation summary..."

echo "=========================================="
echo "🔍 iOS Icon Configuration Validation"
echo "=========================================="
echo "✅ Critical icons (120x120, 152x152, 167x167): PRESENT"
echo "✅ Contents.json: VALID"
echo "✅ Info.plist CFBundleIconName: PRESENT"
echo "✅ Info.plist syntax: VALID"
echo "✅ Asset catalog structure: VALID"
echo "✅ Icon count: $ICON_COUNT files"
echo "=========================================="

# Step 7: Check for potential issues
log_info "Step 7: Checking for potential issues..."

# Check if icons have reasonable file sizes (not 0 bytes)
ZERO_BYTE_ICONS=()
for icon in "$ASSET_CATALOG"/*.png; do
    if [ -f "$icon" ] && [ ! -s "$icon" ]; then
        ZERO_BYTE_ICONS+=("$(basename "$icon")")
    fi
done

if [[ ${#ZERO_BYTE_ICONS[@]} -gt 0 ]]; then
    log_warning "Found zero-byte icons:"
    for icon in "${ZERO_BYTE_ICONS[@]}"; do
        log_warning "  - $icon"
    done
    log_warning "These may cause validation issues"
else
    log_success "All icons have valid file sizes"
fi

# Check if icons are actually PNG files
INVALID_PNG_ICONS=()
for icon in "$ASSET_CATALOG"/*.png; do
    if [ -f "$icon" ]; then
        if ! file "$icon" | grep -q "PNG image data"; then
            INVALID_PNG_ICONS+=("$(basename "$icon")")
        fi
    fi
done

if [[ ${#INVALID_PNG_ICONS[@]} -gt 0 ]]; then
    log_warning "Found non-PNG icons:"
    for icon in "${INVALID_PNG_ICONS[@]}"; do
        log_warning "  - $icon"
    done
    log_warning "These may cause validation issues"
else
    log_success "All icons are valid PNG files"
fi

# Final success message
log_success "🎉 iOS workflow icon integration completed successfully!"
log_info "📱 Your app should now pass App Store icon validation"
log_info "🚀 Ready to proceed with iOS build and upload"

echo ""
echo "📋 Next steps:"
echo "1. Run iOS build workflow"
echo "2. Verify icons are properly included in IPA"
echo "3. Upload to App Store Connect"
echo "4. Validate that icon errors are resolved"
