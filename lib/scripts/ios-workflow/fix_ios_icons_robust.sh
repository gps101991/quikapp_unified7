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

# Priority 1: Look for a high-quality source icon (preferably 1024x1024 or larger)
if [[ -f "assets/images/default_logo.png" ]]; then
    SOURCE_ICON="assets/images/default_logo.png"
    log_info "Using default logo as source icon"
elif [[ -f "assets/images/logo.png" ]]; then
    SOURCE_ICON="assets/images/logo.png"
    log_info "Using logo as source icon"
elif [[ -f "assets/logo.png" ]]; then
    SOURCE_ICON="assets/logo.png"
    log_info "Using assets logo as source icon"
fi

# Priority 2: Look for any high-resolution PNG in the project (avoiding icon directory)
if [[ -z "$SOURCE_ICON" ]]; then
    log_info "Searching for high-resolution source images..."
    # Find PNGs outside the icon directory, sorted by size (largest first)
    SOURCE_ICON=$(find . -name "*.png" -not -path "./ios/Runner/Assets.xcassets/AppIcon.appiconset/*" -not -path "./ios/Runner/Assets.xcassets/LaunchImage.imageset/*" -exec ls -la {} \; | sort -k5 -nr | head -1 | awk '{print $9}')
    if [[ -n "$SOURCE_ICON" ]]; then
        log_info "Found high-resolution source: $SOURCE_ICON"
    fi
fi

# Priority 3: Look for any PNG in the project (last resort)
if [[ -z "$SOURCE_ICON" ]]; then
    SOURCE_ICON=$(find . -name "*.png" | head -1)
    if [[ -n "$SOURCE_ICON" ]]; then
        log_warning "⚠️ Using fallback source icon: $SOURCE_ICON"
    fi
fi

if [[ -z "$SOURCE_ICON" ]]; then
    log_error "No source icon found for generation"
    exit 1
fi

# Validate source icon quality
if command -v sips > /dev/null 2>&1; then
    SOURCE_SIZE=$(sips -g pixelWidth -g pixelHeight "$SOURCE_ICON" 2>/dev/null | grep -E "(pixelWidth|pixelHeight)" | awk '{print $2}' | tr '\n' 'x' | sed 's/x$//')
    if [[ -n "$SOURCE_SIZE" ]]; then
        SOURCE_WIDTH=$(echo "$SOURCE_SIZE" | cut -d'x' -f1)
        SOURCE_HEIGHT=$(echo "$SOURCE_SIZE" | cut -d'x' -f2)
        if [[ "$SOURCE_WIDTH" -ge 1024 ]] && [[ "$SOURCE_HEIGHT" -ge 1024 ]]; then
            log_success "✅ Source icon has excellent resolution: $SOURCE_SIZE"
        elif [[ "$SOURCE_WIDTH" -ge 512 ]] && [[ "$SOURCE_HEIGHT" -ge 512 ]]; then
            log_success "✅ Source icon has good resolution: $SOURCE_SIZE"
        elif [[ "$SOURCE_WIDTH" -ge 256 ]] && [[ "$SOURCE_HEIGHT" -ge 256 ]]; then
            log_warning "⚠️ Source icon has moderate resolution: $SOURCE_SIZE (may affect quality)"
        else
            log_warning "⚠️ Source icon has low resolution: $SOURCE_SIZE (will affect quality)"
        fi
    fi
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

# Special handling for 1024x1024 icon (most critical for App Store Connect)
ICON_1024_PATH="$ICON_DIR/Icon-App-1024x1024@1x.png"
log_info "Ensuring 1024x1024 icon is properly generated for App Store Connect..."

# Force regenerate 1024x1024 icon if it doesn't exist, is invalid, or has wrong dimensions
NEEDS_REGENERATION=false

if [[ ! -f "$ICON_1024_PATH" ]] || [[ ! -s "$ICON_1024_PATH" ]]; then
    log_info "1024x1024 icon missing or empty, will regenerate..."
    NEEDS_REGENERATION=true
