#!/bin/bash

# Test runner for the s tool

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-framework.sh"

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Run all test files
run_tests() {
    local test_dir="$1"
    
    # Find all test files
    local test_files
    test_files=$(find "$test_dir" -name "test-*.sh" -type f)
    
    if [ -z "$test_files" ]; then
        echo -e "${YELLOW}No test files found in $test_dir${NC}"
        return 1
    fi
    
    # Run each test file
    for test_file in $test_files; do
        echo -e "\n${BLUE}Running tests from:${NC} $test_file"
        if [ -x "$test_file" ]; then
            if "$test_file"; then
                echo -e "${GREEN}All tests passed in $test_file${NC}"
            else
                echo -e "${RED}Some tests failed in $test_file${NC}"
            fi
        else
            echo -e "${RED}Test file is not executable: $test_file${NC}"
            chmod +x "$test_file"
            if "$test_file"; then
                echo -e "${GREEN}All tests passed in $test_file${NC}"
            else
                echo -e "${RED}Some tests failed in $test_file${NC}"
            fi
        fi
    done
}

# Show test summary
show_summary() {
    echo -e "\n${BOLD}Test Summary:${NC}"
    echo -e "  ${GREEN}Passed:${NC} $TESTS_PASSED"
    echo -e "  ${RED}Failed:${NC} $TESTS_FAILED"
    echo -e "  ${BLUE}Total:${NC} $TESTS_TOTAL"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "\n${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "\n${RED}Some tests failed${NC}"
        return 1
    fi
}

# Main entry point
main() {
    # Setup test environment
    setup_test_env
    
    # Run all tests
    run_tests "$SCRIPT_DIR"
    
    # Show summary
    show_summary
    
    # Cleanup
    cleanup_test_env
}

# Execute main function
main "$@" 