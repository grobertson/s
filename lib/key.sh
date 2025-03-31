#!/bin/bash

# SSH key management for the s tool

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Generate a new SSH key
generate_key() {
    local key_path="$1"
    local key_file="$2"
    local key_type="${3:-rsa}"
    local key_size="${4:-4096}"
    local comment="$5"
    
    local full_key_path="$key_path/$key_file"
    
    # Validate inputs
    validate_input "$key_type" "^(rsa|ed25519|ecdsa)$" "Invalid key type: $key_type"
    validate_input "$key_size" "^[0-9]+$" "Invalid key size: $key_size"
    
    # Check if key already exists
    if [ -f "$full_key_path" ]; then
        error_exit "SSH key already exists: $full_key_path"
    fi
    
    # Generate the key
    log $LOG_LEVEL_INFO "Generating new SSH key: $full_key_path"
    if ! ssh-keygen -t "$key_type" -b "$key_size" -f "$full_key_path" -N "" -C "$comment"; then
        error_exit "Failed to generate SSH key"
    fi
    
    # Set correct permissions
    chmod 600 "$full_key_path"
    chmod 644 "$full_key_path.pub"
    
    log $LOG_LEVEL_INFO "SSH key generated successfully"
}

# Copy SSH key to remote host
copy_key() {
    local key_path="$1"
    local key_file="$2"
    local remote_host="$3"
    local remote_user="$4"
    
    local full_key_path="$key_path/$key_file"
    
    # Validate inputs
    if [ ! -f "$full_key_path.pub" ]; then
        error_exit "Public key not found: $full_key_path.pub"
    fi
    
    # Copy the key
    log $LOG_LEVEL_INFO "Copying SSH key to $remote_user@$remote_host"
    if ! ssh-copy-id -i "$full_key_path.pub" "$remote_user@$remote_host"; then
        error_exit "Failed to copy SSH key to remote host"
    fi
    
    log $LOG_LEVEL_INFO "SSH key copied successfully"
}

# List available SSH keys
list_keys() {
    local key_path="$1"
    
    if [ ! -d "$key_path" ]; then
        error_exit "SSH key directory not found: $key_path"
    fi
    
    echo -e "${BOLD}Available SSH Keys:${NC}"
    for key in "$key_path"/*.pub; do
        if [ -f "$key" ]; then
            local key_name=$(basename "$key" .pub)
            local key_type=$(ssh-keygen -l -f "$key" | cut -d' ' -f2)
            local key_size=$(ssh-keygen -l -f "$key" | cut -d' ' -f1)
            echo -e "${CYAN}$key_name${NC} (${GREEN}$key_type${NC}, ${YELLOW}$key_size${NC})"
        fi
    done
}

# Delete SSH key
delete_key() {
    local key_path="$1"
    local key_file="$2"
    
    local full_key_path="$key_path/$key_file"
    
    # Validate inputs
    if [ ! -f "$full_key_path" ]; then
        error_exit "SSH key not found: $full_key_path"
    fi
    
    # Confirm deletion
    read -p "Are you sure you want to delete the SSH key $key_file? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log $LOG_LEVEL_INFO "Operation cancelled"
        return
    fi
    
    # Delete the key
    log $LOG_LEVEL_INFO "Deleting SSH key: $full_key_path"
    rm -f "$full_key_path" "$full_key_path.pub"
    
    log $LOG_LEVEL_INFO "SSH key deleted successfully"
}

# Test SSH key
test_key() {
    local key_path="$1"
    local key_file="$2"
    local remote_host="$3"
    local remote_user="$4"
    
    local full_key_path="$key_path/$key_file"
    
    # Validate inputs
    if [ ! -f "$full_key_path" ]; then
        error_exit "SSH key not found: $full_key_path"
    fi
    
    # Test the connection
    log $LOG_LEVEL_INFO "Testing SSH key with $remote_user@$remote_host"
    if ! ssh -i "$full_key_path" -o BatchMode=yes -o ConnectTimeout=5 "$remote_user@$remote_host" exit; then
        error_exit "SSH key test failed" $EXIT_SSH_ERROR
    fi
    
    log $LOG_LEVEL_INFO "SSH key test successful"
}

# Backup SSH keys
backup_keys() {
    local key_path="$1"
    local backup_dir="$2"
    
    # Create backup directory
    safe_mkdir "$backup_dir" "700"
    
    # Create backup
    local backup_file="$backup_dir/ssh_keys_$(date +%Y%m%d_%H%M%S).tar.gz"
    log $LOG_LEVEL_INFO "Creating backup: $backup_file"
    
    if ! tar -czf "$backup_file" -C "$key_path" .; then
        error_exit "Failed to create backup"
    fi
    
    chmod 600 "$backup_file"
    log $LOG_LEVEL_INFO "Backup created successfully"
}

# Restore SSH keys from backup
restore_keys() {
    local key_path="$1"
    local backup_file="$2"
    
    # Validate backup file
    if [ ! -f "$backup_file" ]; then
        error_exit "Backup file not found: $backup_file"
    fi
    
    # Confirm restoration
    read -p "Are you sure you want to restore SSH keys from $backup_file? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log $LOG_LEVEL_INFO "Operation cancelled"
        return
    fi
    
    # Restore from backup
    log $LOG_LEVEL_INFO "Restoring SSH keys from backup"
    if ! tar -xzf "$backup_file" -C "$key_path"; then
        error_exit "Failed to restore backup"
    fi
    
    # Set correct permissions
    chmod 700 "$key_path"
    find "$key_path" -type f -name "*.pub" -exec chmod 644 {} \;
    find "$key_path" -type f ! -name "*.pub" -exec chmod 600 {} \;
    
    log $LOG_LEVEL_INFO "SSH keys restored successfully"
} 