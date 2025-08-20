#!/bin/bash

# Download Custom Icons Script for QuikApp
# This script downloads custom SVG icons from BOTTOMMENU_ITEMS and saves them to assets/icons/

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to validate and fix JSON
validate_and_fix_json() {
    local json_string="$1"
    
    # Check if the string is empty or just whitespace
    if [ -z "$json_string" ] || [ "$json_string" = "[]" ]; then
        echo "[]"
        return 0
    fi
    
    # Try to parse the JSON first
    if python3 -c "import json; json.loads('$json_string')" 2>/dev/null; then
        echo "$json_string"
        return 0
    fi
    
    # If parsing fails, try to fix common issues
    warning "JSON parsing failed, attempting to fix common issues..."
    
    # Try to fix missing quotes around keys
    local fixed_json=$(echo "$json_string" | sed 's/\([a-zA-Z_][a-zA-Z0-9_]*\):/"\1":/g')
    
    # Try parsing the fixed JSON
    if python3 -c "import json; json.loads('$fixed_json')" 2>/dev/null; then
        success "JSON fixed successfully"
        echo "$fixed_json"
        return 0
    fi
    
    # If still fails, return empty array
    warning "Could not fix JSON, using empty array"
    echo "[]"
    return 0
}

# Function to download custom icons
download_custom_icons() {
    local bottom_menu_items="$1"
    
    if [ -z "$bottom_menu_items" ]; then
        log "No BOTTOMMENU_ITEMS provided, skipping custom icon download"
        return 0
    fi
    
    log "Processing BOTTOMMENU_ITEMS for custom icons..."
    
    # Validate and fix JSON if needed
    local valid_json=$(validate_and_fix_json "$bottom_menu_items")
    
    # Create assets/icons directory if it doesn't exist
    mkdir -p assets/icons
    
    # Use Python to parse JSON and download icons
    if ! python3 -c "
import json
import os
import requests
import sys
from urllib.parse import urlparse

try:
    # Parse the validated JSON string
    menu_items = json.loads('$valid_json')
    
    if not isinstance(menu_items, list):
        print('BOTTOMMENU_ITEMS is not a valid JSON array')
        sys.exit(1)
    
    downloaded_count = 0
    
    for item in menu_items:
        if not isinstance(item, dict):
            continue
            
        icon_data = item.get('icon')
        label = item.get('label', 'unknown')
        
        # Skip if icon is not a custom type
        if not isinstance(icon_data, dict) or icon_data.get('type') != 'custom':
            continue
            
        icon_url = icon_data.get('icon_url')
        if not icon_url:
            continue
            
        # Sanitize label for filename
        label_sanitized = label.lower().replace(' ', '_').replace('-', '_')
        filename = f'{label_sanitized}.svg'
        filepath = f'assets/icons/{filename}'
        
        # Download icon if it doesn't exist or if forced
        if not os.path.exists(filepath):
            try:
                print(f'Downloading {label} icon from {icon_url}...')
                response = requests.get(icon_url, timeout=30)
                response.raise_for_status()
                
                with open(filepath, 'wb') as f:
                    f.write(response.content)
                
                print(f'✓ Downloaded {filename}')
                downloaded_count += 1
                
            except requests.exceptions.RequestException as e:
                print(f'✗ Failed to download {label} icon: {e}')
                continue
        else:
            print(f'✓ {filename} already exists')
            downloaded_count += 1
    
    print(f'Total icons processed: {downloaded_count}')
    
except json.JSONDecodeError as e:
    print(f'JSON parsing error: {e}')
    print(f'Original string: {repr('$bottom_menu_items')}')
    print(f'Fixed string: {repr('$valid_json')}')
    print('Continuing without custom icons...')
    sys.exit(0)  # Exit with success to not break the build
except Exception as e:
    print(f'Error processing BOTTOMMENU_ITEMS: {e}')
    print('Continuing without custom icons...')
    sys.exit(0)  # Exit with success to not break the build
"; then
        warning "Python script execution failed, but continuing..."
    fi
    
    success "Custom icons download completed successfully"
}

# Main execution
main() {
    log "Starting custom icons download process..."
    
    # Get BOTTOMMENU_ITEMS from environment
    local bottom_menu_items="${BOTTOMMENU_ITEMS:-[]}"
    
    # Download custom icons
    download_custom_icons "$bottom_menu_items"
    
    success "Custom icons download process completed"
}

# Run main function
main "$@" 