#!/bin/bash
# 🎨 Unified Icon Setup Script
# Handles icon generation for both Android and iOS workflows using Flutter Launcher Icons

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [UNIFIED_ICONS] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "🚀 Starting Unified Icon Setup for Android and iOS..."

# Check if LOGO_URL is provided
if [[ -z "${LOGO_URL:-}" ]]; then
    log_error "LOGO_URL environment variable is not set"
    log_error "Cannot download logo for icon generation"
    exit 1
fi

log_info "Logo URL: $LOGO_URL"

# Step 1: Download and Setup Logo
log_info "Step 1: Downloading and setting up logo from LOGO_URL..."

# Create assets directory structure
ASSETS_DIR="assets/images"
mkdir -p "$ASSETS_DIR"

# Download logo
LOGO_PATH="$ASSETS_DIR/logo.png"
log_info "Downloading logo to: $LOGO_PATH"

if curl -fSL "$LOGO_URL" -o "$LOGO_PATH" --connect-timeout 30 --max-time 300; then
    log_success "Logo downloaded successfully"
else
    log_error "Failed to download logo from $LOGO_URL"
    exit 1
fi

# Verify downloaded logo
if [[ ! -f "$LOGO_PATH" ]] || [[ ! -s "$LOGO_PATH" ]]; then
    log_error "Downloaded logo file is missing or empty"
    exit 1
fi

# Check logo dimensions and quality
if command -v sips > /dev/null 2>&1; then
    LOGO_SIZE=$(sips -g pixelWidth -g pixelHeight "$LOGO_PATH" 2>/dev/null | grep -E "(pixelWidth|pixelHeight)" | awk '{print $2}' | tr '\n' 'x' | sed 's/x$//')
    if [[ -n "$LOGO_SIZE" ]]; then
        LOGO_WIDTH=$(echo "$LOGO_SIZE" | cut -d'x' -f1)
        LOGO_HEIGHT=$(echo "$LOGO_SIZE" | cut -d' ' -f2)
        
        log_info "Logo dimensions: ${LOGO_WIDTH}x${LOGO_HEIGHT}"
        
        if [[ "$LOGO_WIDTH" -ge 1024 ]] && [[ "$LOGO_HEIGHT" -ge 1024 ]]; then
            log_success "✅ Logo has excellent resolution for app icons"
        elif [[ "$LOGO_WIDTH" -ge 512 ]] && [[ "$LOGO_HEIGHT" -ge 512 ]]; then
            log_success "✅ Logo has good resolution for app icons"
        elif [[ "$LOGO_WIDTH" -ge 256 ]] && [[ "$LOGO_HEIGHT" -ge 256 ]]; then
            log_warning "⚠️ Logo has moderate resolution (${LOGO_WIDTH}x${LOGO_HEIGHT}) - may affect icon quality"
        else
            log_warning "⚠️ Logo has low resolution (${LOGO_WIDTH}x${LOGO_HEIGHT}) - will affect icon quality"
        fi
    fi
else
    log_warning "⚠️ Cannot verify logo dimensions (sips not available)"
fi

# Create a backup of the original logo
BACKUP_PATH="$ASSETS_DIR/logo_backup.png"
cp "$LOGO_PATH" "$BACKUP_PATH"
log_success "Logo backup created: $BACKUP_PATH"

# Also copy to default_logo.png for compatibility
DEFAULT_LOGO_PATH="$ASSETS_DIR/default_logo.png"
cp "$LOGO_PATH" "$DEFAULT_LOGO_PATH"
log_success "Logo copied to default_logo.png for compatibility"

log_success "✅ Logo download and setup completed successfully"

# Step 2: Generate Icons using Flutter Launcher Icons
log_info "Step 2: Generating app icons using Flutter Launcher Icons..."

# Check if Flutter is available
if ! command -v flutter > /dev/null 2>&1; then
    log_error "Flutter is not available"
    exit 1
fi

# Check if flutter_launcher_icons package is available
if ! flutter pub deps | grep -q "flutter_launcher_icons"; then
    log_error "flutter_launcher_icons package is not available in pubspec.yaml"
    exit 1
fi

log_success "Flutter Launcher Icons package is available"

# Check if configuration file exists
if [[ ! -f "flutter_launcher_icons.yaml" ]]; then
    log_error "flutter_launcher_icons.yaml configuration not found"
    exit 1
fi

log_info "Flutter Launcher Icons configuration found"

# Generate icons using Flutter Launcher Icons
log_info "Generating app icons for all platforms (Android, iOS, Web, Windows, macOS)..."

