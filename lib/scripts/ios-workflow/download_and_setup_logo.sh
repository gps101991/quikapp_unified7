#!/bin/bash
# 🎨 Download and Setup Logo Script
# Downloads logo from LOGO_URL and sets up for iOS app icons

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [LOGO_SETUP] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "Starting logo download and setup process..."

# Check if LOGO_URL is provided
if [[ -z "${LOGO_URL:-}" ]]; then
    log_error "LOGO_URL environment variable is not set"
    log_error "Cannot download logo for iOS app icons"
    exit 1
fi

log_info "Logo URL: $LOGO_URL"

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
        LOGO_HEIGHT=$(echo "$LOGO_SIZE" | cut -d'x' -f2)
        
        log_info "Logo dimensions: ${LOGO_WIDTH}x${LOGO_HEIGHT}"
        
        if [[ "$LOGO_WIDTH" -ge 1024 ]] && [[ "$LOGO_HEIGHT" -ge 1024 ]]; then
            log_success "✅ Logo has excellent resolution for iOS app icons"
        elif [[ "$LOGO_WIDTH" -ge 512 ]] && [[ "$LOGO_HEIGHT" -ge 512 ]]; then
            log_success "✅ Logo has good resolution for iOS app icons"
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

log_success "🎉 Logo download and setup completed successfully!"
log_info "Logo is now available at: $LOGO_PATH"
log_info "Ready for Flutter Launcher Icons or manual icon generation"
