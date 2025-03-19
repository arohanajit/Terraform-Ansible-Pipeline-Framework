#!/bin/bash
#
# Main Test Runner Script
# Runs all validation tests for the Terraform-Ansible Pipeline Framework
#

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Base directory (repository root)
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# Default timeout values (in seconds)
DEFAULT_TIMEOUT=60
TERRAFORM_TIMEOUT=300  # 5 minutes
ANSIBLE_TIMEOUT=180    # 3 minutes
VALIDATION_TIMEOUT=60  # 1 minute

# Check if timeout command is available
if command -v timeout &> /dev/null; then
    TIMEOUT_CMD="timeout"
elif command -v gtimeout &> /dev/null; then
    # On macOS, timeout might be available as gtimeout via coreutils
    TIMEOUT_CMD="gtimeout"
else
    echo -e "${YELLOW}⚠️ Warning: 'timeout' command not found. Tests will run without timeouts.${NC}"
    TIMEOUT_CMD=""
fi

# Activate virtual environment if it exists
if [ -f "$REPO_ROOT/venv/bin/activate" ]; then
    echo -e "${BLUE}Activating Python virtual environment...${NC}"
    source "$REPO_ROOT/venv/bin/activate"
fi

# Create reports directory if it doesn't exist
mkdir -p reports

# Initialize test status
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

echo "=================================================================="
echo -e "${BOLD}Terraform-Ansible Pipeline Framework Test Suite${NC}"
echo "=================================================================="
echo "Started at: $(date)"
echo -e "${YELLOW}⚠️ Note: Tests will run sequentially and the script will exit on the first failure${NC}"
echo "=================================================================="

