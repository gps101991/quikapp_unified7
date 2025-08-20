#!/usr/bin/env bash

# Fix Firebase Workflow Order Script
# Updates the main iOS workflow to include Firebase setup in the correct order

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}ℹ️ $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️ $1${NC}"; }

echo "🔧 Fixing Firebase Workflow Order in iOS Workflow..."

# Check if main workflow script exists
MAIN_WORKFLOW="lib/scripts/ios-workflow/main_workflow.sh"
if [ ! -f "$MAIN_WORKFLOW" ]; then
    log_error "Main workflow script not found: $MAIN_WORKFLOW"
    exit 1
fi

# Create backup
BACKUP_FILE="${MAIN_WORKFLOW}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$MAIN_WORKFLOW" "$BACKUP_FILE"
log_success "Created backup: $BACKUP_FILE"

# Check if Firebase setup is already integrated
if grep -q "Step 6: Firebase Setup" "$MAIN_WORKFLOW"; then
    log_warning "Firebase setup already appears to be integrated in the workflow"
    log_info "Current workflow structure:"
    grep -n "Step [0-9]*:" "$MAIN_WORKFLOW" || true
    exit 0
fi

# Find the line number where environment configuration generation ends
ENV_CONFIG_END=$(grep -n "Environment configuration generated successfully" "$MAIN_WORKFLOW" | head -1 | cut -d: -f1)
if [ -z "$ENV_CONFIG_END" ]; then
    log_error "Could not find environment configuration generation end point"
    exit 1
fi

log_info "Found environment configuration end at line: $ENV_CONFIG_END"

# Find the line number where Podfile generation starts
PODFILE_START=$(grep -n "Step [0-9]*: Generating Podfile dynamically" "$MAIN_WORKFLOW" | head -1 | cut -d: -f1)
if [ -z "$PODFILE_START" ]; then
    log_error "Could not find Podfile generation start point"
    exit 1
fi

log_info "Found Podfile generation start at line: $PODFILE_START"

# Create temporary file for the updated workflow
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

# Copy content up to environment configuration end
head -n "$ENV_CONFIG_END" "$MAIN_WORKFLOW" > "$TEMP_FILE"

# Add Firebase setup step
cat >> "$TEMP_FILE" << 'EOF'

# Step 6: Firebase Setup (CRITICAL: Must be before CocoaPods)
echo "🔥 Step 6: Firebase Setup and Configuration..."
if [ -f "lib/scripts/ios/firebase.sh" ]; then
    chmod +x lib/scripts/ios/firebase.sh
    if ./lib/scripts/ios/firebase.sh; then
        log_success "✅ Firebase setup completed successfully"
    else
        log_error "❌ Firebase setup failed"
        exit 1
    fi
else
    log_warning "⚠️ Firebase setup script not found, skipping Firebase configuration"
fi

EOF

# Copy content from Podfile generation start to end
tail -n +"$PODFILE_START" "$MAIN_WORKFLOW" >> "$TEMP_FILE"

# Update the main workflow file
cp "$TEMP_FILE" "$MAIN_WORKFLOW"
log_success "Updated main workflow script with Firebase setup"

# Update step numbers in the remaining content
log_info "Updating step numbers in the workflow..."

# Function to update step numbers
update_step_numbers() {
    local file="$1"
    local current_step=7  # Start from step 7 after adding Firebase
    
    # Find all step lines and update them
    while IFS= read -r line; do
        if [[ "$line" =~ ^#\ Step\ ([0-9]+): ]]; then
            echo "# Step $current_step: ${line#*: }"
            ((current_step++))
        else
            echo "$line"
        fi
    done < "$file" > "${file}.tmp"
    
    mv "${file}.tmp" "$file"
}

# Update step numbers in the main workflow
update_step_numbers "$MAIN_WORKFLOW"
log_success "Updated step numbers in the workflow"

# Verify the changes
log_info "Verifying the updated workflow structure..."
if grep -q "Step 6: Firebase Setup" "$MAIN_WORKFLOW"; then
    log_success "✅ Firebase setup successfully integrated at Step 6"
else
    log_error "❌ Failed to integrate Firebase setup"
    exit 1
fi

# Show the updated workflow structure
log_info "Updated workflow structure:"
grep -n "Step [0-9]*:" "$MAIN_WORKFLOW" || true

# Check if Firebase script exists
if [ -f "lib/scripts/ios/firebase.sh" ]; then
    log_success "✅ Firebase setup script found: lib/scripts/ios/firebase.sh"
else
    log_warning "⚠️ Firebase setup script not found: lib/scripts/ios/firebase.sh"
    log_info "You may need to create this script or ensure it's in the correct location"
fi

# Summary
echo ""
log_success "🎉 Firebase Workflow Order Fix Completed!"
echo ""
echo "📋 Summary of Changes:"
echo "  ✅ Added Firebase Setup at Step 6 (before CocoaPods)"
echo "  ✅ Updated all subsequent step numbers"
echo "  ✅ Created backup of original workflow"
echo "  ✅ Verified Firebase integration"
echo ""
echo "🚀 Next Steps:"
echo "  1. Test the updated workflow in Codemagic"
echo "  2. Verify Firebase setup completes before CocoaPods"
echo "  3. Confirm build includes Firebase functionality"
echo "  4. Check build logs for proper Firebase integration"
echo ""
echo "📁 Files Modified:"
echo "  - $MAIN_WORKFLOW (updated with Firebase setup)"
echo "  - $BACKUP_FILE (backup of original)"
echo ""
echo "🔧 Firebase Setup Requirements:"
echo "  - PUSH_NOTIFY=true to enable Firebase"
echo "  - FIREBASE_CONFIG_IOS=<URL> for configuration"
echo "  - lib/scripts/ios/firebase.sh script must exist"

exit 0

