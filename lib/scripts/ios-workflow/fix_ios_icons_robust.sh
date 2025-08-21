#!/bin/bash
# 🍎 Robust iOS Icon Fix Script
# Ensures all critical icons are generated for App Store Connect validation

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ROBUST_ICON_FIX] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "Starting robust iOS icon fix..."

# Step 1: Ensure asset catalog directory structure
log_info "Step 1: Ensuring asset catalog directory structure..."
ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$ICON_DIR"

if [[ ! -d "$ICON_DIR" ]]; then
    log_error "Failed to create icon directory: $ICON_DIR"
    exit 1
fi
log_success "Asset catalog directory structure ready"

# Step 2: Find source icon
log_info "Step 2: Finding source icon..."
SOURCE_ICON=""
for icon in "$ICON_DIR"/*.png; do
    if [[ -f "$icon" ]]; then
        SOURCE_ICON="$icon"
        break
    fi
done

if [[ -z "$SOURCE_ICON" ]]; then
    # Try to find any PNG in the project
    SOURCE_ICON=$(find ios -name "*.png" | head -1)
fi

if [[ -z "$SOURCE_ICON" ]]; then
    log_error "No source icon found for generation"
    exit 1
fi

log_success "Source icon identified: $SOURCE_ICON"

# Step 3: Generate all required icon sizes
log_info "Step 3: Generating all required icon sizes..."

# Critical icons that must exist for App Store Connect
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

# Generate each icon
for icon_info in "${CRITICAL_ICONS[@]}"; do
    icon="${icon_info%%:*}"
    size="${icon_info##*:}"
    filepath="$ICON_DIR/$icon"
    
    if [[ ! -f "$filepath" ]] || [[ ! -s "$filepath" ]]; then
        log_info "Generating $icon ($size)..."
        if sips -s format png -z "${size%x*}" "${size#*x}" "$SOURCE_ICON" --out "$filepath" > /dev/null 2>&1; then
            log_success "Generated $icon"
        else
            log_warning "Failed to generate $icon, trying alternative method..."
            # Alternative method using ImageMagick if available
            if command -v convert > /dev/null 2>&1; then
                if convert "$SOURCE_ICON" -resize "$size" "$filepath" > /dev/null 2>&1; then
                    log_success "Generated $icon using ImageMagick"
                else
                    log_error "Failed to generate $icon with ImageMagick"
                fi
            else
                log_error "Failed to generate $icon - no image tools available"
            fi
        fi
    else
        log_success "$icon already exists"
    fi
done

# Step 4: Create/Update Contents.json
log_info "Step 4: Creating/Updating Contents.json..."
CONTENTS_JSON="$ICON_DIR/Contents.json"

cat > "$CONTENTS_JSON" << 'EOF'
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
EOF

log_success "Contents.json created/updated"

# Step 5: Ensure Info.plist has correct CFBundleIconName
log_info "Step 5: Ensuring Info.plist has correct CFBundleIconName..."
PLIST_PATH="ios/Runner/Info.plist"

if [[ -f "$PLIST_PATH" ]]; then
    # Check if CFBundleIconName exists
    if ! grep -q "CFBundleIconName" "$PLIST_PATH"; then
        log_info "Adding CFBundleIconName to Info.plist..."
        # Add CFBundleIconName after the first <dict> tag
        sed -i '' 's/<dict>/<dict>\n\t<key>CFBundleIconName<\/key>\n\t<string>AppIcon<\/string>/' "$PLIST_PATH"
        log_success "CFBundleIconName added to Info.plist"
    else
        log_info "Updating CFBundleIconName in Info.plist..."
        # Update existing CFBundleIconName
        sed -i '' 's/<key>CFBundleIconName<\/key>.*<string>.*<\/string>/<key>CFBundleIconName<\/key>\n\t<string>AppIcon<\/string>/' "$PLIST_PATH"
        log_success "CFBundleIconName updated in Info.plist"
    fi
else
    log_error "Info.plist not found: $PLIST_PATH"
    exit 1
fi

# Step 6: Verify all critical icons exist and have content
log_info "Step 6: Verifying all critical icons exist and have content..."
MISSING_ICONS=()
EMPTY_ICONS=()

for icon_info in "${CRITICAL_ICONS[@]}"; do
    icon="${icon_info%%:*}"
    size="${icon_info##*:}"
    filepath="$ICON_DIR/$icon"
    
    if [[ ! -f "$filepath" ]]; then
        MISSING_ICONS+=("$icon ($size)")
    elif [[ ! -s "$filepath" ]]; then
        EMPTY_ICONS+=("$icon ($size)")
    fi
done

if [[ ${#MISSING_ICONS[@]} -gt 0 ]]; then
    log_error "Missing icons:"
    for icon in "${MISSING_ICONS[@]}"; do
        log_error "  - $icon"
    done
    exit 1
fi

if [[ ${#EMPTY_ICONS[@]} -gt 0 ]]; then
    log_error "Empty icons:"
    for icon in "${EMPTY_ICONS[@]}"; do
        log_error "  - $icon"
    done
    exit 1
fi

log_success "All critical icons are present and have content"

# Step 7: Validate asset catalog
log_info "Step 7: Validating asset catalog..."
if plutil -lint "$CONTENTS_JSON" > /dev/null 2>&1; then
    log_success "Asset catalog validation passed"
else
    log_error "Asset catalog validation failed"
    plutil -lint "$CONTENTS_JSON"
    exit 1
fi

# Step 8: Final verification
log_info "Step 8: Final verification..."
log_info "Icon directory: $ICON_DIR"
log_info "Total icons: $(ls -1 "$ICON_DIR"/*.png 2>/dev/null | wc -l)"
log_info "Contents.json: $(wc -l < "$CONTENTS_JSON") lines"

# Check specific critical sizes
CRITICAL_SIZES=("120x120" "152x152" "167x167")
for size in "${CRITICAL_SIZES[@]}"; do
    case $size in
        "120x120")
            icon="Icon-App-60x60@2x.png"
            ;;
        "152x152")
            icon="Icon-App-76x76@2x.png"
            ;;
        "167x167")
            icon="Icon-App-83.5x83.5@2x.png"
            ;;
    esac
    
    filepath="$ICON_DIR/$icon"
    if [[ -f "$filepath" ]] && [[ -s "$filepath" ]]; then
        log_success "✅ $size icon ($icon) is present and valid"
    else
        log_error "❌ $size icon ($icon) is missing or empty"
        exit 1
    fi
done

log_success "🎉 Robust iOS icon fix completed successfully!"
log_info "📱 App should now pass App Store Connect icon validation"