else
    # Check if existing icon has correct dimensions
    if command -v sips > /dev/null 2>&1; then
        ICON_SIZE=$(sips -g pixelWidth -g pixelHeight "$ICON_1024_PATH" 2>/dev/null | grep -E "(pixelWidth|pixelHeight)" | awk '{print $2}' | tr '\n' 'x' | sed 's/x$//')
        if [[ "$ICON_SIZE" != "1024x1024" ]]; then
            log_warning "⚠️ 1024x1024 icon has wrong dimensions: $ICON_SIZE (expected: 1024x1024), will regenerate..."
            NEEDS_REGENERATION=true
        else
            log_success "✅ 1024x1024 icon already exists with correct dimensions (1024x1024)"
        fi
    else
        log_warning "⚠️ Cannot verify icon dimensions (sips not available), will regenerate to ensure correctness..."
        NEEDS_REGENERATION=true
    fi
fi

if [[ "$NEEDS_REGENERATION" == "true" ]]; then
    log_info "Generating 1024x1024 icon (critical for App Store Connect)..."
    
    # Try sips first
    if sips -s format png -z 1024 1024 "$SOURCE_ICON" --out "$ICON_1024_PATH" > /dev/null 2>&1; then
        log_success "✅ 1024x1024 icon generated successfully using sips"
    else
        log_warning "⚠️ sips failed, trying ImageMagick..."
        # Try ImageMagick as fallback
        if command -v convert > /dev/null 2>&1; then
            if convert "$SOURCE_ICON" -resize 1024x1024 "$ICON_1024_PATH" > /dev/null 2>&1; then
                log_success "✅ 1024x1024 icon generated successfully using ImageMagick"
            else
                log_error "❌ Failed to generate 1024x1024 icon with ImageMagick"
                exit 1
            fi
        else
            log_error "❌ Failed to generate 1024x1024 icon - no image tools available"
            exit 1
        fi
    fi
    
    # Verify the generated icon
    if [[ -f "$ICON_1024_PATH" ]] && [[ -s "$ICON_1024_PATH" ]]; then
        if command -v sips > /dev/null 2>&1; then
            ICON_SIZE=$(sips -g pixelWidth -g pixelHeight "$ICON_1024_PATH" 2>/dev/null | grep -E "(pixelWidth|pixelHeight)" | awk '{print $2}' | tr '\n' 'x' | sed 's/x$//')
            if [[ "$ICON_SIZE" == "1024x1024" ]]; then
                log_success "✅ 1024x1024 icon validated: correct dimensions and content"
            else
                log_error "❌ 1024x1024 icon has wrong dimensions: $ICON_SIZE (expected: 1024x1024)"
                exit 1
            fi
        else
            log_success "✅ 1024x1024 icon generated and has content"
        fi
    else
        log_error "❌ 1024x1024 icon generation failed"
        exit 1
    fi
fi

# Generate each icon
for icon_info in "${CRITICAL_ICONS[@]}"; do
    icon="${icon_info%%:*}"
    size="${icon_info##*:}"
    filepath="$ICON_DIR/$icon"
    
    NEEDS_GENERATION=false
    
    if [[ ! -f "$filepath" ]] || [[ ! -s "$filepath" ]]; then
        log_info "$icon missing or empty, will generate..."
        NEEDS_GENERATION=true
    else
        # For critical icons, also check dimensions
        if [[ "$icon" == "Icon-App-60x60@2x.png" ]] || [[ "$icon" == "Icon-App-76x76@2x.png" ]] || [[ "$icon" == "Icon-App-83.5x83.5@2x.png" ]]; then
            if command -v sips > /dev/null 2>&1; then
                ICON_SIZE=$(sips -g pixelWidth -g pixelHeight "$filepath" 2>/dev/null | grep -E "(pixelWidth|pixelHeight)" | awk '{print $2}' | tr '\n' 'x' | sed 's/x$//')
                EXPECTED_SIZE="${size%x*}x${size#*x}"
                if [[ "$ICON_SIZE" != "$EXPECTED_SIZE" ]]; then
                    log_warning "⚠️ $icon has wrong dimensions: $ICON_SIZE (expected: $EXPECTED_SIZE), will regenerate..."
                    NEEDS_GENERATION=true
                else
                    log_success "$icon already exists with correct dimensions ($EXPECTED_SIZE)"
                fi
            else
                log_success "$icon already exists"
            fi
        else
            log_success "$icon already exists"
        fi
    fi
    
    if [[ "$NEEDS_GENERATION" == "true" ]]; then
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
    fi
done

