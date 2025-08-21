#!/bin/bash
# 🎨 Setup iOS App Icons Script
# Uses Flutter Launcher Icons as primary method, manual generation as fallback

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IOS_ICONS] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

log_info "Starting iOS app icon setup process..."

# Check if logo exists
LOGO_PATH="assets/images/logo.png"
if [[ ! -f "$LOGO_PATH" ]] || [[ ! -s "$LOGO_PATH" ]]; then
    log_error "Logo file not found or empty: $LOGO_PATH"
    log_error "Please run download_and_setup_logo.sh first"
    exit 1
fi

log_success "Logo found: $LOGO_PATH"

# Step 1: Try Flutter Launcher Icons (Primary Method)
log_info "Step 1: Attempting to generate icons using Flutter Launcher Icons..."

if command -v flutter > /dev/null 2>&1; then
    log_info "Flutter is available, checking Flutter Launcher Icons..."
    
    # Check if flutter_launcher_icons is available
    if flutter pub deps | grep -q "flutter_launcher_icons"; then
        log_success "Flutter Launcher Icons package is available"
        
        # Check if configuration file exists
        if [[ -f "flutter_launcher_icons.yaml" ]]; then
            log_info "Flutter Launcher Icons configuration found"
            
            # Generate icons using Flutter Launcher Icons
            log_info "Generating iOS app icons using Flutter Launcher Icons..."
            
            # Ensure Flutter Launcher Icons generates icons without alpha channels
            log_info "Generating iOS app icons using Flutter Launcher Icons (no alpha channels)..."
            
            if flutter pub get && flutter pub run flutter_launcher_icons:main -f flutter_launcher_icons.yaml --remove-alpha-ios; then
                log_success "✅ iOS app icons generated successfully using Flutter Launcher Icons!"
                
                # Verify that icons were generated
                ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
                if [[ -d "$ICON_DIR" ]]; then
                    ICON_COUNT=$(find "$ICON_DIR" -name "*.png" | wc -l)
                    log_info "Generated $ICON_COUNT icon files in $ICON_DIR"
                    
                    # Check for critical icons
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
                        if [[ ! -f "$ICON_DIR/$icon" ]]; then
                            MISSING_CRITICAL+=("$icon ($size)")
                        fi
                    done
                    
                    if [[ ${#MISSING_CRITICAL[@]} -eq 0 ]]; then
                        log_success "✅ All critical iOS app icons are present"
                        log_success "✅ Flutter Launcher Icons method completed successfully"
                        
                        # Update Contents.json to ensure proper configuration
                        log_info "Updating Contents.json for proper iOS configuration..."
                        if [[ -f "lib/scripts/ios-workflow/fix_corrupted_contents_json.sh" ]]; then
                            chmod +x lib/scripts/ios-workflow/fix_corrupted_contents_json.sh
                            if ./lib/scripts/ios-workflow/fix_corrupted_contents_json.sh; then
                                log_success "✅ Contents.json updated successfully"
                            else
                                log_warning "⚠️ Contents.json update failed, but icons are present"
                            fi
                        fi
                        
                        # Exit successfully
                        log_success "🎉 iOS app icon setup completed successfully using Flutter Launcher Icons!"
                        exit 0
                    else
                        log_warning "⚠️ Some critical icons are missing:"
                        for icon in "${MISSING_CRITICAL[@]}"; do
                            log_warning "  - $icon"
                        done
                        log_warning "⚠️ Falling back to manual icon generation..."
                    fi
                else
                    log_warning "⚠️ Icon directory not found, falling back to manual generation..."
                fi
            else
                log_warning "⚠️ Flutter Launcher Icons failed, falling back to manual generation..."
            fi
        else
            log_warning "⚠️ Flutter Launcher Icons configuration not found, falling back to manual generation..."
        fi
    else
        log_warning "⚠️ Flutter Launcher Icons package not available, falling back to manual generation..."
    fi
else
    log_warning "⚠️ Flutter not available, falling back to manual generation..."
fi

# Step 2: Manual Icon Generation (Fallback Method)
log_info "Step 2: Using manual icon generation as fallback..."

# Check if our robust icon fix script exists
if [[ -f "lib/scripts/ios-workflow/fix_ios_icons_robust.sh" ]]; then
    log_info "Manual icon generation script found"
    chmod +x lib/scripts/ios-workflow/fix_ios_icons_robust.sh
    
    log_info "Running manual iOS icon generation..."
    if ./lib/scripts/ios-workflow/fix_ios_icons_robust.sh; then
        log_success "✅ Manual iOS icon generation completed successfully!"
        
        # Verify the results
        ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
        if [[ -d "$ICON_DIR" ]]; then
            ICON_COUNT=$(find "$ICON_DIR" -name "*.png" | wc -l)
            log_info "Generated $ICON_COUNT icon files in $ICON_DIR"
            
            # Final verification
            log_info "Performing final verification..."
            if [[ -f "$ICON_DIR/Icon-App-1024x1024@1x.png" ]]; then
                log_success "✅ 1024x1024 icon is present (critical for App Store Connect)"
                log_success "✅ Manual icon generation method completed successfully"
                log_success "🎉 iOS app icon setup completed successfully using manual generation!"
                exit 0
            else
                log_error "❌ 1024x1024 icon is still missing after manual generation"
                exit 1
            fi
        else
            log_error "❌ Icon directory not found after manual generation"
            exit 1
        fi
    else
        log_error "❌ Manual iOS icon generation failed"
        exit 1
    fi
else
    log_error "❌ Manual icon generation script not found: lib/scripts/ios-workflow/fix_ios_icons_robust.sh"
    exit 1
fi
