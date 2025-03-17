#!/bin/bash

# Test framework for shell scripts
# Provides common testing utilities and functions

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test setup and teardown
setup() {
    # Create temporary test directory
    TEST_DIR=$(mktemp -d)
    export TEST_DIR
    
    # Create test SSH directory
    TEST_SSH_DIR="$TEST_DIR/.ssh"
    mkdir -p "$TEST_SSH_DIR"
    chmod 700 "$TEST_SSH_DIR"
    
    # Create test config directory
    TEST_CONFIG_DIR="$TEST_DIR/.s"
    mkdir -p "$TEST_CONFIG_DIR"
    chmod 700 "$TEST_CONFIG_DIR"
    
    # Create test config file
    TEST_CONFIG_FILE="$TEST_DIR/.sconfig"
    cat > "$TEST_CONFIG_FILE" << EOF
KEYPATH=$TEST_SSH_DIR/
KEYFILE=id_rsa
EOF
    chmod 600 "$TEST_CONFIG_FILE"
    
    # Export test environment variables
    export HOME="$TEST_DIR"
    export CONFIGDIR="$TEST_CONFIG_DIR"
    export CONFIGFILE="$TEST_CONFIG_FILE"
}

teardown() {
    # Clean up test directory
    rm -rf "$TEST_DIR"
}

# Test assertion functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}✓${NC} $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo -e "  Expected: $expected"
        echo -e "  Got:      $actual"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_not_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    if [[ "$expected" != "$actual" ]]; then
        echo -e "${GREEN}✓${NC} $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo -e "  Expected: not $expected"
        echo -e "  Got:      $actual"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✓${NC} $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo -e "  File not found: $file"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_file_not_exists() {
    local file="$1"
    local message="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    if [[ ! -f "$file" ]]; then
        echo -e "${GREEN}✓${NC} $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo -e "  File exists but should not: $file"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_directory_exists() {
    local dir="$1"
    local message="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    if [[ -d "$dir" ]]; then
        echo -e "${GREEN}✓${NC} $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo -e "  Directory not found: $dir"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_directory_not_exists() {
    local dir="$1"
    local message="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    if [[ ! -d "$dir" ]]; then
        echo -e "${GREEN}✓${NC} $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo -e "  Directory exists but should not: $dir"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_permissions() {
    local file="$1"
    local expected_perms="$2"
    local message="$3"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    local actual_perms=$(stat -c %a "$file" 2>/dev/null)
    if [[ "$actual_perms" == "$expected_perms" ]]; then
        echo -e "${GREEN}✓${NC} $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo -e "  Expected permissions: $expected_perms"
        echo -e "  Got permissions:      $actual_perms"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test summary
print_summary() {
    echo -e "\n${YELLOW}Test Summary:${NC}"
    echo -e "Total tests:  $TESTS_TOTAL"
    echo -e "${GREEN}Passed:      $TESTS_PASSED${NC}"
    echo -e "${RED}Failed:      $TESTS_FAILED${NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Mock SSH command for testing
mock_ssh() {
    local expected_args=("$@")
    local actual_args=()
    
    # Read actual arguments
    while read -r arg; do
        actual_args+=("$arg")
    done
    
    # Compare arguments
    if [[ "${#expected_args[@]}" != "${#actual_args[@]}" ]]; then
        echo "Error: Expected ${#expected_args[@]} arguments, got ${#actual_args[@]}"
        return 1
    fi
    
    for i in "${!expected_args[@]}"; do
        if [[ "${expected_args[$i]}" != "${actual_args[$i]}" ]]; then
            echo "Error: Argument $i mismatch"
            echo "Expected: ${expected_args[$i]}"
            echo "Got:      ${actual_args[$i]}"
            return 1
        fi
    done
    
    return 0
}

# Mock SSH key generation
mock_ssh_keygen() {
    local key_file="$1"
    local pub_file="${key_file}.pub"
    
    # Create dummy key files
    echo "dummy private key" > "$key_file"
    echo "dummy public key" > "$pub_file"
    
    chmod 600 "$key_file"
    chmod 644 "$pub_file"
    
    return 0
} 