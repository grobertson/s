#!/bin/bash

# Common functions and security checks for the s command

# Exit codes
EXIT_SUCCESS=0
EXIT_ERROR=1
EXIT_INVALID_INPUT=2
EXIT_PERMISSION_DENIED=3
EXIT_CONFIG_ERROR=4

# Configuration validation
validate_config_name() {
    local config_name="$1"
    if [[ -z "$config_name" ]]; then
        echo "Error: Configuration name cannot be empty" >&2
        return $EXIT_INVALID_INPUT
    fi
    
    if [[ "$config_name" =~ [^a-zA-Z0-9_-] ]]; then
        echo "Error: Configuration name can only contain letters, numbers, underscores, and hyphens" >&2
        return $EXIT_INVALID_INPUT
    fi
    
    return $EXIT_SUCCESS
}

# SSH key validation
validate_ssh_key() {
    local key_path="$1"
    if [[ ! -f "$key_path" ]]; then
        echo "Error: SSH key file not found: $key_path" >&2
        return $EXIT_ERROR
    fi
    
    # Check private key permissions
    if [[ "$(stat -c %a "$key_path")" != "600" ]]; then
        echo "Error: SSH private key must have 600 permissions" >&2
        return $EXIT_PERMISSION_DENIED
    fi
    
    # Validate key format
    if ! ssh-keygen -l -f "$key_path" >/dev/null 2>&1; then
        echo "Error: Invalid SSH key format: $key_path" >&2
        return $EXIT_ERROR
    fi
    
    return $EXIT_SUCCESS
}

# Safe file operations
safe_mkdir() {
    local dir="$1"
    local mode="$2"
    
    if [[ ! -d "$dir" ]]; then
        if ! mkdir -p "$dir"; then
            echo "Error: Failed to create directory: $dir" >&2
            return $EXIT_ERROR
        fi
        if [[ -n "$mode" ]]; then
            if ! chmod "$mode" "$dir"; then
                echo "Error: Failed to set directory permissions: $dir" >&2
                return $EXIT_ERROR
            fi
        fi
    fi
    return $EXIT_SUCCESS
}

safe_cp() {
    local src="$1"
    local dest="$2"
    local mode="$3"
    
    if ! cp -f "$src" "$dest"; then
        echo "Error: Failed to copy file: $src to $dest" >&2
        return $EXIT_ERROR
    fi
    
    if [[ -n "$mode" ]]; then
        if ! chmod "$mode" "$dest"; then
            echo "Error: Failed to set file permissions: $dest" >&2
            return $EXIT_ERROR
        fi
    fi
    
    return $EXIT_SUCCESS
}

# SSH connection validation
validate_ssh_connection() {
    local user="$1"
    local host="$2"
    local key_file="$3"
    local timeout="${4:-5}"
    
    if [[ -n "$key_file" ]]; then
        if ! ssh -i "$key_file" -o ConnectTimeout="$timeout" -o BatchMode=yes -o StrictHostKeyChecking=no "$user@$host" "exit" 2>/dev/null; then
            echo "Error: Failed to establish SSH connection to $user@$host" >&2
            return $EXIT_ERROR
        fi
    else
        if ! ssh -o ConnectTimeout="$timeout" -o BatchMode=yes -o StrictHostKeyChecking=no "$user@$host" "exit" 2>/dev/null; then
            echo "Error: Failed to establish SSH connection to $user@$host" >&2
            return $EXIT_ERROR
        fi
    fi
    
    return $EXIT_SUCCESS
}

# Configuration file validation
validate_config_file() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        echo "Error: Configuration file not found: $config_file" >&2
        return $EXIT_ERROR
    fi
    
    if [[ "$(stat -c %a "$config_file")" != "600" ]]; then
        echo "Error: Configuration file must have 600 permissions" >&2
        return $EXIT_PERMISSION_DENIED
    fi
    
    return $EXIT_SUCCESS
}

# Logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" >&2
} 