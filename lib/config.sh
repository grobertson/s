#!/bin/bash

# Configuration management for the s tool

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Default configuration values
DEFAULT_CONFIG=(
    "KEYPATH=$HOME/.ssh"
    "KEYFILE=id_rsa"
    "CONNECT_TIMEOUT=5"
    "MAX_RETRIES=3"
    "USE_SSH_AGENT=false"
    "LOG_LEVEL=$LOG_LEVEL_INFO"
)

# Initialize configuration
init_config() {
    local config_dir="$1"
    local config_file="$2"
    
    # Create configuration directory
    safe_mkdir "$config_dir" "700"
    
    # Create default configuration if it doesn't exist
    if [ ! -f "$config_file" ]; then
        log $LOG_LEVEL_INFO "Creating default configuration file: $config_file"
        for setting in "${DEFAULT_CONFIG[@]}"; do
            echo "$setting" >> "$config_file"
        done
        chmod 600 "$config_file"
    fi
}

# Load configuration
load_config() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        error_exit "Configuration file not found: $config_file" $EXIT_CONFIG_ERROR
    fi
    
    # Only source config file if not in test environment
    if [ -z "$TEST_ENV" ]; then
        source "$config_file"
    fi
}

# Save configuration
save_config() {
    local config_file="$1"
    local key="$2"
    local value="$3"
    
    # Validate the configuration value
    validate_config "$key" "$value"
    
    # Update or add the configuration
    if grep -q "^$key=" "$config_file"; then
        sed -i "s|^$key=.*|$key=$value|" "$config_file"
    else
        echo "$key=$value" >> "$config_file"
    fi
    
    chmod 600 "$config_file"
}

# Get configuration value
get_config() {
    local config_file="$1"
    local key="$2"
    
    if [ -f "$config_file" ]; then
        grep "^$key=" "$config_file" | cut -d'=' -f2-
    fi
}

# List all configurations
list_config() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        error_exit "Configuration file not found: $config_file" $EXIT_CONFIG_ERROR
    fi
    
    echo -e "${BOLD}Current Configuration:${NC}"
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ $key =~ ^#.*$ ]] && continue
        [[ -z $key ]] && continue
        
        echo -e "${CYAN}$key${NC}=${GREEN}$value${NC}"
    done < "$config_file"
}

# Export configuration to environment
export_config() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        error_exit "Configuration file not found: $config_file" $EXIT_CONFIG_ERROR
    fi
    
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ $key =~ ^#.*$ ]] && continue
        [[ -z $key ]] && continue
        
        export "$key=$value"
    done < "$config_file"
}

# Validate all configuration values
validate_all_config() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        error_exit "Configuration file not found: $config_file" $EXIT_CONFIG_ERROR
    fi
    
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ $key =~ ^#.*$ ]] && continue
        [[ -z $key ]] && continue
        
        validate_config "$key" "$value"
    done < "$config_file"
} 