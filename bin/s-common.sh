#!/bin/bash

# Common functions and security checks for the s command

# Exit codes
EXIT_SUCCESS=0
EXIT_ERROR=1
EXIT_INVALID_INPUT=2
EXIT_CONFIG_ERROR=3

# Log levels
LOG_LEVEL_ERROR=0
LOG_LEVEL_INFO=1
LOG_LEVEL_DEBUG=2

# Default log level
LOG_LEVEL=$LOG_LEVEL_INFO

# Safe directory creation
safe_mkdir() {
    local dir="$1"
    local perms="$2"
    
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" || return 1
        chmod "$perms" "$dir" || return 1
    fi
    return 0
}

# Log function
log() {
    local level="$1"
    local message="$2"
    
    case "$level" in
        "ERROR") echo "ERROR: $message" >&2 ;;
        "INFO") echo "INFO: $message" >&2 ;;
        "DEBUG") [ "$LOG_LEVEL" -ge "$LOG_LEVEL_DEBUG" ] && echo "DEBUG: $message" >&2 ;;
        *) echo "$message" >&2 ;;
    esac
}

# Default paths
if [ -z "$CONFIGDIR" ]; then
    CONFIGDIR="$HOME/.s"
fi

if [ -z "$KEYPATH" ]; then
    KEYPATH="$HOME/.ssh"
fi

# Create directories if they don't exist
mkdir -p "$CONFIGDIR/templates"
mkdir -p "$KEYPATH"

# Set permissions
chmod 700 "$CONFIGDIR"
chmod 700 "$CONFIGDIR/templates"
chmod 700 "$KEYPATH"

# Validation functions
validate_config_name() {
    local name="$1"
    
    if [ -z "$name" ]; then
        log "ERROR" "Configuration name is required"
        return $EXIT_INVALID_INPUT
    fi
    
    if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log "ERROR" "Invalid configuration name: $name"
        return $EXIT_INVALID_INPUT
    fi
    
    return $EXIT_SUCCESS
}

validate_config_file() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        log "ERROR" "Configuration file not found: $file"
        return $EXIT_CONFIG_ERROR
    fi
    
    if [ ! -r "$file" ]; then
        log "ERROR" "Configuration file not readable: $file"
        return $EXIT_CONFIG_ERROR
    fi
    
    return $EXIT_SUCCESS
}

validate_ssh_key() {
    local key_file="$1"
    
    if [ ! -f "$key_file" ]; then
        log "ERROR" "SSH key not found: $key_file"
        return $EXIT_ERROR
    fi
    
    if [ ! -r "$key_file" ]; then
        log "ERROR" "SSH key not readable: $key_file"
        return $EXIT_ERROR
    fi
    
    if [ "$(stat -c %a "$key_file" 2>/dev/null || stat -f "%Lp" "$key_file")" != "600" ]; then
        log "ERROR" "SSH key has incorrect permissions: $key_file"
        return $EXIT_ERROR
    fi
    
    return $EXIT_SUCCESS
}

validate_ssh_connection() {
    local user="$1"
    local host="$2"
    local key_file="$3"
    
    if [ -z "$user" ] || [ -z "$host" ]; then
        log "ERROR" "User and host are required"
        return $EXIT_INVALID_INPUT
    fi
    
    if [ -n "$key_file" ] && ! validate_ssh_key "$key_file"; then
        return $EXIT_ERROR
    fi
    
    return $EXIT_SUCCESS
}

# File operations
safe_cp() {
    local src="$1"
    local dst="$2"
    local perms="$3"
    
    if [ ! -f "$src" ]; then
        log "ERROR" "Source file not found: $src"
        return $EXIT_ERROR
    fi
    
    if ! cp -f "$src" "$dst"; then
        log "ERROR" "Failed to copy file from $src to $dst"
        return $EXIT_ERROR
    fi
    
    if ! chmod "$perms" "$dst"; then
        log "ERROR" "Failed to set permissions on $dst"
        return $EXIT_ERROR
    fi
    
    return $EXIT_SUCCESS
}

secure_file_operation() {
    local operation="$1"
    local file="$2"
    local content="$3"
    
    # Create temporary file
    local temp_file
    temp_file="$(mktemp)"
    
    # Write content to temporary file
    echo "$content" > "$temp_file"
    
    # Set correct permissions
    chmod 600 "$temp_file"
    
    # Move temporary file to target
    mv "$temp_file" "$file"
    
    # Set correct permissions on target
    chmod 600 "$file"
}

# Configuration management
save_config() {
    local name="$1"
    local config_file="$CONFIGDIR/$name"
    
    # Validate input
    if ! validate_config_name "$name"; then
        return $EXIT_INVALID_INPUT
    fi
    
    # Check if config already exists
    if [ -f "$config_file" ]; then
        log "ERROR" "Configuration '$name' already exists"
        return $EXIT_ERROR
    fi
    
    # Create config file
    secure_file_operation "create" "$config_file" ""
    
    log "INFO" "Configuration '$name' created"
    return $EXIT_SUCCESS
}

# Help message
show_help() {
    cat << EOF
Usage: s [OPTIONS] [CONFIG]

Options:
    --version           Show version
    --help             Show this help message
    --save NAME        Save current configuration
    --delete NAME      Delete configuration
    --from-template TEMPLATE NAME  Create config from template
    --generate-key NAME  Generate SSH key
    --delete-key NAME    Delete SSH key
    --dry-run          Show SSH command without executing
    --port-forward LOCAL:REMOTE  Enable port forwarding
    --ssh-agent        Enable SSH agent forwarding
    --timeout SECONDS  Set connection timeout
    --retries COUNT    Set connection retries

Configuration Management:
    s --save <name>           Save current configuration
    s --delete <name>         Delete configuration
    s --from-template <template> <name>  Create config from template
    s --generate-key <name>   Generate SSH key
    s --delete-key <name>     Delete SSH key

Connection Options:
    s --dry-run <name>        Show SSH command without executing
    s --port-forward <local>:<remote>  Enable port forwarding
    s --ssh-agent            Enable SSH agent forwarding
    s --timeout <seconds>     Set connection timeout
    s --retries <count>       Set connection retries

Installation:
    s --install home         Install for current user
    s --install system       Install system-wide
    s --remove force         Remove installation
EOF
} 