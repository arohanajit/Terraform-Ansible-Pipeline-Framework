#!/bin/bash
#
# Terraform Validation Test
# Validates all Terraform configurations in the repository
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

TERRAFORM_DIRS=("terraform/dev" "terraform/staging" "terraform/prod")
FAILED=false

echo "=================================================================="
echo -e "${BOLD}Running Terraform Validation Tests${NC}"
echo "=================================================================="

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform is not installed.${NC}"
    exit 1
fi

# Get terraform version
TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
echo -e "Using Terraform version: ${BLUE}$TERRAFORM_VERSION${NC}"

# Validate each Terraform environment
for dir in "${TERRAFORM_DIRS[@]}"; do
    echo -e "\n${YELLOW}Validating $dir...${NC}"
    
    # Check if directory exists
    if [ ! -d "$dir" ]; then
        echo -e "${RED}Directory $dir does not exist.${NC}"
        FAILED=true
        continue
    fi
    
    # Go to directory
    cd "$REPO_ROOT/$dir"
    
    # Initialize terraform with backend disabled (for CI environment)
    echo "Initializing Terraform..."
    if ! terraform init -backend=false -no-color > /dev/null; then
        echo -e "${RED}Failed to initialize Terraform in $dir${NC}"
        FAILED=true
        continue
    fi
    
    # Validate terraform configuration
    echo "Validating Terraform configuration..."
    if ! terraform validate -no-color; then
        echo -e "${RED}Terraform validation failed in $dir${NC}"
        FAILED=true
        continue
    fi
    
    # Check formatting
    echo "Checking Terraform formatting..."
    if ! terraform fmt -check -no-color; then
        echo -e "${RED}Terraform formatting issues found in $dir${NC}"
        echo -e "${YELLOW}Run 'terraform fmt' to fix formatting issues.${NC}"
        FAILED=true
        continue
    fi
    
    echo -e "${GREEN}Validation successful for $dir${NC}"
done

# Return to repo root
cd "$REPO_ROOT"

if [ "$FAILED" = true ]; then
    echo -e "\n${RED}${BOLD}✖ Terraform validation tests failed.${NC}"
    exit 1
else
    echo -e "\n${GREEN}${BOLD}✓ All Terraform validation tests passed!${NC}"
    exit 0
fi 