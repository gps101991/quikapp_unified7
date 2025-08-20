#!/bin/bash
set -euo pipefail

# 🚀 iOS App Icon Fix Script for Codemagic
# Fixes transparency and alpha channel issues in app icons

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ICON_FIX] $1"; }
log_info() { log "ℹ️ $1"; }
log_success() { log "✅ $1"; }
log_warning() { log "⚠️ $1"; }
log_error() { log "❌ $1"; }

# Configuration
ICONS_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
REQUIRED_ICONS=(
    "Icon-App-1024x1024@1x.png"
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
)

# Check if ImageMagick is available
check_imagemagick() {
    if ! command -v convert &> /dev/null; then
        log_warning "ImageMagick not found, installing..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command -v brew &> /dev/null; then
                brew install imagemagick
            else
                log_error "Homebrew not found. Please install ImageMagick manually:"
                log_error "brew install imagemagick"
                return 1
            fi
        else
            # Linux
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y imagemagick
            elif command -v yum &> /dev/null; then
                sudo yum install -y ImageMagick
            else
                log_error "Package manager not found. Please install ImageMagick manually."
                return 1
            fi
        fi
    fi
    
    log_success "ImageMagick available: $(convert --version | head -n1)"
    return 0
}

# Fix individual icon
fix_icon() {
    local icon_path="$1"
    local temp_path="${icon_path}.temp"
    
    if [[ ! -f "$icon_path" ]]; then
        log_warning "Icon not found: $icon_path"
        return 1
    fi
    
    log_info "Fixing icon: $icon_path"
    
    # Get original dimensions
    local original_size=$(identify -format "%wx%h" "$icon_path" 2>/dev/null || echo "unknown")
    log_info "  Original size: $original_size"
    
    # Remove transparency and alpha channel, ensure opaque background
    if convert "$icon_path" \
        -background white \
        -alpha remove \
        -alpha off \
        -flatten \
        "$temp_path" 2>/dev/null; then
        
        # Verify the fixed icon
        local fixed_size=$(identify -format "%wx%h" "$temp_path" 2>/dev/null || echo "unknown")
        local has_alpha=$(identify -format "%A" "$temp_path" 2>/dev/null || echo "unknown")
        
        log_info "  Fixed size: $fixed_size, Alpha: $has_alpha"
        
        # Replace original with fixed version
        if mv "$temp_path" "$icon_path"; then
            log_success "  ✅ Icon fixed successfully"
            return 0
        else
            log_error "  ❌ Failed to replace icon"
            rm -f "$temp_path"
            return 1
        fi
    else
        log_error "  ❌ Failed to process icon"
        rm -f "$temp_path"
        return 1
    fi
}

# Validate icon format
validate_icon() {
    local icon_path="$1"
    
    if [[ ! -f "$icon_path" ]]; then
        return 1
    fi
    
    # Check if icon has transparency/alpha
    local alpha_info=$(identify -format "%A" "$icon_path" 2>/dev/null || echo "unknown")
    
    if [[ "$alpha_info" == "True" ]]; then
        log_warning "  ⚠️ Icon still has alpha channel: $icon_path"
        return 1
    else
        log_success "  ✅ Icon validated: $icon_path"
        return 0
    fi
}

# Generate missing icons from the largest one
generate_missing_icons() {
    local source_icon="$ICONS_DIR/Icon-App-1024x1024@1x.png"
    
    if [[ ! -f "$source_icon" ]]; then
        log_error "Source icon not found: $source_icon"
        return 1
    fi
    
    log_info "Generating missing icons from source..."
    
    # Icon size mappings (filename -> dimensions)
    declare -A icon_sizes=(
        ["Icon-App-20x20@1x.png"]="20x20"
        ["Icon-App-20x20@2x.png"]="40x40"
        ["Icon-App-20x20@3x.png"]="60x60"
        ["Icon-App-29x29@1x.png"]="29x29"
        ["Icon-App-29x29@2x.png"]="58x58"
        ["Icon-App-29x29@3x.png"]="87x87"
        ["Icon-App-40x40@1x.png"]="40x40"
        ["Icon-App-40x40@2x.png"]="80x80"
        ["Icon-App-40x40@3x.png"]="120x120"
        ["Icon-App-60x60@2x.png"]="120x120"
        ["Icon-App-60x60@3x.png"]="180x180"
        ["Icon-App-76x76@1x.png"]="76x76"
        ["Icon-App-76x76@2x.png"]="152x152"
        ["Icon-App-83.5x83.5@2x.png"]="167x167"
        ["Icon-App-1024x1024@1x.png"]="1024x1024"
    )
    
    for icon_file in "${REQUIRED_ICONS[@]}"; do
        local icon_path="$ICONS_DIR/$icon_file"
        local target_size="${icon_sizes[$icon_file]}"
        
        if [[ ! -f "$icon_path" ]]; then
            log_info "Generating missing icon: $icon_file ($target_size)"
            
            if convert "$source_icon" \
                -resize "$target_size" \
                -background white \
                -alpha remove \
                -alpha off \
                -flatten \
                "$icon_path" 2>/dev/null; then
                log_success "  ✅ Generated: $icon_file"
            else
                log_error "  ❌ Failed to generate: $icon_file"
            fi
        fi
    done
}

# Main function
main() {
    log_info "🚀 Starting iOS app icon fix process..."
    
    # Check if icons directory exists
    if [[ ! -d "$ICONS_DIR" ]]; then
        log_error "Icons directory not found: $ICONS_DIR"
        log_error "Please ensure you're running this script from the project root"
        exit 1
    fi
    
    # Check ImageMagick availability
    if ! check_imagemagick; then
        log_error "ImageMagick is required but not available"
        exit 1
    fi
    
    log_info "📁 Icons directory: $ICONS_DIR"
    
    # Fix existing icons
    local fixed_count=0
    local total_count=0
    
    for icon_file in "${REQUIRED_ICONS[@]}"; do
        local icon_path="$ICONS_DIR/$icon_file"
        total_count=$((total_count + 1))
        
        if fix_icon "$icon_path"; then
            fixed_count=$((fixed_count + 1))
        fi
    done
    
    log_info "📊 Icon processing summary: $fixed_count/$total_count icons fixed"
    
    # Generate missing icons
    generate_missing_icons
    
    # Final validation
    log_info "🔍 Performing final validation..."
    local valid_count=0
    
    for icon_file in "${REQUIRED_ICONS[@]}"; do
        local icon_path="$ICONS_DIR/$icon_file"
        if validate_icon "$icon_path"; then
            valid_count=$((valid_count + 1))
        fi
    done
    
    log_info "📊 Final validation: $valid_count/$total_count icons valid"
    
    if [[ $valid_count -eq $total_count ]]; then
        log_success "🎉 All app icons are now valid for App Store submission!"
        log_info "📱 Your iOS build should now pass App Store Connect validation"
    else
        log_warning "⚠️ Some icons may still have issues. Please check manually."
        log_info "💡 Common issues: transparency, wrong dimensions, or corrupted files"
    fi
    
    # Show icon information
    log_info "📋 Icon details:"
    for icon_file in "${REQUIRED_ICONS[@]}"; do
        local icon_path="$ICONS_DIR/$icon_file"
        if [[ -f "$icon_path" ]]; then
            local size=$(identify -format "%wx%h" "$icon_path" 2>/dev/null || echo "unknown")
            local alpha=$(identify -format "%A" "$icon_path" 2>/dev/null || echo "unknown")
            log_info "  $icon_file: $size (Alpha: $alpha)"
        else
            log_warning "  $icon_file: MISSING"
        fi
    done
}

# Run main function
main "$@"
