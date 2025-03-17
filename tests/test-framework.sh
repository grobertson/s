#!/bin/bash

# Test framework for shell scripts
# Provides common testing utilities and functions

# Get the absolute path to s-common.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$SCRIPT_DIR")/bin/s-common.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test environment
CONFIGDIR=""
KEYPATH=""

# Mock functions
mock_ssh() {
    echo "ssh $*"
}

# Move mock_ssh_keygen definition after environment setup
setup_test_env() {
    echo "Setting up test environment..."
    
    # Create temporary directories
    CONFIGDIR="$(mktemp -d)"
    KEYPATH="$(mktemp -d)"
    
    # Export environment variables
    export CONFIGDIR
    export KEYPATH
    export TEST_ENV=1
    
    # Create necessary directories
    mkdir -p "$CONFIGDIR/templates"
    mkdir -p "$KEYPATH"
    
    # Set permissions
    chmod 700 "$CONFIGDIR"
    chmod 700 "$CONFIGDIR/templates"
    chmod 700 "$KEYPATH"
    
    # Define mock functions with access to environment variables
    mock_ssh_keygen() {
        local key_file="$1"
        log "INFO" "Mock keygen received path: $key_file"
        log "INFO" "KEYPATH is: $KEYPATH"
        
        # Extract just the key name
        local key_name="$(basename "$key_file")"
        log "INFO" "Key name is: $key_name"
        
        # Create the key in the test KEYPATH
        local test_key_file="$KEYPATH/$key_name"
        log "INFO" "Creating key file at: $test_key_file"
        
        touch "$test_key_file"
        touch "${test_key_file}.pub"
        
        log "INFO" "Setting permissions"
        chmod 600 "$test_key_file"
        chmod 644 "${test_key_file}.pub"
        log "INFO" "Key files created"
    }
    
    # Export mock functions
    export -f mock_ssh
    export -f mock_ssh_keygen
    
    echo "Test directories created:"
    echo "  CONFIGDIR: $CONFIGDIR"
    echo "  KEYPATH: $KEYPATH"
}

# Teardown test environment
teardown_test_env() {
    echo "Cleaning up test environment..."
    
    # Remove temporary directories
    rm -rf "$CONFIGDIR"
    rm -rf "$KEYPATH"
    
    echo "Test directories removed"
}

# Test assertion functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    
    ((TESTS_TOTAL++))
    if [ "$expected" = "$actual" ]; then
        ((TESTS_PASSED++))
        echo -e "${GREEN}✓ $message${NC}"
    else
        ((TESTS_FAILED++))
        echo -e "${RED}✗ $message${NC}"
        echo "  Expected: $expected"
        echo "  Got:      $actual"
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"
    
    ((TESTS_TOTAL++))
    if [[ "$haystack" == *"$needle"* ]]; then
        ((TESTS_PASSED++))
        echo -e "${GREEN}✓ $message${NC}"
    else
        ((TESTS_FAILED++))
        echo -e "${RED}✗ $message${NC}"
        echo "  Expected to contain: $needle"
        echo "  Got:                 $haystack"
    fi
}

assert_file_exists() {
    local file="$1"
    local message="$2"
    
    ((TESTS_TOTAL++))
    if [ -f "$file" ]; then
        ((TESTS_PASSED++))
        echo -e "${GREEN}✓ $message${NC}"
    else
        ((TESTS_FAILED++))
        echo -e "${RED}✗ $message${NC}"
        echo "  File not found: $file"
    fi
}

assert_file_not_exists() {
    local file="$1"
    local message="$2"
    
    ((TESTS_TOTAL++))
    if [ ! -f "$file" ]; then
        ((TESTS_PASSED++))
        echo -e "${GREEN}✓ $message${NC}"
    else
        ((TESTS_FAILED++))
        echo -e "${RED}✗ $message${NC}"
        echo "  File exists but should not: $file"
    fi
}

assert_permissions() {
    local expected="$1"
    local file="$2"
    local message="$3"
    
    ((TESTS_TOTAL++))
    local actual
    if [ "$(uname)" = "Darwin" ]; then
        actual="$(stat -f "%Lp" "$file" 2>/dev/null)"
    else
        actual="$(stat -c "%a" "$file" 2>/dev/null)"
    fi
    
    if [ "$actual" = "$expected" ]; then
        ((TESTS_PASSED++))
        echo -e "${GREEN}✓ $message${NC}"
    else
        ((TESTS_FAILED++))
        echo -e "${RED}✗ $message${NC}"
        echo "  Expected permissions: $expected"
        echo "  Got permissions: $actual"
    fi
}

# Print test summary
print_test_summary() {
    echo
    echo "Test Summary:"
    echo "Total tests:  $TESTS_TOTAL"
    echo -e "${GREEN}Passed:      $TESTS_PASSED${NC}"
    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "${RED}Failed:      $TESTS_FAILED${NC}"
    fi
    echo
} 