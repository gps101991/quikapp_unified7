#!/bin/bash

# =============================================================================
# Common Utilities for QuikApp Build Scripts
# =============================================================================
# Provides shared functions for logging, error handling, and common operations

set -e

# =============================================================================
# Logging Functions
# =============================================================================

log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1"
}

log_success() {
    log "✅ $1"
}

log_warning() {
    log "⚠️ $1"
}

log_error() {
    log "❌ $1"
}

log_info() {
    log "ℹ️ $1"
}

log_debug() {
    log "🔍 $1"
}

# =============================================================================
# Error Handling Functions
# =============================================================================

handle_error() {
    local error_message="$1"
    local exit_code="${2:-1}"
    
    log_error "$error_message"
    log_error "Script failed with exit code: $exit_code"
    
    # Send error notification if available
    if command -v send_error_notification >/dev/null 2>&1; then
        send_error_notification "$error_message"
    fi
    
    exit "$exit_code"
}

handle_warning() {
    local warning_message="$1"
    log_warning "$warning_message"
}

# =============================================================================
# Validation Functions
# =============================================================================

validate_var() {
    local var_name="$1"
    local var_value="$2"
    local required="${3:-true}"
    local description="${4:-$var_name}"
    
    if [ "$required" = "true" ] && [ -z "$var_value" ]; then
        handle_error "Required variable '$var_name' ($description) is not set"
    elif [ -z "$var_value" ]; then
        log_warning "Optional variable '$var_name' ($description) is not set"
    else
        log_debug "Variable '$var_name' is set: $var_value"
    fi
}

validate_file() {
    local file_path="$1"
    local description="${2:-File}"
    
    if [ ! -f "$file_path" ]; then
        handle_error "$description not found: $file_path"
    fi
    
    if [ ! -r "$file_path" ]; then
        handle_error "$description not readable: $file_path"
    fi
    
    log_debug "$description validated: $file_path"
}

validate_url() {
    local url="$1"
    local description="${2:-URL}"
    
    if [ -z "$url" ]; then
        log_warning "$description is empty"
        return 1
    fi
    
    # Basic URL validation
    if [[ ! "$url" =~ ^https?:// ]]; then
        log_warning "$description is not a valid HTTP/HTTPS URL: $url"
        return 1
    fi
    
    # Test if URL is accessible
    if ! curl --output /dev/null --silent --head --fail "$url" 2>/dev/null; then
        log_warning "$description is not accessible: $url"
        return 1
    fi
    
    log_debug "$description validated: $url"
    return 0
}

# =============================================================================
# File Operations
# =============================================================================

backup_file() {
    local file_path="$1"
    local backup_suffix="${2:-backup}"
    
    if [ -f "$file_path" ]; then
        local backup_path="${file_path}.${backup_suffix}.$(date +%Y%m%d_%H%M%S)"
        cp "$file_path" "$backup_path"
        log_debug "Backup created: $backup_path"
        echo "$backup_path"
    else
        log_warning "File not found for backup: $file_path"
        echo ""
    fi
}

restore_file() {
    local backup_path="$1"
    local target_path="$2"
    
    if [ -f "$backup_path" ]; then
        cp "$backup_path" "$target_path"
        log_debug "File restored from backup: $backup_path -> $target_path"
        return 0
    else
        log_error "Backup file not found: $backup_path"
        return 1
    fi
}

# =============================================================================
# Network Operations
# =============================================================================

download_file() {
    local url="$1"
    local target_path="$2"
    local description="${3:-File}"
    
    log_info "Downloading $description from: $url"
    
    # Create directory if it doesn't exist
    local target_dir=$(dirname "$target_path")
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir"
        log_debug "Created directory: $target_dir"
    fi
    
    # Download with retry logic
    local max_retries=3
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        if curl -L "$url" -o "$target_path" --silent --show-error; then
            log_success "$description downloaded successfully: $target_path"
            return 0
        else
            retry_count=$((retry_count + 1))
            log_warning "Download failed (attempt $retry_count/$max_retries)"
            
            if [ $retry_count -lt $max_retries ]; then
                local delay=$((retry_count * 2))
                log_info "Retrying in $delay seconds..."
                sleep $delay
            fi
        fi
    done
    
    handle_error "Failed to download $description after $max_retries attempts"
}

# =============================================================================
# System Information
# =============================================================================

get_system_info() {
    log_info "System Information:"
    log_info "  OS: $(uname -s)"
    log_info "  Architecture: $(uname -m)"
    log_info "  Kernel: $(uname -r)"
    
    if command -v java >/dev/null 2>&1; then
        log_info "  Java: $(java -version 2>&1 | head -1)"
    fi
    
    if command -v flutter >/dev/null 2>&1; then
        log_info "  Flutter: $(flutter --version | head -1)"
    fi
    
    if command -v gradle >/dev/null 2>&1; then
        log_info "  Gradle: $(gradle --version | head -1)"
    fi
}

check_disk_space() {
    local min_space_gb="${1:-1}"
    local available_space_gb=$(df . | awk 'NR==2 {print int($4/1024/1024)}')
    
    if [ "$available_space_gb" -lt "$min_space_gb" ]; then
        log_warning "Low disk space: ${available_space_gb}GB available, ${min_space_gb}GB required"
        return 1
    else
        log_debug "Disk space OK: ${available_space_gb}GB available"
        return 0
    fi
}

# =============================================================================
# Build Environment
# =============================================================================

setup_build_environment() {
    log_info "Setting up build environment..."
    
    # Check required tools
    local required_tools=("curl" "java" "flutter" "gradle")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            handle_error "Required tool not found: $tool"
        fi
    done
    
    # Check disk space
    check_disk_space 2
    
    # Get system info
    get_system_info
    
    log_success "Build environment setup completed"
}

# =============================================================================
# Cleanup Functions
# =============================================================================

cleanup_temp_files() {
    local temp_pattern="${1:-*.tmp}"
    local temp_files=$(find . -name "$temp_pattern" -type f 2>/dev/null || true)
    
    if [ -n "$temp_files" ]; then
        log_info "Cleaning up temporary files..."
        echo "$temp_files" | xargs rm -f
        log_success "Temporary files cleaned up"
    fi
}

cleanup_backups() {
    local backup_pattern="${1:-*.backup.*}"
    local backup_files=$(find . -name "$backup_pattern" -type f 2>/dev/null || true)
    
    if [ -n "$backup_files" ]; then
        log_info "Cleaning up backup files..."
        echo "$backup_files" | xargs rm -f
        log_success "Backup files cleaned up"
    fi
}

# =============================================================================
# Success Notification
# =============================================================================

send_success_notification() {
    local message="$1"
    log_info "Success: $message"
    
    # Add success notification logic here if needed
    # e.g., send email, webhook, etc.
}

# =============================================================================
# Export Functions
# =============================================================================

# Export all functions for use in other scripts
export -f log log_success log_warning log_error log_info log_debug
export -f handle_error handle_warning
export -f validate_var validate_file validate_url
export -f backup_file restore_file
export -f download_file
export -f get_system_info check_disk_space setup_build_environment
export -f cleanup_temp_files cleanup_backups
export -f send_success_notification
