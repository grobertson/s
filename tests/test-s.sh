#!/bin/bash

# Test suite for the s command
# Tests all major functionality including new features

# Source test framework
source "$(dirname "$0")/test-framework.sh"

# Source the s script
source "$(dirname "$0")/../bin/s"

# Test cases
test_delete_config() {
    local config_name="test_config"
    local config_file="$CONFIGDIR$config_name"
    
    # Create test config
    cat > "$config_file" << EOF
HOST=test.example.com
USER=testuser
KEYFILE=id_rsa
EOF
    chmod 600 "$config_file"
    
    # Test delete command
    s --delete "$config_name"
    
    # Verify deletion
    assert_file_not_exists "$config_file" "Configuration file should be deleted"
}

test_port_forwarding() {
    local config_name="test_port_forward"
    local config_file="$CONFIGDIR$config_name"
    
    # Create test config with port forwarding
    cat > "$config_file" << EOF
HOST=test.example.com
USER=testuser
KEYFILE=id_rsa
LOCAL_PORT=8080
REMOTE_PORT=80
EOF
    chmod 600 "$config_file"
    
    # Test connection with port forwarding
    local ssh_cmd=$(s --dry-run "$config_name")
    assert_equals "-L 8080:localhost:80" "$(echo "$ssh_cmd" | grep -o "-L 8080:localhost:80")" "Port forwarding should be enabled"
}

test_ssh_agent() {
    local config_name="test_agent"
    local config_file="$CONFIGDIR$config_name"
    
    # Create test config
    cat > "$config_file" << EOF
HOST=test.example.com
USER=testuser
KEYFILE=id_rsa
USE_SSH_AGENT=yes
EOF
    chmod 600 "$config_file"
    
    # Test SSH agent integration
    local ssh_cmd=$(s --dry-run "$config_name")
    assert_equals "-A" "$(echo "$ssh_cmd" | grep -o "-A")" "SSH agent forwarding should be enabled"
}

test_connection_timeout() {
    local config_name="test_timeout"
    local config_file="$CONFIGDIR$config_name"
    
    # Create test config with timeout
    cat > "$config_file" << EOF
HOST=test.example.com
USER=testuser
KEYFILE=id_rsa
CONNECT_TIMEOUT=10
EOF
    chmod 600 "$config_file"
    
    # Test connection timeout
    local ssh_cmd=$(s --dry-run "$config_name")
    assert_equals "-o ConnectTimeout=10" "$(echo "$ssh_cmd" | grep -o "-o ConnectTimeout=10")" "Connection timeout should be set"
}

test_connection_retries() {
    local config_name="test_retries"
    local config_file="$CONFIGDIR$config_name"
    
    # Create test config with retries
    cat > "$config_file" << EOF
HOST=test.example.com
USER=testuser
KEYFILE=id_rsa
MAX_RETRIES=3
EOF
    chmod 600 "$config_file"
    
    # Test connection retries
    local ssh_cmd=$(s --dry-run "$config_name")
    assert_equals "-o ServerAliveCountMax=3" "$(echo "$ssh_cmd" | grep -o "-o ServerAliveCountMax=3")" "Connection retries should be set"
}

test_config_template() {
    local template_name="test_template"
    local template_file="$CONFIGDIR$template_name"
    
    # Create test template
    cat > "$template_file" << EOF
HOST=\${HOST}
USER=\${USER}
KEYFILE=id_rsa
EOF
    chmod 600 "$template_file"
    
    # Create config from template
    HOST=test.example.com USER=testuser s --from-template "$template_name" "test_config"
    
    # Verify config creation
    assert_file_exists "$CONFIGDIRtest_config" "Config should be created from template"
    
    # Verify config contents
    local config_contents=$(cat "$CONFIGDIRtest_config")
    assert_equals "HOST=test.example.com" "$(echo "$config_contents" | grep "^HOST=")" "Host should be set from environment"
    assert_equals "USER=testuser" "$(echo "$config_contents" | grep "^USER=")" "User should be set from environment"
}

test_key_management() {
    local key_name="test_key"
    local key_file="$KEYPATH$key_name"
    
    # Test key generation
    s --generate-key "$key_name"
    assert_file_exists "$key_file" "Private key should be generated"
    assert_file_exists "${key_file}.pub" "Public key should be generated"
    assert_permissions "$key_file" "600" "Private key should have correct permissions"
    assert_permissions "${key_file}.pub" "644" "Public key should have correct permissions"
    
    # Test key deletion
    s --delete-key "$key_name"
    assert_file_not_exists "$key_file" "Private key should be deleted"
    assert_file_not_exists "${key_file}.pub" "Public key should be deleted"
}

# Run all tests
main() {
    echo "Running tests..."
    
    # Setup test environment
    setup
    
    # Run test cases
    test_delete_config
    test_port_forwarding
    test_ssh_agent
    test_connection_timeout
    test_connection_retries
    test_config_template
    test_key_management
    
    # Print test summary
    print_summary
    
    # Cleanup
    teardown
    
    # Exit with appropriate status
    if [[ $TESTS_FAILED -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi 