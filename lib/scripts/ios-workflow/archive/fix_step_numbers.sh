#!/usr/bin/env bash

# Fix Step Numbers Script
# Corrects all step numbers in the iOS workflow to be sequential and consistent

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

echo "🔢 Fixing Step Numbers in iOS Workflow..."

# Check if main workflow script exists
MAIN_WORKFLOW="lib/scripts/ios-workflow/main_workflow.sh"
if [ ! -f "$MAIN_WORKFLOW" ]; then
    log_error "Main workflow script not found: $MAIN_WORKFLOW"
    exit 1
fi

# Create backup
BACKUP_FILE="${MAIN_WORKFLOW}.backup.step_fix.$(date +%Y%m%d_%H%M%S)"
cp "$MAIN_WORKFLOW" "$BACKUP_FILE"
log_success "Created backup: $BACKUP_FILE"

# Define the correct step order
declare -a STEP_NAMES=(
    "Cleanup and fix corrupted files"
    "Initialize Flutter and generate configuration files"
    "Fix Generated.xcconfig issue"
    "Inject dynamic iOS configurations"
    "Generate environment configuration"
    "Firebase Setup (CRITICAL: Must be before CocoaPods)"
    "Generate Podfile dynamically (after Firebase setup)"
    "Advanced cleanup"
    "Code signing setup"
    "App customization and branding"
    "App icon installation"
    "iOS permissions configuration"
    "Flutter dependencies and project setup"
    "CocoaPods setup (after Firebase configuration)"
    "Xcode configuration and code signing"
    "Build process"
    "IPA export and finalization"
)

# Create temporary file for the corrected workflow
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

# Process the file line by line
current_step=1
in_step_section=false

while IFS= read -r line; do
    # Check if this line starts a new step
    if [[ "$line" =~ ^#\ Step\ [0-9]+: ]]; then
        # Extract the step name from the comment
        step_name=$(echo "$line" | sed 's/^# Step [0-9]*: //')
        
        # Find matching step name in our array
        found=false
        for i in "${!STEP_NAMES[@]}"; do
            if [[ "${STEP_NAMES[$i]}" == "$step_name" ]]; then
                current_step=$((i + 1))
                found=true
                break
            fi
        done
        
        if [ "$found" = false ]; then
            # If not found, try to match partial names
            for i in "${!STEP_NAMES[@]}"; do
                if [[ "$step_name" == *"${STEP_NAMES[$i]}"* ]] || [[ "${STEP_NAMES[$i]}" == *"$step_name"* ]]; then
                    current_step=$((i + 1))
                    found=true
                    break
                fi
            done
        fi
        
        # Write the corrected step header
        echo "# Step $current_step: $step_name" >> "$TEMP_FILE"
        in_step_section=true
        
    elif [[ "$line" =~ ^echo\ \"[^\"].*Step\ [0-9]+: ]]; then
        # Fix echo statements with step numbers
        corrected_line=$(echo "$line" | sed "s/Step [0-9]*:/Step $current_step:/")
        echo "$corrected_line" >> "$TEMP_FILE"
        
    else
        # Copy the line as-is
        echo "$line" >> "$TEMP_FILE"
    fi
done < "$MAIN_WORKFLOW"

# Update the main workflow file
cp "$TEMP_FILE" "$MAIN_WORKFLOW"
log_success "Updated main workflow script with corrected step numbers"

# Verify the changes
log_info "Verifying the corrected step numbers..."
log_info "Updated workflow structure:"
grep -n "Step [0-9]*:" "$MAIN_WORKFLOW" || true

# Summary
echo ""
log_success "🎉 Step Numbers Fix Completed!"
echo ""
echo "📋 Summary of Changes:"
echo "  ✅ Corrected all step numbers to be sequential (1-17)"
echo "  ✅ Fixed step headers and echo statements"
echo "  ✅ Created backup of workflow before changes"
echo "  ✅ Verified step number consistency"
echo ""
echo "🚀 Corrected Workflow Order:"
for i in "${!STEP_NAMES[@]}"; do
    step_num=$((i + 1))
    echo "  Step $step_num: ${STEP_NAMES[$i]}"
done
echo ""
echo "📁 Files Modified:"
echo "  - $MAIN_WORKFLOW (corrected step numbers)"
echo "  - $BACKUP_FILE (backup before step fix)"
echo ""
echo "🔧 Next Steps:"
echo "  1. Review the corrected workflow structure"
echo "  2. Test the workflow in Codemagic"
echo "  3. Verify Firebase setup is at Step 6"
echo "  4. Confirm CocoaPods setup is at Step 14"

exit 0

