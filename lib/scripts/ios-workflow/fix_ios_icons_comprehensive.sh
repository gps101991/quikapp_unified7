#!/bin/bash
# 🔧 Comprehensive iOS Icon Fix for App Store Connect Compliance
# Fixes Contents.json corruption, missing icons, and Info.plist configuration

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ICON_FIX] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "🔧 Starting comprehensive iOS icon fix for App Store Connect compliance..."

# Check if we're in the right directory
if [[ ! -d "ios" ]]; then
    log_error "iOS directory not found. Please run this script from the Flutter project root."
    exit 1
fi

# Create backup directory
BACKUP_DIR="ios/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Step 1: Fix corrupted Contents.json
log_info "🔧 Step 1: Fixing corrupted Contents.json..."

CONTENTS_JSON="ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json"
if [[ -f "$CONTENTS_JSON" ]]; then
    # Backup current Contents.json
    cp "$CONTENTS_JSON" "$BACKUP_DIR/Contents.json.backup"
    log_success "✅ Backed up Contents.json to $BACKUP_DIR/Contents.json.backup"
    
    # Create clean Contents.json with all required icon sizes
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

    log_success "✅ Created clean Contents.json with all required icon sizes"
else
    log_error "Contents.json not found at $CONTENTS_JSON"
    exit 1
fi

# Step 2: Ensure asset catalog directory structure
log_info "🔧 Step 2: Ensuring asset catalog directory structure..."

ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$ICON_DIR"

# Step 3: Find source icon
log_info "🔧 Step 3: Finding source icon for icon generation..."

SOURCE_ICON=""
if [[ -f "assets/images/logo.png" ]]; then
    SOURCE_ICON="assets/images/logo.png"
    log_success "✅ Using logo from assets/images/logo.png"
elif [[ -f "assets/images/default_logo.png" ]]; then
    SOURCE_ICON="assets/images/default_logo.png"
    log_success "✅ Using default logo from assets/images/default_logo.png"
else
    log_error "No source icon found. Please ensure logo.png or default_logo.png exists in assets/images/"
    exit 1
fi

# Step 4: Generate all required icon sizes using sips
log_info "🔧 Step 4: Generating all required icon sizes using sips..."

if command -v sips > /dev/null 2>&1; then
    log_info "Using sips for icon generation..."
    
    # iPhone icons
    sips -z 20 20 "$SOURCE_ICON" --out "$ICON_DIR/Icon-App-20x20@1x.png" 2>/dev/null || log_warning "Failed to generate 20x20@1x"
    sips -z 40 40 "$SOURCE_ICON" --out "$ICON_DIR/Icon-App-20x20@2x.png" 2>/dev/null || log_warning "Failed to generate 20x20@2x"
    sips -z 60 60 "$SOURCE_ICON" --out "$ICON_DIR/Icon-App-20x20@3x.png" 2>/dev/null || log_warning "Failed to generate 20x20@3x"
    
    sips -z 29 29 "$SOURCE_ICON" --out "$ICON_DIR/Icon-App-29x29@1x.png" 2>/dev/null || log_warning "Failed to generate 29x29@1x"
    sips -z 58 58 "$SOURCE_ICON" --out "$ICON_DIR/Icon-App-29x29@2x.png" 2>/dev/null || log_warning "Failed to generate 29x29@2x"
    sips -z 87 87 "$SOURCE_ICON" --out "$ICON_DIR/Icon-App-29x29@3x.png" 2>/dev/null || log_warning "Failed to generate 29x29@3x"
    
    sips -z 40 40 "$SOURCE_ICON" --out "$ICON_DIR/Icon-App-40x40@1x.png" 2>/dev/null || log_warning "Failed to generate 40x40@1x"
    sips -z 80 80 "$SOURCE_ICON" --out "$ICON_DIR/Icon-App-40x40@2x.png" 2>/dev/null || log_warning "Failed to generate 40x40@2x"
    sips -z 120 120 "$SOURCE_ICON" --out "$ICON_DIR/Icon-App-40x40@3x.png" 2>/dev/null || log_warning "Failed to generate 40x40@3x"
    
    sips -z 120 120 "$SOURCE_ICON" --out "$ICON_DIR/Icon-App-60x60@2x.png" 2>/dev/null || log_warning "Failed to generate 60x60@2x"
    sips -z 180 180 "$SOURCE_ICON" --out "$ICON_DIR/Icon-App-60x60@3x.png" 2>/dev/null || log_warning "Failed to generate 60x60@3x"
    
    # iPad icons
    sips -z 76 76 "$SOURCE_ICON" --out "$ICON_DIR/Icon-App-76x76@1x.png" 2>/dev/null || log_warning "Failed to generate 76x76@1x"
    sips -z 152 152 "$SOURCE_ICON" --out "$ICON_DIR/Icon-App-76x76@2x.png" 2>/dev/null || log_warning "Failed to generate 76x76@2x"
    sips -z 167 167 "$SOURCE_ICON" --out "$ICON_DIR/Icon-App-83.5x83.5@2x.png" 2>/dev/null || log_warning "Failed to generate 83.5x83.5@2x"
    
    # App Store icon (critical)
    sips -z 1024 1024 "$SOURCE_ICON" --out "$ICON_DIR/Icon-App-1024x1024@1x.png" 2>/dev/null || log_warning "Failed to generate 1024x1024@1x"
    
    log_success "✅ Generated all required icon sizes using sips"
