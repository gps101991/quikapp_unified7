#!/bin/bash
set -euo pipefail
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"; }
handle_error() { log "ERROR: $1"; exit 1; }
trap 'handle_error "Error occurred at line $LINENO"' ERR

FIREBASE_CONFIG_ANDROID=${FIREBASE_CONFIG_ANDROID:-}
PUSH_NOTIFY=${PUSH_NOTIFY:-false}
IS_GOOGLE_AUTH=${IS_GOOGLE_AUTH:-false}

log "Starting Firebase configuration for Android"
log "PUSH_NOTIFY: $PUSH_NOTIFY"
log "IS_GOOGLE_AUTH: $IS_GOOGLE_AUTH"
log "FIREBASE_CONFIG_ANDROID: ${FIREBASE_CONFIG_ANDROID:-'Not provided'}"

# Check if Firebase is needed
if [ "$PUSH_NOTIFY" != "true" ] && [ "$IS_GOOGLE_AUTH" != "true" ]; then
    log "Firebase not required (PUSH_NOTIFY=$PUSH_NOTIFY, IS_GOOGLE_AUTH=$IS_GOOGLE_AUTH)"
    log "Removing any existing Firebase configuration..."
    
    # Remove existing Firebase files
    rm -f android/app/google-services.json 2>/dev/null || true
    rm -f assets/google-services.json 2>/dev/null || true
    
    log "✅ Firebase configuration removed - not required for this build"
    exit 0
fi

# Firebase is required, validate configuration
if [ -z "$FIREBASE_CONFIG_ANDROID" ]; then
    log "❌ Firebase required but FIREBASE_CONFIG_ANDROID not provided"
    log "🔄 Skipping Firebase setup - build will continue without Firebase"
    
    # Remove any existing Firebase files
    rm -f android/app/google-services.json 2>/dev/null || true
    rm -f assets/google-services.json 2>/dev/null || true
    
    log "⚠️ Firebase setup skipped - no configuration provided"
    log "⚠️ Push notifications and Google auth will not work"
    exit 0
fi

log "Validating Firebase config URL: $FIREBASE_CONFIG_ANDROID"

# Check if URL is reachable
if ! curl --output /dev/null --silent --head --fail "$FIREBASE_CONFIG_ANDROID"; then
    log "❌ Firebase config URL is not accessible: $FIREBASE_CONFIG_ANDROID"
    log "🔄 Skipping Firebase setup - build will continue without Firebase"
    
    # Remove any existing Firebase files
    rm -f android/app/google-services.json 2>/dev/null || true
    rm -f assets/google-services.json 2>/dev/null || true
    
    log "⚠️ Firebase setup skipped - URL not accessible"
    log "⚠️ Push notifications and Google auth will not work"
    exit 0
fi

log "Downloading Firebase configuration from $FIREBASE_CONFIG_ANDROID"
if curl -L "$FIREBASE_CONFIG_ANDROID" -o android/app/google-services.json --silent --show-error --max-time 30; then
    log "✅ Firebase configuration downloaded successfully"
else
    log "❌ Failed to download Firebase configuration"
    log "🔄 Skipping Firebase setup - build will continue without Firebase"
    
    # Remove any existing Firebase files
    rm -f android/app/google-services.json 2>/dev/null || true
    rm -f assets/google-services.json 2>/dev/null || true
    
    log "⚠️ Firebase setup skipped - download failed"
    log "⚠️ Push notifications and Google auth will not work"
    exit 0
fi

# Validate downloaded file
if [ ! -f android/app/google-services.json ]; then
    log "❌ google-services.json was not created after download"
    log "🔄 Skipping Firebase setup - build will continue without Firebase"
    
    # Remove any existing Firebase files
    rm -f android/app/google-services.json 2>/dev/null || true
    rm -f assets/google-services.json 2>/dev/null || true
    
    log "⚠️ Firebase setup skipped - file creation failed"
    log "⚠️ Push notifications and Google auth will not work"
    exit 0
fi

# Check file size (should be > 100 bytes for a valid config)
FIREBASE_SIZE=$(stat -f%z android/app/google-services.json 2>/dev/null || stat -c%s android/app/google-services.json 2>/dev/null || echo "0")
if [ "$FIREBASE_SIZE" -lt 100 ]; then
    log "⚠️ Firebase config file seems too small ($FIREBASE_SIZE bytes). This might be an error page."
    log "🔄 Skipping Firebase setup - build will continue without Firebase"
    
    # Remove any existing Firebase files
    rm -f android/app/google-services.json 2>/dev/null || true
    rm -f assets/google-services.json 2>/dev/null || true
    
    log "⚠️ Firebase setup skipped - invalid config file"
    log "⚠️ Push notifications and Google auth will not work"
    exit 0
fi

# Validate JSON format
if ! python3 -c "import json; json.load(open('android/app/google-services.json'))" 2>/dev/null; then
    log "❌ Invalid JSON format in downloaded Firebase config"
    log "🔄 Skipping Firebase setup - build will continue without Firebase"
    
    # Remove any existing Firebase files
    rm -f android/app/google-services.json 2>/dev/null || true
    rm -f assets/google-services.json 2>/dev/null || true
    
    log "⚠️ Firebase setup skipped - invalid JSON format"
    log "⚠️ Push notifications and Google auth will not work"
    exit 0
fi

# Check for required fields
if ! grep -q "project_info" android/app/google-services.json; then
    log "❌ Invalid Firebase config: missing project_info"
    log "🔄 Skipping Firebase setup - build will continue without Firebase"
    
    # Remove any existing Firebase files
    rm -f android/app/google-services.json 2>/dev/null || true
    rm -f assets/google-services.json 2>/dev/null || true
    
    log "⚠️ Firebase setup skipped - missing required fields"
    log "⚠️ Push notifications and Google auth will not work"
    exit 0
fi

if ! grep -q "client" android/app/google-services.json; then
    log "❌ Invalid Firebase config: missing client configuration"
    log "🔄 Skipping Firebase setup - build will continue without Firebase"
    
    # Remove any existing Firebase files
    rm -f android/app/google-services.json 2>/dev/null || true
    rm -f assets/google-services.json 2>/dev/null || true
    
    log "⚠️ Firebase setup skipped - missing client configuration"
    log "⚠️ Push notifications and Google auth will not work"
    exit 0
fi

# Copy to assets directory
mkdir -p assets
cp android/app/google-services.json assets/google-services.json || log "⚠️ Failed to copy google-services.json to assets"

log "✅ Firebase configuration validated and installed successfully"
log "📋 Config file size: $FIREBASE_SIZE bytes"

log "Firebase configuration completed successfully"
exit 0 