#!/bin/bash

# Common library functions for the s tool

# Exit codes
EXIT_SUCCESS=0
EXIT_ERROR=1
EXIT_INVALID_ARGS=2
EXIT_CONFIG_ERROR=3
EXIT_SSH_ERROR=4

# Log levels
LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_WARN=2
LOG_LEVEL_ERROR=3

# Default log level
LOG_LEVEL=${LOG_LEVEL:-$LOG_LEVEL_INFO}

# ANSI color support
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    DIM='\033[2m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    MAGENTA=''
    CYAN=''
    BOLD=''
    DIM=''
    NC=''
fi

# Logging functions
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Only log if the message level is >= current log level
    if [ "$level" -ge "$LOG_LEVEL" ]; then
        case $level in
            $LOG_LEVEL_DEBUG)
                echo -e "${DIM}[DEBUG] $timestamp: $message${NC}" >&2
                ;;
            $LOG_LEVEL_INFO)
                echo -e "${BLUE}[INFO] $timestamp: $message${NC}" >&2
                ;;
            $LOG_LEVEL_WARN)
                echo -e "${YELLOW}[WARN] $timestamp: $message${NC}" >&2
                ;;
            $LOG_LEVEL_ERROR)
                echo -e "${RED}[ERROR] $timestamp: $message${NC}" >&2
                ;;
        esac
    fi
}

# Error handling
error_exit() {
    local message="$1"
    local exit_code=${2:-$EXIT_ERROR}
    log $LOG_LEVEL_ERROR "$message"
    exit "$exit_code"
}

# Safe directory creation with permissions
safe_mkdir() {
    local dir="$1"
    local perms="$2"
    
    if [ ! -d "$dir" ]; then
        if ! mkdir -p "$dir"; then
            error_exit "Failed to create directory: $dir"
        fi
    fi
    
    if ! chmod "$perms" "$dir"; then
        error_exit "Failed to set permissions on directory: $dir"
    fi
}

# Configuration validation
validate_config() {
    local key="$1"
    local value="$2"
    
    case "$key" in
        KEYPATH)
            if [ ! -d "$value" ]; then
                error_exit "Invalid KEYPATH: $value" $EXIT_CONFIG_ERROR
            fi
            ;;
        KEYFILE)
            if [ -z "$value" ]; then
                error_exit "KEYFILE cannot be empty" $EXIT_CONFIG_ERROR
            fi
            ;;
        *)
            log $LOG_LEVEL_WARN "Unknown configuration key: $key"
            ;;
    esac
}

# Input validation
validate_input() {
    local input="$1"
    local pattern="$2"
    local message="$3"
    
    if ! [[ "$input" =~ $pattern ]]; then
        error_exit "$message" $EXIT_INVALID_ARGS
    fi
}

# Cache management
cache_set() {
    local key="$1"
    local value="$2"
    local cache_file="$CONFIGDIR/.cache"
    
    # Create cache file if it doesn't exist
    touch "$cache_file"
    chmod 600 "$cache_file"
    
    # Update or add the key-value pair
    if grep -q "^$key=" "$cache_file"; then
        sed -i "s|^$key=.*|$key=$value|" "$cache_file"
    else
        echo "$key=$value" >> "$cache_file"
    fi
}

cache_get() {
    local key="$1"
    local cache_file="$CONFIGDIR/.cache"
    
    if [ -f "$cache_file" ]; then
        grep "^$key=" "$cache_file" | cut -d'=' -f2-
    fi
}

# SSH connection validation
validate_ssh_connection() {
    local host="$1"
    local timeout="${2:-5}"
    
    if ! timeout "$timeout" ssh -q -o BatchMode=yes -o ConnectTimeout="$timeout" "$host" exit; then
        error_exit "Failed to connect to $host" $EXIT_SSH_ERROR
    fi
}

# Key management
generate_ssh_key() {
    local key_file="$1"
    local key_type="${2:-rsa}"
    local key_size="${3:-4096}"
    
    if [ -f "$key_file" ]; then
        error_exit "SSH key already exists: $key_file"
    fi
    
    log $LOG_LEVEL_INFO "Generating new SSH key: $key_file"
    if ! ssh-keygen -t "$key_type" -b "$key_size" -f "$key_file" -N ""; then
        error_exit "Failed to generate SSH key"
    fi
    
    chmod 600 "$key_file"
    chmod 644 "$key_file.pub"
} 