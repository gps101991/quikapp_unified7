#!/bin/bash
# 🔧 Comprehensive iOS Icon Fix Script
# Fixes alpha channel issues and ensures App Store Connect compliance

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IOS_ICON_FIX] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "🚀 Starting Comprehensive iOS Icon Fix..."

# Check if we're on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    log_error "This script must run on macOS (Xcode required)"
    exit 1
fi

# Check if sips is available
if ! command -v sips > /dev/null 2>&1; then
    log_error "sips command not available (Xcode not installed)"
    exit 1
fi

# Define iOS icon directory
IOS_ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"

if [[ ! -d "$IOS_ICON_DIR" ]]; then
    log_error "iOS icon directory not found: $IOS_ICON_DIR"
    exit 1
fi

log_info "iOS icon directory: $IOS_ICON_DIR"

# Step 1: Backup original icons
log_info "Step 1: Creating backup of original icons..."
BACKUP_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

if find "$IOS_ICON_DIR" -name "*.png" -exec cp {} "$BACKUP_DIR/" \; 2>/dev/null; then
    log_success "✅ Icons backed up to: $BACKUP_DIR"
else
    log_warning "⚠️ Could not create backup (continuing anyway)"
fi

# Step 2: Check current icon status
log_info "Step 2: Analyzing current icon status..."
TOTAL_ICONS=0
ICONS_WITH_ALPHA=0
MISSING_ICONS=()

# Check each icon for alpha channels and existence
while IFS= read -r -d '' icon_file; do
    if [[ -f "$icon_file" ]]; then
        TOTAL_ICONS=$((TOTAL_ICONS + 1))
        icon_name=$(basename "$icon_file")
        
        # Check for alpha channel
        if sips -g hasAlpha "$icon_file" 2>/dev/null | grep -q "hasAlpha: yes"; then
            ICONS_WITH_ALPHA=$((ICONS_WITH_ALPHA + 1))
            log_warning "⚠️ Icon has alpha channel: $icon_name"
        else
            log_success "✅ Icon OK: $icon_name"
        fi
    fi
done < <(find "$IOS_ICON_DIR" -name "*.png" -print0)

log_info "Total icons found: $TOTAL_ICONS"
log_info "Icons with alpha channels: $ICONS_WITH_ALPHA"

# Step 3: Fix alpha channel issues
if [[ $ICONS_WITH_ALPHA -gt 0 ]]; then
    log_info "Step 3: Fixing alpha channel issues..."
    
    # Fix each icon with alpha channel
    while IFS= read -r -d '' icon_file; do
        if [[ -f "$icon_file" ]]; then
            icon_name=$(basename "$icon_file")
            
            # Check if this icon has alpha channel
            if sips -g hasAlpha "$icon_file" 2>/dev/null | grep -q "hasAlpha: yes"; then
                log_info "Fixing alpha channel in: $icon_name"
                
                # Create a temporary file with white background
                temp_file="${icon_file}.temp"
                
                # Use sips to remove alpha channel and set white background
                if sips -s format png --matchTo '/System/Library/ColorSync/Profiles/Generic RGB Profile.icc' "$icon_file" --out "$temp_file" 2>/dev/null; then
                    # Verify the fix
                    if sips -g hasAlpha "$temp_file" 2>/dev/null | grep -q "hasAlpha: no"; then
                        # Replace original with fixed version
                        mv "$temp_file" "$icon_file"
                        log_success "✅ Fixed alpha channel: $icon_name"
                    else
                        log_warning "⚠️ Could not fix alpha channel: $icon_name"
                        rm -f "$temp_file"
                    fi
                else
                    log_warning "⚠️ Failed to process: $icon_name"
                    rm -f "$temp_file"
                fi
            fi
        fi
    done < <(find "$IOS_ICON_DIR" -name "*.png" -print0)
else
    log_success "✅ No alpha channel issues detected"
fi

# Step 4: Verify critical icons exist
log_info "Step 4: Verifying critical iOS icons..."
CRITICAL_ICONS=(
    "Icon-App-20x20@1x.png:20x20"
    "Icon-App-20x20@2x.png:40x40"
    "Icon-App-20x20@3x.png:60x60"
    "Icon-App-29x29@1x.png:29x29"
    "Icon-App-29x29@2x.png:58x58"
    "Icon-App-29x29@3x.png:87x87"
    "Icon-App-40x40@1x.png:40x40"
    "Icon-App-40x40@2x.png:80x80"
    "Icon-App-40x40@3x.png:120x120"
    "Icon-App-60x60@2x.png:120x120"
    "Icon-App-60x60@3x.png:180x180"
    "Icon-App-76x76@1x.png:76x76"
    "Icon-App-76x76@2x.png:152x152"
    "Icon-App-83.5x83.5@2x.png:167x167"
    "Icon-App-1024x1024@1x.png:1024x1024"
)