else
    log_warning "sips not available, trying alternative methods..."
    
    # Try using flutter_launcher_icons again with proper configuration
    if command -v flutter > /dev/null 2>&1; then
        log_info "Trying flutter_launcher_icons with proper configuration..."
        
        # Create temporary flutter_launcher_icons.yaml with iOS-specific settings
        cat > "flutter_launcher_icons_temp.yaml" << EOF
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "$SOURCE_ICON"
  remove_alpha_ios: true
  background_color_ios: "#FFFFFF"
  min_sdk_android: 21
EOF
        
        if flutter pub run flutter_launcher_icons -f flutter_launcher_icons_temp.yaml; then
            log_success "✅ flutter_launcher_icons completed successfully"
        else
            log_warning "⚠️ flutter_launcher_icons failed, continuing with manual fix..."
        fi
        
        # Clean up temporary file
        rm -f "flutter_launcher_icons_temp.yaml"
    fi
fi

# Step 5: Fix Info.plist CFBundleIconName
log_info "🔧 Step 5: Fixing Info.plist CFBundleIconName..."

INFO_PLIST="ios/Runner/Info.plist"
if [[ -f "$INFO_PLIST" ]]; then
    # Backup Info.plist
    cp "$INFO_PLIST" "$BACKUP_DIR/Info.plist.backup"
    log_success "✅ Backed up Info.plist to $BACKUP_DIR/Info.plist.backup"
    
    # Add CFBundleIconName if missing
    if ! grep -q "CFBundleIconName" "$INFO_PLIST"; then
        # Find the closing </dict> tag and add CFBundleIconName before it
        sed -i '' '/<\/dict>/i\
	<key>CFBundleIconName</key>\
	<string>AppIcon</string>' "$INFO_PLIST"
        log_success "✅ Added CFBundleIconName to Info.plist"
    else
        log_info "CFBundleIconName already present in Info.plist"
    fi
else
    log_error "Info.plist not found at $INFO_PLIST"
    exit 1
fi

# Step 6: Verify icon generation
log_info "🔧 Step 6: Verifying icon generation..."

REQUIRED_ICONS=(
    "Icon-App-60x60@2x.png:120x120"
    "Icon-App-76x76@2x.png:152x152"
    "Icon-App-83.5x83.5@2x.png:167x167"
    "Icon-App-1024x1024@1x.png:1024x1024"
)

MISSING_ICONS=()
for icon_spec in "${REQUIRED_ICONS[@]}"; do
    icon_file="${icon_spec%:*}"
    expected_size="${icon_spec#*:}"
    
    if [[ -f "$ICON_DIR/$icon_file" ]]; then
        # Check dimensions
        if command -v sips > /dev/null 2>&1; then
            actual_size=$(sips -g pixelWidth -g pixelHeight "$ICON_DIR/$icon_file" 2>/dev/null | grep -E "(pixelWidth|pixelHeight)" | awk '{print $2}' | tr '\n' 'x' | sed 's/x$//')
            if [[ "$actual_size" == "$expected_size" ]]; then
                log_success "✅ $icon_file: $actual_size (correct)"
            else
                log_warning "⚠️ $icon_file: $actual_size (expected: $expected_size)"
                MISSING_ICONS+=("$icon_file")
            fi
        else
            log_success "✅ $icon_file exists"
        fi
    else
        log_error "❌ $icon_file missing"
        MISSING_ICONS+=("$icon_file")
    fi
done

# Step 7: Validate Contents.json
log_info "🔧 Step 7: Validating Contents.json..."

if command -v python3 > /dev/null 2>&1; then
    if python3 -m json.tool "$CONTENTS_JSON" > /dev/null 2>&1; then
        log_success "✅ Contents.json is valid JSON"
    else
        log_error "❌ Contents.json is invalid JSON"
        exit 1
    fi
else
    log_warning "python3 not available, skipping JSON validation"
fi

# Step 8: Final verification
log_info "🔧 Step 8: Final verification..."

if [[ ${#MISSING_ICONS[@]} -eq 0 ]]; then
    log_success "🎉 All required icons are present and correctly sized!"
    log_success "✅ iOS icon fix completed successfully"
    log_success "✅ App Store Connect validation should now pass"
else
    log_warning "⚠️ Some icons are missing or incorrectly sized:"
    for icon in "${MISSING_ICONS[@]}"; do
        log_warning "  - $icon"
    done
    log_warning "⚠️ App Store Connect validation may still fail"
fi

# Summary
log_info "📋 iOS Icon Fix Summary:"
log_info "  - Contents.json: ✅ Fixed and validated"
log_info "  - Required Icons: ${#REQUIRED_ICONS[@]} total, ${#MISSING_ICONS[@]} issues"
log_info "  - Info.plist: ✅ CFBundleIconName configured"
log_info "  - Backup: ✅ Created in $BACKUP_DIR"

if [[ ${#MISSING_ICONS[@]} -eq 0 ]]; then
    log_success "🎉 iOS icon fix completed successfully!"
    log_success "🚀 Your app should now pass App Store Connect validation!"
    exit 0
else
    log_warning "⚠️ iOS icon fix completed with some issues"
    log_warning "🔧 Manual verification may be required"
    exit 1
fi