# Function to run a test script and track its status
run_test() {
    local test_name="$1"
    local script_path="$2"
    local timeout="$DEFAULT_TIMEOUT"
    local args=()
    
    # Process additional arguments
    shift 2
    while [[ $# -gt 0 ]]; do
        if [[ "$1" == "--timeout="* ]]; then
            timeout="${1#--timeout=}"
        else
            args+=("$1")
        fi
        shift
    done
    
    # Set timeout based on test type if not explicitly provided
    if [[ "$test_name" == *"Terraform"* ]] && [[ "$timeout" == "$DEFAULT_TIMEOUT" ]]; then
        timeout="$TERRAFORM_TIMEOUT"
    elif [[ "$test_name" == *"Ansible"* ]] && [[ "$timeout" == "$DEFAULT_TIMEOUT" ]]; then
        timeout="$ANSIBLE_TIMEOUT"
    elif [[ "$test_name" == *"Validation"* || "$test_name" == *"Validate"* ]] && [[ "$timeout" == "$DEFAULT_TIMEOUT" ]]; then
        timeout="$VALIDATION_TIMEOUT"
    fi
    
    if [ ! -f "$script_path" ]; then
        echo -e "\n${YELLOW}⚠️ Warning: Test script not found: $script_path${NC}"
        return 0
    fi
    
    echo -e "\n=================================================================="
    echo -e "${BLUE}Running Test: ${BOLD}$test_name${NC} (timeout: ${timeout}s)"
    echo "=================================================================="
    
    chmod +x "$script_path"
    
    # Run the test with timeout and capture its exit code
    local start_time=$(date +%s)
    
    if [ -n "$TIMEOUT_CMD" ]; then
        # Run with timeout if available
        if $TIMEOUT_CMD -k 10 "${timeout}" "$script_path" "${args[@]}"; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            echo -e "\n${GREEN}✅ Test Passed: $test_name (completed in ${duration}s)${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        elif [[ $? -eq 124 ]]; then
            echo -e "\n${RED}❌ Test Failed: $test_name (TIMEOUT after ${timeout}s)${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            FAILED_TESTS+=("$test_name (TIMEOUT)")
            return 1
        else
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            echo -e "\n${RED}❌ Test Failed: $test_name (completed in ${duration}s)${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            FAILED_TESTS+=("$test_name")
            return 1
        fi
    else
        # Run without timeout
        if "$script_path" "${args[@]}"; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            echo -e "\n${GREEN}✅ Test Passed: $test_name (completed in ${duration}s)${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        else
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            echo -e "\n${RED}❌ Test Failed: $test_name (completed in ${duration}s)${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            FAILED_TESTS+=("$test_name")
            return 1
        fi
    fi
}

# Run Ansible syntax test directly
run_ansible_syntax_test() {
    local env="$1"
    local playbook="$REPO_ROOT/ansible/playbooks/$env/site.yml"
    local timeout="$ANSIBLE_TIMEOUT"
    
    echo -e "\n=================================================================="
    echo -e "${BLUE}Running Test: ${BOLD}Ansible Syntax Check ($env)${NC} (timeout: ${timeout}s)"
    echo "=================================================================="
    
    local start_time=$(date +%s)
    
    if [ -n "$TIMEOUT_CMD" ]; then
        # Run with timeout if available
        if $TIMEOUT_CMD -k 10 "${timeout}" ansible-playbook --syntax-check "$playbook"; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            echo -e "\n${GREEN}✅ Test Passed: Ansible Syntax Check ($env) (completed in ${duration}s)${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        elif [[ $? -eq 124 ]]; then
            echo -e "\n${RED}❌ Test Failed: Ansible Syntax Check ($env) (TIMEOUT after ${timeout}s)${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            FAILED_TESTS+=("Ansible Syntax Check ($env) (TIMEOUT)")
            return 1
        else
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            echo -e "\n${RED}❌ Test Failed: Ansible Syntax Check ($env) (completed in ${duration}s)${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            FAILED_TESTS+=("Ansible Syntax Check ($env)")
            return 1
        fi
    else
        # Run without timeout
        if ansible-playbook --syntax-check "$playbook"; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            echo -e "\n${GREEN}✅ Test Passed: Ansible Syntax Check ($env) (completed in ${duration}s)${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        else
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            echo -e "\n${RED}❌ Test Failed: Ansible Syntax Check ($env) (completed in ${duration}s)${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            FAILED_TESTS+=("Ansible Syntax Check ($env)")
            return 1
        fi
    fi
}

# Phase 1: Basic Repository Tests
echo -e "\n${BOLD}${BLUE}Running Phase 1: Basic Repository Tests${NC}"
run_test "Repository Structure Validation" "$REPO_ROOT/scripts/validate_repo_structure.sh" --timeout=60 || exit 1
run_test "Repository Validation" "$REPO_ROOT/scripts/validate_repo.sh" --timeout=60 || exit 1
run_test "CI/CD Connection Test" "$REPO_ROOT/scripts/test_cicd_connection.sh" --timeout=120 || exit 1
run_test "Configuration Files Validation" "$REPO_ROOT/scripts/validate_config_files.sh" --timeout=60 || exit 1
run_test "Configuration Parsing Test" "$REPO_ROOT/scripts/validate_configs.sh" --timeout=120 || exit 1

# Phase 2: Terraform Tests
echo -e "\n${BOLD}${BLUE}Running Phase 2: Terraform Tests${NC}"
run_test "Terraform Validation Test" "$REPO_ROOT/scripts/test_terraform_validation.sh" --timeout=180 || exit 1
run_test "Terraform Plan Verification Test (Dev)" "$REPO_ROOT/scripts/test_terraform_plan.sh" "dev" --timeout=300 || exit 1
run_test "Terraform State Isolation Test" "$REPO_ROOT/scripts/test_terraform_state_isolation.sh" --timeout=240 || exit 1

# Phase 3: Ansible Tests
echo -e "\n${BOLD}${BLUE}Running Phase 3: Ansible Tests${NC}"
run_test "Ansible Lint Test" "$REPO_ROOT/scripts/test_ansible_lint.sh" --timeout=120 || exit 1
run_ansible_syntax_test "prod" || exit 1
run_ansible_syntax_test "dev" || exit 1
run_ansible_syntax_test "staging" || exit 1
run_test "Ansible Roles Validation" "$REPO_ROOT/scripts/test_ansible_roles.sh" --timeout=120 || exit 1
run_test "Ansible-Terraform Integration Test" "$REPO_ROOT/scripts/test_terraform_ansible_integration.sh" --timeout=360 || exit 1

# Print summary
echo -e "\n=================================================================="
echo -e "${BOLD}Test Summary${NC}"
echo "=================================================================="
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"

if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
    echo -e "\n${RED}Failed tests:${NC}"
    for test in "${FAILED_TESTS[@]}"; do
        echo -e "  - $test"
    done
fi

echo -e "\nCompleted at: $(date)"
echo "=================================================================="

# Create a test report
REPORT_FILE="reports/test_run_$(date +%Y%m%d%H%M%S).txt"
{
    echo "TERRAFORM-ANSIBLE PIPELINE FRAMEWORK TEST REPORT"
    echo "================================================="
    echo "Run date: $(date)"
    echo "Repository root: $REPO_ROOT"
    echo ""
    echo "TIMEOUT SETTINGS"
    echo "---------------"
    echo "Default timeout: ${DEFAULT_TIMEOUT}s"
    echo "Terraform operations: ${TERRAFORM_TIMEOUT}s"
    echo "Ansible operations: ${ANSIBLE_TIMEOUT}s"
    echo "Validation operations: ${VALIDATION_TIMEOUT}s"
    echo ""
    echo "SUMMARY"
    echo "-------"
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
    echo ""
    if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
        echo "Failed tests:"
        for test in "${FAILED_TESTS[@]}"; do
            echo "  - $test"
        done
    else
        echo "All tests passed successfully!"
    fi
} > "$REPORT_FILE"

echo -e "Test report saved to: ${YELLOW}$REPORT_FILE${NC}"

# If in virtual environment, deactivate it
if [ -n "$VIRTUAL_ENV" ]; then
    deactivate
fi

# Exit with appropriate status code
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "\n${RED}❌ Some tests failed. Please check the output above for details.${NC}"
    exit 1
else
    echo -e "\n${GREEN}✅ All tests passed successfully!${NC}"
    exit 0
fi 