MISSING_CRITICAL=()
for icon_info in "${CRITICAL_ICONS[@]}"; do
    icon="${icon_info%%:*}"
    size="${icon_info##*:}"
    if [[ ! -f "$IOS_ICON_DIR/$icon" ]]; then
        MISSING_CRITICAL+=("$icon ($size)")
    else
        log_success "✅ $icon ($size) is present"
    fi
done

if [[ ${#MISSING_CRITICAL[@]} -gt 0 ]]; then
    log_warning "⚠️ Missing critical icons:"
    for icon in "${MISSING_CRITICAL[@]}"; do
        log_warning "  - $icon"
    done
else
    log_success "✅ All critical iOS icons are present"
fi

# Step 5: Regenerate icons if needed
if [[ ${#MISSING_CRITICAL[@]} -gt 0 ]] || [[ $ICONS_WITH_ALPHA -gt 0 ]]; then
    log_info "Step 5: Regenerating icons using Flutter Launcher Icons..."
    
    # Check if flutter_launcher_icons is available
    if flutter pub deps | grep -q "flutter_launcher_icons"; then
        if [[ -f "flutter_launcher_icons.yaml" ]]; then
            log_info "Regenerating icons..."
            if flutter pub run flutter_launcher_icons:main -f flutter_launcher_icons.yaml; then
                log_success "✅ Icons regenerated successfully"
            else
                log_warning "⚠️ Icon regeneration failed"
            fi
        else
            log_warning "⚠️ flutter_launcher_icons.yaml not found"
        fi
    else
        log_warning "⚠️ flutter_launcher_icons package not available"
    fi
fi

# Step 6: Final verification
log_info "Step 6: Final verification..."
FINAL_ICONS_WITH_ALPHA=0

while IFS= read -r -d '' icon_file; do
    if [[ -f "$icon_file" ]]; then
        icon_name=$(basename "$icon_file")
        if sips -g hasAlpha "$icon_file" 2>/dev/null | grep -q "hasAlpha: yes"; then
            FINAL_ICONS_WITH_ALPHA=$((FINAL_ICONS_WITH_ALPHA + 1))
            log_warning "⚠️ Icon still has alpha channel: $icon_name"
        fi
    fi
done < <(find "$IOS_ICON_DIR" -name "*.png" -print0)

# Step 7: Validate Contents.json
log_info "Step 7: Validating Contents.json..."
if [[ -f "$IOS_ICON_DIR/Contents.json" ]]; then
    if python3 -m json.tool "$IOS_ICON_DIR/Contents.json" > /dev/null 2>&1; then
        log_success "✅ Contents.json is valid JSON"
    else
        log_error "❌ Contents.json is invalid JSON"
    fi
else
    log_error "❌ Contents.json not found"
fi

# Step 8: Summary and recommendations
log_info "Step 8: Summary and recommendations..."

if [[ $FINAL_ICONS_WITH_ALPHA -eq 0 ]]; then
    log_success "🎉 All iOS icons are now App Store Connect compliant!"
    log_success "✅ No alpha channels detected"
    log_success "✅ Ready for App Store Connect upload"
else
    log_warning "⚠️ $FINAL_ICONS_WITH_ALPHA icons still have alpha channels"
    log_warning "⚠️ App Store Connect upload may fail"
    log_info "💡 Consider manually fixing remaining alpha channel issues"
fi

if [[ ${#MISSING_CRITICAL[@]} -eq 0 ]]; then
    log_success "✅ All critical icon sizes are present"
else
    log_warning "⚠️ Some critical icon sizes are missing"
    log_info "💡 Consider regenerating icons with flutter_launcher_icons"
fi

log_info "📋 Final icon count: $TOTAL_ICONS"
log_info "📁 Backup location: $BACKUP_DIR"
log_info "🚀 iOS icon fix process completed!"

# Exit with appropriate code
if [[ $FINAL_ICONS_WITH_ALPHA -eq 0 ]] && [[ ${#MISSING_CRITICAL[@]} -eq 0 ]]; then
    log_success "✅ All issues resolved - ready for App Store Connect!"
    exit 0
else
    log_warning "⚠️ Some issues remain - review output above"
    exit 1
fi