# Step 4: Create/Update Contents.json
log_info "Step 4: Creating/Updating Contents.json..."
CONTENTS_JSON="$ICON_DIR/Contents.json"

# Check if Contents.json is corrupted and fix it first
if [[ -f "$CONTENTS_JSON" ]]; then
    if ! plutil -lint "$CONTENTS_JSON" >/dev/null 2>&1; then
        log_warning "⚠️ Contents.json is corrupted, fixing it first..."
        
        # Create backup
        BACKUP_PATH="${CONTENTS_JSON}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$CONTENTS_JSON" "$BACKUP_PATH"
        log_info "Backup created: $BACKUP_PATH"
        
        # Remove corrupted file
        rm "$CONTENTS_JSON"
        log_info "Corrupted Contents.json removed"
    fi
fi

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
      "size" : "1024x1024",
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "any"
        }
      ]
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

# Special validation for 1024x1024 icon (critical for App Store Connect)
ICON_1024_PATH="$ICON_DIR/Icon-App-1024x1024@1x.png"
if [[ ! -f "$ICON_1024_PATH" ]]; then
    log_error "❌ CRITICAL: 1024x1024 icon missing - App Store Connect upload will fail"
    MISSING_ICONS+=("Icon-App-1024x1024@1x.png (1024x1024)")
elif [[ ! -s "$ICON_1024_PATH" ]]; then
    log_error "❌ CRITICAL: 1024x1024 icon is empty - App Store Connect upload will fail"
    EMPTY_ICONS+=("Icon-App-1024x1024@1x.png (1024x1024)")
else
    # Verify the icon dimensions
    ICON_SIZE=$(sips -g pixelWidth -g pixelHeight "$ICON_1024_PATH" 2>/dev/null | grep -E "(pixelWidth|pixelHeight)" | awk '{print $2}' | tr '\n' 'x' | sed 's/x$//')
    if [[ "$ICON_SIZE" == "1024x1024" ]]; then
        log_success "✅ 1024x1024 icon validated: correct dimensions and content"
    else
        log_error "❌ CRITICAL: 1024x1024 icon has wrong dimensions: $ICON_SIZE (expected: 1024x1024)"
        EMPTY_ICONS+=("Icon-App-1024x1024@1x.png (wrong dimensions: $ICON_SIZE)")
    fi
fi

if [[ ${#MISSING_ICONS[@]} -gt 0 ]]; then
    log_error "Missing icons:"
    for icon in "${MISSING_ICONS[@]}"; do
        log_error "  - $icon"
    done
    exit 1
fi

if [[ ${#EMPTY_ICONS[@]} -gt 0 ]]; then
    log_error "Empty or invalid icons:"
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

# App Store Connect specific validation
log_info "🔍 App Store Connect validation check..."
log_info "Checking for 'Any Appearance' 1024x1024 icon requirement..."

ICON_1024_PATH="$ICON_DIR/Icon-App-1024x1024@1x.png"
if [[ -f "$ICON_1024_PATH" ]] && [[ -s "$ICON_1024_PATH" ]]; then
    # Verify dimensions
    ICON_SIZE=$(sips -g pixelWidth -g pixelHeight "$ICON_1024_PATH" 2>/dev/null | grep -E "(pixelWidth|pixelHeight)" | awk '{print $2}' | tr '\n' 'x' | sed 's/x$//')
    if [[ "$ICON_SIZE" == "1024x1024" ]]; then
        log_success "✅ 1024x1024 icon: correct dimensions (1024x1024)"
        
        # Check if Contents.json has proper appearances field
        if grep -q '"appearance" : "luminosity"' "$CONTENTS_JSON"; then
            log_success "✅ Contents.json: 'Any Appearance' field properly configured"
            log_success "✅ App Store Connect: Should pass icon validation"
        else
            log_warning "⚠️ Contents.json: 'Any Appearance' field missing"
        fi
    else
        log_error "❌ 1024x1024 icon: wrong dimensions ($ICON_SIZE), expected 1024x1024"
        log_error "❌ App Store Connect: Will fail icon validation"
    fi
else
    log_error "❌ 1024x1024 icon: missing or empty"
    log_error "❌ App Store Connect: Will fail icon validation"
fi

log_success "🎉 Robust iOS icon fix completed successfully!"
log_info "📱 App should now pass App Store Connect icon validation"
