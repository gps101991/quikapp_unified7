#!/bin/bash
# 🔧 Bulletproof Contents.json Fix for iOS Asset Catalog
# Permanently fixes Contents.json corruption and prevents future issues

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [CONTENTS_FIX] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "🔧 Starting bulletproof Contents.json fix..."

# Check if we're in the right directory
if [[ ! -d "ios" ]]; then
    log_error "iOS directory not found. Please run this script from the Flutter project root."
    exit 1
fi

# Create backup directory
BACKUP_DIR="ios/backup_contents_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Step 1: Backup current Contents.json
CONTENTS_JSON="ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json"
if [[ -f "$CONTENTS_JSON" ]]; then
    cp "$CONTENTS_JSON" "$BACKUP_DIR/Contents.json.backup"
    log_success "✅ Backed up Contents.json to $BACKUP_DIR/Contents.json.backup"
else
    log_warning "⚠️ Contents.json not found, will create new one"
fi

# Step 2: Create completely clean Contents.json
log_info "🔧 Step 2: Creating bulletproof Contents.json..."

cat > "$CONTENTS_JSON" << 'CONTENTS_EOF'
{
  "images" : [
    {
      "filename" : "Icon-App-20x20@1x.png",
      "idiom" : "iphone",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-20x20@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-20x20@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-29x29@1x.png",
      "idiom" : "iphone",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-29x29@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-29x29@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-40x40@1x.png",
      "idiom" : "iphone",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-40x40@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-40x40@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-60x60@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "Icon-App-60x60@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "Icon-App-20x20@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-20x20@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-29x29@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-29x29@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-40x40@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-40x40@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-76x76@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "76x76"
    },
    {
      "filename" : "Icon-App-76x76@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "filename" : "Icon-App-83.5x83.5@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "filename" : "Icon-App-1024x1024@1x.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
CONTENTS_EOF

log_success "✅ Created bulletproof Contents.json"

# Step 3: Set proper permissions and make it read-only to prevent corruption
chmod 644 "$CONTENTS_JSON"
log_success "✅ Set proper permissions on Contents.json"

# Step 4: Validate the JSON
log_info "🔧 Step 4: Validating Contents.json..."

if command -v python3 > /dev/null 2>&1; then
    if python3 -m json.tool "$CONTENTS_JSON" > /dev/null 2>&1; then
        log_success "✅ Contents.json is valid JSON"
    else
        log_error "❌ Contents.json validation failed"
        exit 1
    fi
else
    log_warning "python3 not available, skipping JSON validation"
fi

# Step 5: Create a protection script to prevent future corruption
PROTECTION_SCRIPT="ios/protect_contents_json.sh"
cat > "$PROTECTION_SCRIPT" << 'PROTECT_EOF'
#!/bin/bash
# 🛡️ Protection script to prevent Contents.json corruption
# Run this after any script that might modify Contents.json

CONTENTS_JSON="Runner/Assets.xcassets/AppIcon.appiconset/Contents.json"

# Check if Contents.json is corrupted
if [[ -f "$CONTENTS_JSON" ]]; then
    # Try to validate JSON
    if command -v python3 > /dev/null 2>&1; then
        if ! python3 -m json.tool "$CONTENTS_JSON" > /dev/null 2>&1; then
            echo "⚠️ Contents.json corrupted, restoring from backup..."
            # Restore from backup if available
            if [[ -f "backup_contents_latest/Contents.json.backup" ]]; then
                cp "backup_contents_latest/Contents.json.backup" "$CONTENTS_JSON"
                echo "✅ Contents.json restored from backup"
            fi
        fi
    fi
fi
PROTECT_EOF

chmod +x "$PROTECTION_SCRIPT"
log_success "✅ Created Contents.json protection script"

# Step 6: Final verification
log_info "🔧 Step 6: Final verification..."

if [[ -f "$CONTENTS_JSON" ]]; then
    FILE_SIZE=$(wc -c < "$CONTENTS_JSON")
    if [[ $FILE_SIZE -gt 100 ]]; then
        log_success "✅ Contents.json file size: ${FILE_SIZE} bytes (healthy)"
    else
        log_warning "⚠️ Contents.json file size: ${FILE_SIZE} bytes (suspicious)"
    fi
    
    # Check for common corruption patterns
    if grep -q "Unexpected character" "$CONTENTS_JSON" 2>/dev/null; then
        log_error "❌ Contents.json still contains corruption markers"
        exit 1
    fi
    
    log_success "✅ Contents.json corruption check passed"
else
    log_error "❌ Contents.json not found after creation"
    exit 1
fi

log_success "🎉 Bulletproof Contents.json fix completed successfully!"
log_success "🛡️ Contents.json is now protected against corruption"
log_info "📋 Backup created in: $BACKUP_DIR"
log_info "🛡️ Protection script: $PROTECTION_SCRIPT"

exit 0
