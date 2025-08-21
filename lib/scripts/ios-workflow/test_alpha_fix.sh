#!/bin/bash
# 🧪 Test Script for iOS Icon Alpha Channel Fix
# Tests the fix_alpha_channels.sh script functionality

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [TEST_ALPHA] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "🧪 Starting iOS Icon Alpha Channel Fix Test..."

# Check if we're on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    log_error "This test must run on macOS (Xcode required)"
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

# Step 1: Check current alpha channel status
log_info "Step 1: Checking current alpha channel status..."
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

# Step 2: Test the fix_alpha_channels.sh script
log_info "Step 2: Testing the fix_alpha_channels.sh script..."

if [[ -f "lib/scripts/ios-workflow/fix_alpha_channels.sh" ]]; then
    chmod +x lib/scripts/ios-workflow/fix_alpha_channels.sh
    
    # Run the fix script
    if ./lib/scripts/ios-workflow/fix_alpha_channels.sh; then
        log_success "✅ Alpha channel fix script completed successfully"
    else
        log_warning "⚠️ Alpha channel fix script had issues"
    fi
else
    log_error "❌ fix_alpha_channels.sh script not found"
    exit 1
fi

# Step 3: Verify the fix worked
log_info "Step 3: Verifying the fix worked..."
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

# Step 4: Test results
log_info "Step 4: Test results..."

log_info "📊 Alpha Channel Fix Test Results:"
log_info "  - Initial icons with alpha: ${#ICONS_WITH_ALPHA[@]}"
log_info "  - Final icons with alpha: $FINAL_ICONS_WITH_ALPHA"
log_info "  - Icons fixed: $((${#ICONS_WITH_ALPHA[@]} - FINAL_ICONS_WITH_ALPHA))"

if [[ $FINAL_ICONS_WITH_ALPHA -eq 0 ]]; then
    log_success "🎉 Test PASSED: All alpha channel issues resolved!"
    log_success "✅ Your icons are now App Store Connect compliant"
    log_success "✅ Ready for successful App Store Connect upload"
    exit 0
else
    log_warning "⚠️ Test PARTIALLY PASSED: Some alpha channel issues remain"
    log_warning "⚠️ $FINAL_ICONS_WITH_ALPHA icons still have alpha channels"
    
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
    
    exit 1
fi
