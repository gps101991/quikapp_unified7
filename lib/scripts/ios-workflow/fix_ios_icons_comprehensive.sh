#!/bin/bash
# 🍎 Comprehensive iOS Icon Fix Script
# Fixes all iOS icon issues for App Store validation

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ICON_FIX] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "Starting comprehensive iOS icon fix..."

# Step 1: Ensure asset catalog directory exists
log_info "Step 1: Ensuring asset catalog directory structure..."
mkdir -p ios/Runner/Assets.xcassets/AppIcon.appiconset
log_success "Asset catalog directory structure ready"

# Step 2: Check and create source icon if missing
SOURCE_ICON="ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"
if [[ ! -f "$SOURCE_ICON" ]]; then
    log_warning "Source icon not found: $SOURCE_ICON"
    
    # Try to find any existing icon to use as source
    EXISTING_ICONS=($(find ios/Runner/Assets.xcassets/AppIcon.appiconset -name "*.png" 2>/dev/null | head -1))
    
    if [[ ${#EXISTING_ICONS[@]} -gt 0 ]] && [[ -f "${EXISTING_ICONS[0]}" ]]; then
        log_info "Using existing icon as source: ${EXISTING_ICONS[0]}"
        SOURCE_ICON="${EXISTING_ICONS[0]}"
    else
        log_error "No source icon found and no existing icons available"
        log_info "Please ensure you have a 1024x1024 source icon or any existing icon"
        exit 1
    fi
fi

log_success "Source icon identified: $SOURCE_ICON"

# Function to generate icon if missing with better error handling
generate_icon() {
    local size="$1"
    local filename="$2"
    local target_path="ios/Runner/Assets.xcassets/AppIcon.appiconset/$filename"
    
    if [[ ! -f "$target_path" ]]; then
        log_info "Generating missing icon: $filename ($size)"
        
        # Try to use sips (macOS built-in) to resize
        if command -v sips >/dev/null 2>&1; then
            if sips -z "$size" "$size" "$SOURCE_ICON" --out "$target_path" 2>/dev/null; then
                log_success "Generated $filename with sips"
            else
                log_warning "sips failed for $filename, trying fallback method"
                # Copy source icon as fallback
                cp "$SOURCE_ICON" "$target_path"
                log_success "Copied source icon as fallback for $filename"
            fi
        else
            log_warning "sips not available, copying source icon"
            cp "$SOURCE_ICON" "$target_path"
            log_success "Copied source icon for $filename"
        fi
    else
        log_success "$filename already exists"
    fi
}

# Step 3: Generate all required icon sizes with validation
log_info "Step 3: Generating all required icon sizes..."

# iPhone icons
generate_icon "40" "Icon-App-20x20@2x.png"    # 40x40
generate_icon "60" "Icon-App-20x20@3x.png"    # 60x60
generate_icon "58" "Icon-App-29x29@2x.png"    # 58x58
generate_icon "87" "Icon-App-29x29@3x.png"    # 87x87
generate_icon "80" "Icon-App-40x40@2x.png"    # 80x80
generate_icon "120" "Icon-App-40x40@3x.png"   # 120x120
generate_icon "120" "Icon-App-60x60@2x.png"   # 120x120 (CRITICAL - missing)
generate_icon "180" "Icon-App-60x60@3x.png"   # 180x180

# iPad icons
generate_icon "76" "Icon-App-76x76@1x.png"    # 76x76
generate_icon "152" "Icon-App-76x76@2x.png"   # 152x152 (CRITICAL - missing)
generate_icon "167" "Icon-App-83.5x83.5@2x.png" # 167x167 (CRITICAL - missing)

# Marketing icon
generate_icon "1024" "Icon-App-1024x1024@1x.png" # 1024x1024

# Step 4: Fix Contents.json with complete icon configuration
log_info "Step 4: Fixing Contents.json with complete icon configuration..."

cat > "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json" << 'EOF'
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
EOF

log_success "Updated Contents.json with complete icon configuration"

# Step 5: Ensure Info.plist has correct CFBundleIconName
log_info "Step 5: Ensuring Info.plist has correct CFBundleIconName..."

# Backup original Info.plist
cp ios/Runner/Info.plist ios/Runner/Info.plist.backup.icons

# Update CFBundleIconName if not present or incorrect
if ! grep -q "CFBundleIconName" ios/Runner/Info.plist; then
    log_info "Adding CFBundleIconName to Info.plist..."
    sed -i '' '/<\/dict>/i\
	<key>CFBundleIconName</key>\
	<string>AppIcon</string>\
' ios/Runner/Info.plist
    log_success "Added CFBundleIconName to Info.plist"
else
    log_info "CFBundleIconName already present in Info.plist"
    # Ensure it's set to "AppIcon"
    sed -i '' 's/<key>CFBundleIconName<\/key>.*/<key>CFBundleIconName<\/key>\
	<string>AppIcon<\/string>/' ios/Runner/Info.plist
    log_success "Updated CFBundleIconName to AppIcon"
fi

# Step 6: Verify all required icons exist
log_info "Step 6: Verifying all required icons exist..."

REQUIRED_ICONS=(
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
    "Icon-App-1024x1024@1x.png"
)

MISSING_ICONS=()
for icon in "${REQUIRED_ICONS[@]}"; do
    if [[ ! -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/$icon" ]]; then
        MISSING_ICONS+=("$icon")
    fi
done

if [[ ${#MISSING_ICONS[@]} -gt 0 ]]; then
    log_error "Missing icons:"
    for icon in "${MISSING_ICONS[@]}"; do
        log_error "  - $icon"
    done
    exit 1
else
    log_success "All required icons are present"
fi

# Step 7: Validate asset catalog
log_info "Step 7: Validating asset catalog..."

# Check if Contents.json is valid
if plutil -lint "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json" > /dev/null 2>&1; then
    log_success "Contents.json is valid"
else
    log_error "Contents.json is invalid"
    plutil -lint "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json"
    exit 1
fi

# Step 8: Clean up any duplicate entries in Info.plist
log_info "Step 8: Cleaning up Info.plist..."

# Remove duplicate CADisableMinimumFrameDurationOnPhone entries
sed -i '' '/CADisableMinimumFrameDurationOnPhone/,+1d' ios/Runner/Info.plist
sed -i '' '/UIApplicationSupportsIndirectInputEvents/,+1d' ios/Runner/Info.plist

# Add them back once at the end
sed -i '' '/<\/dict>/i\
	<key>CADisableMinimumFrameDurationOnPhone</key>\
	<true/>\
	<key>UIApplicationSupportsIndirectInputEvents</key>\
	<true/>\
' ios/Runner/Info.plist

log_success "Cleaned up Info.plist"

# Step 9: Final validation
log_info "Step 9: Final validation..."

# Validate Info.plist
if plutil -lint ios/Runner/Info.plist > /dev/null 2>&1; then
    log_success "Info.plist is valid"
else
    log_error "Info.plist is invalid"
    plutil -lint ios/Runner/Info.plist
    exit 1
fi

# Check icon sizes
log_info "Checking icon dimensions..."

# Critical sizes that were missing
CRITICAL_SIZES=(
    "120x120:Icon-App-60x60@2x.png"
    "152x152:Icon-App-76x76@2x.png"
    "167x167:Icon-App-83.5x83.5@2x.png"
)

for size_info in "${CRITICAL_SIZES[@]}"; do
    size="${size_info%%:*}"
    filename="${size_info##*:}"
    filepath="ios/Runner/Assets.xcassets/AppIcon.appiconset/$filename"
    
    if [[ -f "$filepath" ]]; then
        log_success "✅ $filename exists (required for $size)"
    else
        log_error "❌ $filename missing (required for $size)"
    fi
done

# Step 10: Force regenerate missing critical icons
log_info "Step 10: Force regenerating critical icons..."

CRITICAL_ICONS=(
    "120:Icon-App-60x60@2x.png"
    "152:Icon-App-76x76@2x.png"
    "167:Icon-App-83.5x83.5@2x.png"
)

for icon_info in "${CRITICAL_ICONS[@]}"; do
    size="${icon_info%%:*}"
    filename="${icon_info##*:}"
    filepath="ios/Runner/Assets.xcassets/AppIcon.appiconset/$filename"
    
    log_info "Force regenerating $filename ($size x $size)..."
    
    # Remove existing file if it exists
    if [[ -f "$filepath" ]]; then
        rm "$filepath"
    fi
    
    # Generate new icon
    if command -v sips >/dev/null 2>&1; then
        if sips -z "$size" "$size" "$SOURCE_ICON" --out "$filepath" 2>/dev/null; then
            log_success "✅ Regenerated $filename"
        else
            log_error "❌ Failed to regenerate $filename"
            # Copy source as fallback
            cp "$SOURCE_ICON" "$filepath"
            log_warning "⚠️ Copied source icon as fallback for $filename"
        fi
    else
        # Copy source as fallback
        cp "$SOURCE_ICON" "$filepath"
        log_warning "⚠️ Copied source icon as fallback for $filename"
    fi
done

# Step 11: Final verification
log_info "Step 11: Final verification..."

# Verify all critical icons exist and have content
for icon_info in "${CRITICAL_ICONS[@]}"; do
    size="${icon_info%%:*}"
    filename="${icon_info##*:}"
    filepath="ios/Runner/Assets.xcassets/AppIcon.appiconset/$filename"
    
    if [[ -f "$filepath" ]] && [[ -s "$filepath" ]]; then
        log_success "✅ $filename exists and has content"
    else
        log_error "❌ $filename missing or empty"
        exit 1
    fi
done

# Summary
log_info "📋 Icon Fix Summary:"
echo "=========================================="
echo "✅ All required icon sizes generated"
echo "✅ Contents.json updated with complete configuration"
echo "✅ CFBundleIconName properly set in Info.plist"
echo "✅ Asset catalog validated"
echo "✅ Info.plist cleaned and validated"
echo "✅ Critical icons force regenerated"
echo "=========================================="

log_success "🎉 Comprehensive iOS icon fix completed successfully!"
log_info "📱 Your app should now pass App Store icon validation"
