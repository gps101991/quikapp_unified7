#!/bin/bash
# 🔧 iOS Icon Alpha Channel Fix Script
# Specifically fixes the "Invalid large app icon" error for App Store Connect

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ALPHA_FIX] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "🚀 Starting iOS Icon Alpha Channel Fix..."

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

# Step 1: Create backup
log_info "Step 1: Creating backup of current icons..."
BACKUP_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset/backup_alpha_fix_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

if find "$IOS_ICON_DIR" -name "*.png" -exec cp {} "$BACKUP_DIR/" \; 2>/dev/null; then
    log_success "✅ Icons backed up to: $BACKUP_DIR"
else
    log_warning "⚠️ Could not create backup (continuing anyway)"
fi

# Step 2: Check current alpha channel status
log_info "Step 2: Checking current alpha channel status..."
ICONS_WITH_ALPHA=()
ICONS_WITHOUT_ALPHA=()

while IFS= read -r -d '' icon_file; do
    if [[ -f "$icon_file" ]]; then
        icon_name=$(basename "$icon_file")
        
        # Check for alpha channel
        if sips -g hasAlpha "$icon_file" 2>/dev/null | grep -q "hasAlpha: yes"; then
            ICONS_WITH_ALPHA+=("$icon_name")
            log_warning "⚠️ Icon has alpha channel: $icon_name"
        else
            ICONS_WITHOUT_ALPHA+=("$icon_name")
            log_success "✅ Icon OK: $icon_name"
        fi
    fi
done < <(find "$IOS_ICON_DIR" -name "*.png" -print0)

log_info "Icons with alpha channels: ${#ICONS_WITH_ALPHA[@]}"
log_info "Icons without alpha channels: ${#ICONS_WITHOUT_ALPHA[@]}"

if [[ ${#ICONS_WITH_ALPHA[@]} -eq 0 ]]; then
    log_success "🎉 No alpha channel issues detected!"
    log_success "✅ Your icons are already App Store Connect compliant"
    exit 0
fi

# Step 3: Fix alpha channel issues
log_info "Step 3: Fixing alpha channel issues..."

FIXED_COUNT=0
FAILED_COUNT=0

for icon_name in "${ICONS_WITH_ALPHA[@]}"; do
    icon_file="$IOS_ICON_DIR/$icon_name"
    
    if [[ -f "$icon_file" ]]; then
        log_info "Fixing alpha channel in: $icon_name"
        
        # Create temporary file
        temp_file="${icon_file}.temp"
        
        # Method 1: Try to remove alpha channel using sips
        if sips -s format png --matchTo '/System/Library/ColorSync/Profiles/Generic RGB Profile.icc' "$icon_file" --out "$temp_file" 2>/dev/null; then
            # Verify the fix
            if sips -g hasAlpha "$temp_file" 2>/dev/null | grep -q "hasAlpha: no"; then
                # Replace original with fixed version
                mv "$temp_file" "$icon_file"
                log_success "✅ Fixed alpha channel: $icon_name"
                FIXED_COUNT=$((FIXED_COUNT + 1))
            else
                log_warning "⚠️ Method 1 failed for: $icon_name"
                rm -f "$temp_file"
                
                # Method 2: Try alternative approach
                if sips -s format png -s formatOptions best "$icon_file" --out "$temp_file" 2>/dev/null; then
                    if sips -g hasAlpha "$temp_file" 2>/dev/null | grep -q "hasAlpha: no"; then
                        mv "$temp_file" "$icon_file"
                        log_success "✅ Fixed alpha channel (Method 2): $icon_name"
                        FIXED_COUNT=$((FIXED_COUNT + 1))
                    else
                        log_warning "⚠️ Method 2 failed for: $icon_name"
                        rm -f "$temp_file"
                        FAILED_COUNT=$((FAILED_COUNT + 1))
                    fi
                else
                    log_warning "⚠️ Method 2 failed for: $icon_name"
                    rm -f "$temp_file"
                    FAILED_COUNT=$((FAILED_COUNT + 1))
                fi
            fi
        else
            log_warning "⚠️ Method 1 failed for: $icon_name"
            rm -f "$temp_file"
            FAILED_COUNT=$((FAILED_COUNT + 1))
        fi
    fi
done

# Step 4: Final verification
log_info "Step 4: Final verification..."
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

# Step 5: Summary and recommendations
log_info "Step 5: Summary and recommendations..."

log_info "📊 Fix Results:"
log_info "  - Icons processed: ${#ICONS_WITH_ALPHA[@]}"
log_info "  - Successfully fixed: $FIXED_COUNT"
log_info "  - Failed to fix: $FAILED_COUNT"
log_info "  - Remaining alpha channels: $FINAL_ICONS_WITH_ALPHA"

if [[ $FINAL_ICONS_WITH_ALPHA -eq 0 ]]; then
    log_success "🎉 All alpha channel issues resolved!"
    log_success "✅ Your icons are now App Store Connect compliant"
    log_success "✅ Ready for successful App Store Connect upload"
    
    # Clean up backup if everything is fixed
    if [[ -d "$BACKUP_DIR" ]] && [[ $FIXED_COUNT -gt 0 ]]; then
        log_info "Cleaning up backup directory..."
        rm -rf "$BACKUP_DIR"
        log_success "✅ Backup cleaned up"
    fi
    
    exit 0
else
    log_warning "⚠️ $FINAL_ICONS_WITH_ALPHA icons still have alpha channels"
    log_warning "⚠️ App Store Connect upload may still fail"
    
    # List remaining problematic icons
    log_info "Remaining icons with alpha channels:"
    while IFS= read -r -d '' icon_file; do
        if [[ -f "$icon_file" ]]; then
            icon_name=$(basename "$icon_file")
            if sips -g hasAlpha "$icon_file" 2>/dev/null | grep -q "hasAlpha: yes"; then
                log_warning "  - $icon_name"
            fi
        fi
    done < <(find "$IOS_ICON_DIR" -name "*.png" -print0)
    
    log_info "💡 Recommendations:"
    log_info "  1. Check if the source logo has transparency"
    log_info "  2. Regenerate icons using flutter_launcher_icons with ios_remove_alpha: true"
    log_info "  3. Use image editing software to remove transparency from source"
    log_info "  4. Backup location: $BACKUP_DIR"
    
    exit 1
fi
