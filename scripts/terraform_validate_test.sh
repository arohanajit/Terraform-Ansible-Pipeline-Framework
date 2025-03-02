#!/bin/bash
#
# Terraform Validation Test
# Validates Terraform configurations for all environments
#

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Base directory (repository root)
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# Environments to test
ENVIRONMENTS=("dev" "staging" "prod")

# Initialize test status
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_ENVS=()

echo "=================================================================="
echo -e "${YELLOW}Running Terraform Validation Tests${NC}"
echo "=================================================================="

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform is not installed or not in PATH${NC}"
    exit 1
fi

# Run validation for each environment
for ENV in "${ENVIRONMENTS[@]}"; do
    echo -e "\nTesting ${YELLOW}$ENV${NC} environment..."
    
    if [ ! -d "$REPO_ROOT/terraform/$ENV" ]; then
        echo -e "${RED}Error: Directory terraform/$ENV does not exist${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_ENVS+=("$ENV (missing directory)")
        continue
    fi
    
    cd "$REPO_ROOT/terraform/$ENV"
    
    # Initialize Terraform without backend
    echo "Initializing Terraform..."
    if ! terraform init -backend=false -input=false > /dev/null; then
        echo -e "${RED}Error: Failed to initialize Terraform for $ENV environment${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_ENVS+=("$ENV (init failed)")
        continue
    fi
    
    # Validate Terraform configuration
    echo "Validating Terraform configuration..."
    if ! terraform validate > /dev/null; then
        echo -e "${RED}Error: Terraform validation failed for $ENV environment${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_ENVS+=("$ENV (validation failed)")
        continue
    fi
    
    echo -e "${GREEN}✓ $ENV environment passed validation${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
done

# Print summary
echo -e "\n=================================================================="
echo -e "Terraform Validation Test Summary"
echo "=================================================================="
echo -e "Environments tested: ${#ENVIRONMENTS[@]}"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

if [ ${#FAILED_ENVS[@]} -gt 0 ]; then
    echo -e "\n${RED}Failed environments:${NC}"
    for env in "${FAILED_ENVS[@]}"; do
        echo -e "  - $env"
    done
    exit 1
else
    echo -e "\n${GREEN}All Terraform configurations are valid!${NC}"
    exit 0
fi 