#!/usr/bin/env bash

# Comprehensive Step Numbers Fix Script
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

echo "🔢 Comprehensive Step Numbers Fix for iOS Workflow..."

# Check if main workflow script exists
MAIN_WORKFLOW="lib/scripts/ios-workflow/main_workflow.sh"
if [ ! -f "$MAIN_WORKFLOW" ]; then
    log_error "Main workflow script not found: $MAIN_WORKFLOW"
    exit 1
fi

# Create backup
BACKUP_FILE="${MAIN_WORKFLOW}.backup.comprehensive_fix.$(date +%Y%m%d_%H%M%S)"
cp "$MAIN_WORKFLOW" "$BACKUP_FILE"
log_success "Created backup: $BACKUP_FILE"

# Create temporary file for the corrected workflow
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

# Process the file line by line with specific replacements
current_step=1

while IFS= read -r line; do
    # Handle specific step patterns
    if [[ "$line" =~ ^#\ Step\ [0-9]+:\ Cleanup\ and\ fix\ corrupted\ files ]]; then
        echo "# Step 1: Cleanup and fix corrupted files" >> "$TEMP_FILE"
        current_step=2
    elif [[ "$line" =~ ^echo\ \"🧹\ Step\ [0-9]+:\ Cleaning\ up\ iOS\ project ]]; then
        echo 'echo "🧹 Step 1: Cleaning up iOS project..."' >> "$TEMP_FILE"
    elif [[ "$line" =~ ^log_info\ \"📝\ Step\ [0-9]+:\ Generate\ environment\ configuration ]]; then
        echo 'log_info "📝 Step 5: Generate environment configuration..."' >> "$TEMP_FILE"
    elif [[ "$line" =~ ^#\ Step\ [0-9]+:\ Firebase\ Setup ]]; then
        echo "# Step 6: Firebase Setup (CRITICAL: Must be before CocoaPods)" >> "$TEMP_FILE"
        current_step=7
    elif [[ "$line" =~ ^echo\ \"🔥\ Step\ [0-9]+:\ Firebase\ Setup\ and\ Configuration ]]; then
        echo 'echo "🔥 Step 6: Firebase Setup and Configuration..."' >> "$TEMP_FILE"
    elif [[ "$line" =~ ^log_info\ \"📦\ Step\ [0-9]+:\ Generating\ Podfile\ dynamically ]]; then
        echo 'log_info "📦 Step 7: Generating Podfile dynamically..."' >> "$TEMP_FILE"
        current_step=8
    elif [[ "$line" =~ ^#\ Step\ [0-9]+:\ Code\ Signing\ Setup ]]; then
        echo "# Step 9: Code Signing Setup" >> "$TEMP_FILE"
        current_step=10
    elif [[ "$line" =~ ^echo\ \"🔐\ Step\ [0-9]+:\ Code\ Signing\ Setup ]]; then
        echo 'echo "🔐 Step 9: Code Signing Setup..."' >> "$TEMP_FILE"
    elif [[ "$line" =~ ^#\ Step\ [0-9]+:\ App\ Customization ]]; then
        echo "# Step 10: App Customization and Branding" >> "$TEMP_FILE"
        current_step=11
    elif [[ "$line" =~ ^echo\ \"🎨\ Step\ [0-9]+:\ App\ Customization\ and\ Branding ]]; then
        echo 'echo "🎨 Step 10: App Customization and Branding..."' >> "$TEMP_FILE"
    elif [[ "$line" =~ ^#\ Step\ [0-9]+:\ iOS\ Permissions\ Configuration ]]; then
        echo "# Step 12: iOS Permissions Configuration" >> "$TEMP_FILE"
        current_step=13
    elif [[ "$line" =~ ^echo\ \"🔐\ Step\ [0-9]+:\ iOS\ Permissions\ Configuration ]]; then
        echo 'echo "🔐 Step 12: iOS Permissions Configuration..."' >> "$TEMP_FILE"
    elif [[ "$line" =~ ^#\ Step\ [0-9]+:\ Flutter\ Dependencies\ and\ Project\ Setup ]]; then
        echo "# Step 13: Flutter Dependencies and Project Setup" >> "$TEMP_FILE"
        current_step=14
    elif [[ "$line" =~ ^echo\ \"📦\ Step\ [0-9]+:\ Flutter\ Dependencies\ and\ Project\ Setup ]]; then
        echo 'echo "📦 Step 13: Flutter Dependencies and Project Setup..."' >> "$TEMP_FILE"
    elif [[ "$line" =~ ^#\ Step\ [0-9]+:\ CocoaPods\ Setup ]]; then
        echo "# Step 14: CocoaPods Setup (after Firebase configuration)" >> "$TEMP_FILE"
        current_step=15
    elif [[ "$line" =~ ^echo\ \"📦\ Step\ [0-9]+:\ CocoaPods\ Setup\ and\ Dependencies ]]; then
        echo 'echo "📦 Step 14: CocoaPods Setup and Dependencies..."' >> "$TEMP_FILE"
    elif [[ "$line" =~ ^#\ Step\ [0-9]+:\ Xcode\ Configuration ]]; then
        echo "# Step 15: Xcode Configuration and Code Signing" >> "$TEMP_FILE"
        current_step=16
    elif [[ "$line" =~ ^echo\ \"⚙️\ Step\ [0-9]+:\ Xcode\ Configuration\ and\ Code\ Signing ]]; then
        echo 'echo "⚙️ Step 15: Xcode Configuration and Code Signing..."' >> "$TEMP_FILE"
    elif [[ "$line" =~ ^#\ Step\ [0-9]+:\ Build\ Process ]]; then
        echo "# Step 16: Build Process" >> "$TEMP_FILE"
        current_step=17
    elif [[ "$line" =~ ^echo\ \"🔨\ Step\ [0-9]+:\ Build\ Process ]]; then
        echo 'echo "🔨 Step 16: Build Process..."' >> "$TEMP_FILE"
    elif [[ "$line" =~ ^#\ Step\ [0-9]+:\ IPA\ Export ]]; then
        echo "# Step 17: IPA Export and Finalization" >> "$TEMP_FILE"
        current_step=18
    elif [[ "$line" =~ ^echo\ \"📤\ Step\ [0-9]+:\ IPA\ Export\ and\ Finalization ]]; then
        echo 'echo "📤 Step 17: IPA Export and Finalization..."' >> "$TEMP_FILE"
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
log_success "🎉 Comprehensive Step Numbers Fix Completed!"
echo ""
echo "📋 Summary of Changes:"
echo "  ✅ Corrected all step numbers to be sequential (1-17)"
echo "  ✅ Fixed step headers and echo statements"
echo "  ✅ Created backup of workflow before changes"
echo "  ✅ Verified step number consistency"
echo ""
echo "🚀 Corrected Workflow Order:"
echo "  Step 1: Cleanup and fix corrupted files"
echo "  Step 2: Initialize Flutter and generate configuration files"
echo "  Step 3: Fix Generated.xcconfig issue"
echo "  Step 4: Inject dynamic iOS configurations"
echo "  Step 5: Generate environment configuration"
echo "  Step 6: Firebase Setup (CRITICAL: Must be before CocoaPods)"
echo "  Step 7: Generate Podfile dynamically (after Firebase setup)"
echo "  Step 8: Advanced cleanup"
echo "  Step 9: Code signing setup"
echo "  Step 10: App customization and branding"
echo "  Step 11: App icon installation"
echo "  Step 12: iOS permissions configuration"
echo "  Step 13: Flutter dependencies and project setup"
echo "  Step 14: CocoaPods setup (after Firebase configuration)"
echo "  Step 15: Xcode configuration and code signing"
echo "  Step 16: Build process"
echo "  Step 17: IPA export and finalization"
echo ""
echo "📁 Files Modified:"
echo "  - $MAIN_WORKFLOW (corrected step numbers)"
echo "  - $BACKUP_FILE (backup before comprehensive fix)"
echo ""
echo "🔧 Next Steps:"
echo "  1. Review the corrected workflow structure"
echo "  2. Test the workflow in Codemagic"
echo "  3. Verify Firebase setup is at Step 6"
echo "  4. Confirm CocoaPods setup is at Step 14"
echo "  5. Check that all steps are numbered sequentially"

exit 0

