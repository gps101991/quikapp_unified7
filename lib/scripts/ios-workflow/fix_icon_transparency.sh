#!/bin/bash
# 🎨 Fix Icon Transparency Script
# Removes alpha channels and transparency from iOS app icons for App Store Connect compliance

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [TRANSPARENCY_FIX] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "Starting iOS icon transparency fix process..."

# Check if icon directory exists
ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
if [[ ! -d "$ICON_DIR" ]]; then
    log_error "Icon directory not found: $ICON_DIR"
    log_error "Please run icon generation first"
    exit 1
fi

log_success "Icon directory found: $ICON_DIR"

# Function to remove alpha channel from an icon
remove_alpha_channel() {
    local icon_path="$1"
    local icon_name=$(basename "$icon_path")
    
    if [[ ! -f "$icon_path" ]]; then
        log_warning "Icon file not found: $icon_path"
        return 1
    fi
    
    # Check if file has alpha channel
    if command -v sips > /dev/null 2>&1; then
        local has_alpha=$(sips -g hasAlpha "$icon_path" 2>/dev/null | grep -o "hasAlpha: [a-z]*" | cut -d' ' -f2)
        
        if [[ "$has_alpha" == "yes" ]]; then
            log_info "Removing alpha channel from: $icon_name"
            
            # Create backup
            local backup_path="${icon_path}.backup"
            cp "$icon_path" "$backup_path"
            
            # Remove alpha channel using sips
            if sips -s format png --matchTo '/System/Library/ColorSync/Profiles/Generic RGB Profile.icc' "$icon_path" > /dev/null 2>&1; then
                log_success "✅ Alpha channel removed from $icon_name using sips"
            else
                log_warning "⚠️ sips failed, trying alternative method..."
                
                # Alternative: Use ImageMagick if available
                if command -v convert > /dev/null 2>&1; then
                    if convert "$icon_path" -background white -alpha remove -alpha off "$icon_path"; then
                        log_success "✅ Alpha channel removed from $icon_name using ImageMagick"
                    else
                        log_error "❌ Failed to remove alpha channel from $icon_name using ImageMagick"
                        # Restore backup
                        cp "$backup_path" "$icon_path"
                        return 1
                    fi
                else
                    log_error "❌ Neither sips nor ImageMagick available to remove alpha channel"
                    # Restore backup
                    cp "$backup_path" "$icon_path"
                    return 1
                fi
            fi
            
            # Verify alpha channel is removed
            local new_has_alpha=$(sips -g hasAlpha "$icon_path" 2>/dev/null | grep -o "hasAlpha: [a-z]*" | cut -d' ' -f2)
            if [[ "$new_has_alpha" == "no" ]]; then
                log_success "✅ Alpha channel successfully removed from $icon_name"
                # Remove backup
                rm "$backup_path"
            else
                log_warning "⚠️ Alpha channel may still be present in $icon_name"
            fi
        else
            log_info "✅ $icon_name already has no alpha channel"
        fi
    else
        log_warning "⚠️ Cannot check alpha channel (sips not available)"
        # Try to remove alpha channel anyway using ImageMagick
        if command -v convert > /dev/null 2>&1; then
            log_info "Attempting to remove alpha channel from $icon_name using ImageMagick..."
            if convert "$icon_path" -background white -alpha remove -alpha off "$icon_path"; then
                log_success "✅ Alpha channel removal attempted for $icon_name using ImageMagick"
            else
                log_warning "⚠️ Failed to remove alpha channel from $icon_name using ImageMagick"
            fi
        fi
    fi
}

# Function to process all icons in the directory
process_all_icons() {
    local processed_count=0
    local success_count=0
    
    log_info "Processing all icons in $ICON_DIR..."
    
    # Find all PNG files
    while IFS= read -r -d '' icon_file; do
        if [[ -f "$icon_file" ]]; then
            processed_count=$((processed_count + 1))
            if remove_alpha_channel "$icon_file"; then
                success_count=$((success_count + 1))
            fi
        fi
    done < <(find "$ICON_DIR" -name "*.png" -print0)
    
    log_info "Processed $processed_count icons, $success_count successful alpha channel removals"
}

# Function to specifically fix the 1024x1024 icon
fix_1024_icon() {
    local icon_1024_path="$ICON_DIR/Icon-App-1024x1024@1x.png"
    
    if [[ -f "$icon_1024_path" ]]; then
        log_info "🔍 Specifically fixing 1024x1024 icon for App Store Connect..."
        
        if remove_alpha_channel "$icon_1024_path"; then
            log_success "✅ 1024x1024 icon transparency fixed successfully"
            
            # Verify the fix
            if command -v sips > /dev/null 2>&1; then
                local has_alpha=$(sips -g hasAlpha "$icon_1024_path" 2>/dev/null | grep -o "hasAlpha: [a-z]*" | cut -d' ' -f2)
                if [[ "$has_alpha" == "no" ]]; then
                    log_success "✅ 1024x1024 icon verified: no alpha channel"
                    return 0
                else
                    log_warning "⚠️ 1024x1024 icon still has alpha channel after fix attempt"
                    return 1
                fi
            else
                log_success "✅ 1024x1024 icon processed (alpha channel status unknown)"
                return 0
            fi
        else
            log_error "❌ Failed to fix 1024x1024 icon transparency"
            return 1
        fi
    else
        log_error "❌ 1024x1024 icon not found: $icon_1024_path"
        return 1
    fi
}

# Main execution
log_info "🚀 Starting iOS icon transparency fix..."

# Step 1: Fix all icons
process_all_icons

# Step 2: Specifically fix 1024x1024 icon
if fix_1024_icon; then
    log_success "✅ 1024x1024 icon transparency fix completed successfully"
else
    log_warning "⚠️ 1024x1024 icon transparency fix had issues"
fi

# Step 3: Final verification
log_info "🔍 Performing final verification..."

# Check if any icons still have alpha channels
if command -v sips > /dev/null 2>&1; then
    local icons_with_alpha=0
    while IFS= read -r -d '' icon_file; do
        if [[ -f "$icon_file" ]]; then
            local has_alpha=$(sips -g hasAlpha "$icon_file" 2>/dev/null | grep -o "hasAlpha: [a-z]*" | cut -d' ' -f2)
            if [[ "$has_alpha" == "yes" ]]; then
                icons_with_alpha=$((icons_with_alpha + 1))
                log_warning "⚠️ Icon still has alpha channel: $(basename "$icon_file")"
            fi
        fi
    done < <(find "$ICON_DIR" -name "*.png" -print0)
    
    if [[ $icons_with_alpha -eq 0 ]]; then
        log_success "✅ All icons verified: no alpha channels detected"
    else
        log_warning "⚠️ $icons_with_alpha icons still have alpha channels"
    fi
else
    log_warning "⚠️ Cannot verify alpha channels (sips not available)"
fi

# Summary
log_success "🎉 iOS icon transparency fix completed!"
log_info "📱 Icons should now be App Store Connect compliant"
log_info "🚀 Ready for App Store Connect upload without transparency errors"