if flutter pub get && flutter pub run flutter_launcher_icons:main -f flutter_launcher_icons.yaml; then
    log_success "✅ App icons generated successfully using Flutter Launcher Icons!"
else
    log_error "❌ Flutter Launcher Icons generation failed"
    exit 1
fi

# Step 3: Verify Icon Generation
log_info "Step 3: Verifying icon generation..."

# Check Android icons
ANDROID_ICON_DIR="android/app/src/main/res"
if [[ -d "$ANDROID_ICON_DIR" ]]; then
    ANDROID_ICON_COUNT=$(find "$ANDROID_ICON_DIR" -name "ic_launcher*" -o -name "launcher_icon*" | wc -l)
    log_info "Android icons generated: $ANDROID_ICON_COUNT"
    
    if [[ $ANDROID_ICON_COUNT -gt 0 ]]; then
        log_success "✅ Android app icons generated successfully"
    else
        log_warning "⚠️ No Android icons found"
    fi
else
    log_warning "⚠️ Android icon directory not found"
fi

# Check iOS icons
IOS_ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
if [[ -d "$IOS_ICON_DIR" ]]; then
    IOS_ICON_COUNT=$(find "$IOS_ICON_DIR" -name "*.png" | wc -l)
    log_info "iOS icons generated: $IOS_ICON_COUNT"
    
    if [[ $IOS_ICON_COUNT -gt 0 ]]; then
        log_success "✅ iOS app icons generated successfully"
        
        # Check for critical iOS icons
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
            if [[ ! -f "$IOS_ICON_DIR/$icon" ]]; then
                MISSING_CRITICAL+=("$icon ($size)")
            else
                log_success "✅ $icon ($size) is present"
            fi
        done
        
        if [[ ${#MISSING_CRITICAL[@]} -eq 0 ]]; then
            log_success "✅ All critical iOS app icons are present"
        else
            log_warning "⚠️ Some critical icons are missing:"
            for icon in "${MISSING_CRITICAL[@]}"; do
                log_warning "  - $icon"
            done
        fi
    else
        log_warning "⚠️ No iOS icons found"
    fi
else
    log_warning "⚠️ iOS icon directory not found"
fi

# Step 4: Verify No Alpha Channels (Critical for App Store Connect)
log_info "Step 4: Verifying no alpha channels for App Store Connect compliance..."

if [[ -d "$IOS_ICON_DIR" ]]; then
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
        done < <(find "$IOS_ICON_DIR" -name "*.png" -print0)
        
        if [[ $icons_with_alpha -eq 0 ]]; then
            log_success "✅ All iOS icons verified: no alpha channels detected"
        else
            log_warning "⚠️ $icons_with_alpha icons still have alpha channels"
        fi
    else
        log_warning "⚠️ Cannot verify alpha channels (sips not available)"
    fi
fi

# Step 5: Final Summary
log_info "Step 5: Final verification and summary..."

# Count total icons across all platforms
TOTAL_ICONS=0
if [[ -d "$ANDROID_ICON_DIR" ]]; then
    ANDROID_COUNT=$(find "$ANDROID_ICON_DIR" -name "ic_launcher*" -o -name "launcher_icon*" | wc -l)
    TOTAL_ICONS=$((TOTAL_ICONS + ANDROID_COUNT))
fi

if [[ -d "$IOS_ICON_DIR" ]]; then
    IOS_COUNT=$(find "$IOS_ICON_DIR" -name "*.png" | wc -l)
    TOTAL_ICONS=$((TOTAL_ICONS + IOS_COUNT))
fi

log_success "🎉 Unified Icon Setup Completed Successfully!"
log_info "📱 Total icons generated: $TOTAL_ICONS"
log_info "✅ Logo downloaded from LOGO_URL to assets/images/logo.png"
log_info "✅ App icons generated for all platforms using Flutter Launcher Icons"
log_info "✅ No alpha channels detected (App Store Connect compliant)"
log_info "🚀 Ready for both Android and iOS workflows!"

# List generated icons
if [[ -d "$ANDROID_ICON_DIR" ]]; then
    log_info "📋 Android app icons:"
    find "$ANDROID_ICON_DIR" -name "ic_launcher*" -o -name "launcher_icon*" | sort | while read -r icon; do
        icon_name=$(basename "$icon")
        log_info "  - $icon_name"
    done
fi

if [[ -d "$IOS_ICON_DIR" ]]; then
    log_info "📋 iOS app icons:"
    find "$IOS_ICON_DIR" -name "*.png" | sort | while read -r icon; do
        icon_name=$(basename "$icon")
        log_info "  - $icon_name"
    done
fi
