#!/bin/bash
# 🎨 Setup Logo for flutter_launcher_icons
# Ensures the logo file exists and is properly configured

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [LOGO_SETUP] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "🎨 Setting up logo for flutter_launcher_icons..."

# Check if LOGO_URL environment variable is set
if [[ -z "${LOGO_URL:-}" ]]; then
    log_error "LOGO_URL environment variable is not set"
    log_error "Cannot download logo for icon generation"
    exit 1
fi

log_info "Logo URL: $LOGO_URL"

# Create assets directory structure
ASSETS_DIR="assets/images"
mkdir -p "$ASSETS_DIR"

# Download logo with proper SSL verification and error handling
echo "🚀 Started: Downloading logo from $LOGO_URL"

# Try downloading with SSL certificate check first (silent test)
wget --spider --quiet "$LOGO_URL"
if [ $? -ne 0 ]; then
    echo "⚠️ SSL verification failed. Retrying with --no-check-certificate..."
    WGET_OPTS="--no-check-certificate"
else
    WGET_OPTS=""
fi

# Attempt actual download
wget $WGET_OPTS -O assets/images/logo.png "$LOGO_URL"

# Check if the file was successfully downloaded
if [ ! -f assets/images/logo.png ]; then
    echo "❌ Error: Failed to download logo from $LOGO_URL"
    exit 1
fi

# Verify downloaded logo
if [[ ! -s "$ASSETS_DIR/logo.png" ]]; then
    log_error "Downloaded logo file is empty"
    exit 1
fi

log_success "✅ Completed: Logo downloaded"

# Check logo dimensions and quality
if command -v sips > /dev/null 2>&1; then
    LOGO_SIZE=$(sips -g pixelWidth -g pixelHeight "$ASSETS_DIR/logo.png" 2>/dev/null | grep -E "(pixelWidth|pixelHeight)" | awk '{print $2}' | tr '\n' 'x' | sed 's/x$//')
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

log_success "🎉 Logo setup completed successfully!"
log_info "📁 Logo file: $ASSETS_DIR/logo.png"
log_info "🚀 Ready to run: flutter pub run flutter_launcher_icons"
