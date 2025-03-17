#!/bin/bash

# Test suite for the s command
# Tests all major functionality including new features

# Get the absolute path to the test framework
TEST_FRAMEWORK="$(dirname "$0")/test-framework.sh"

# Source the test framework
if [ ! -f "$TEST_FRAMEWORK" ]; then
    echo "Error: Test framework not found at $TEST_FRAMEWORK"
    exit 1
fi
source "$TEST_FRAMEWORK"

# Get the absolute path to the s command
S_CMD="$(dirname "$(dirname "$0")")/bin/s"

# Test functions
test_delete_config() {
    echo "Testing configuration deletion..."
    local config_file="$CONFIGDIR/test_config"
    mkdir -p "$(dirname "$config_file")"
    echo "HOST=test.example.com" > "$config_file"
    chmod 600 "$config_file"
    
    "$S_CMD" --delete test_config
    
    assert_file_not_exists "$config_file" "Configuration file should be deleted"
}

test_port_forwarding() {
    echo "Testing port forwarding..."
    local config_file="$CONFIGDIR/test_config"
    mkdir -p "$(dirname "$config_file")"
    echo "HOST=test.example.com" > "$config_file"
    chmod 600 "$config_file"
    
    local output="$("$S_CMD" --port-forward 8080:localhost:80 --dry-run test_config)"
    assert_contains "$output" "-L 8080:localhost:80" "Port forwarding should be enabled"
    
    rm -f "$config_file"
}

test_ssh_agent() {
    echo "Testing SSH agent forwarding..."
    local config_file="$CONFIGDIR/test_config"
    mkdir -p "$(dirname "$config_file")"
    echo "HOST=test.example.com" > "$config_file"
    chmod 600 "$config_file"
    
    local output="$("$S_CMD" --ssh-agent --dry-run test_config)"
    assert_contains "$output" "-A" "SSH agent forwarding should be enabled"
    
    rm -f "$config_file"
}

test_connection_timeout() {
    echo "Testing connection timeout..."
    local config_file="$CONFIGDIR/test_config"
    mkdir -p "$(dirname "$config_file")"
    echo "HOST=test.example.com" > "$config_file"
    chmod 600 "$config_file"
    
    local output="$("$S_CMD" --timeout 10 --dry-run test_config)"
    assert_contains "$output" "-o ConnectTimeout=10" "Connection timeout should be set"
    
    rm -f "$config_file"
}

test_connection_retries() {
    echo "Testing connection retries..."
    local config_file="$CONFIGDIR/test_config"
    mkdir -p "$(dirname "$config_file")"
    echo "HOST=test.example.com" > "$config_file"
    chmod 600 "$config_file"
    
    local output="$("$S_CMD" --retries 3 --dry-run test_config)"
    assert_contains "$output" "-o ServerAliveCountMax=3" "Connection retries should be set"
    
    rm -f "$config_file"
}

test_config_template() {
    echo "Testing configuration template..."
    local template_dir="$CONFIGDIR/templates"
    mkdir -p "$template_dir"
    local template_file="$template_dir/test_template"
    echo 'HOST=${HOST:-localhost}' > "$template_file"
    chmod 600 "$template_file"
    
    "$S_CMD" --from-template test_template test_config
    
    assert_file_exists "$CONFIGDIR/test_config" "Config should be created from template"
    assert_contains "$(cat "$CONFIGDIR/test_config")" 'HOST=${HOST:-localhost}' "Template variables should be preserved"
    
    rm -f "$template_file" "$CONFIGDIR/test_config"
}

test_key_management() {
    echo "Testing key management..."
    local key_file="$KEYPATH/test_key"
    mkdir -p "$(dirname "$key_file")"
    
    # Test key generation
    "$S_CMD" --generate-key test_key
    assert_file_exists "$key_file" "Private key should be generated"
    assert_file_exists "${key_file}.pub" "Public key should be generated"
    assert_permissions "600" "$key_file" "Private key should have correct permissions"
    assert_permissions "644" "${key_file}.pub" "Public key should have correct permissions"
    
    # Test key deletion
    "$S_CMD" --delete-key test_key
    assert_file_not_exists "$key_file" "Private key should be deleted"
    assert_file_not_exists "${key_file}.pub" "Public key should be deleted"
}

# Main test execution
main() {
    setup_test_env
    
    # Export environment variables
    export CONFIGDIR
    export KEYPATH
    
    # Run all tests
    test_delete_config
    test_port_forwarding
    test_ssh_agent
    test_connection_timeout
    test_connection_retries
    test_config_template
    test_key_management
    
    # Print summary
    print_test_summary
    
    # Cleanup
    teardown_test_env
}

# Run the tests
main

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi 