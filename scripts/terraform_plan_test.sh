#!/bin/bash
#
# Terraform Plan Verification Test
# Verifies that Terraform plan output contains expected resources
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

# Default environment to test
ENV=${1:-dev}

# Expected resources for each environment
declare -A EXPECTED_RESOURCES
EXPECTED_RESOURCES[dev]="aws_vpc aws_subnet aws_internet_gateway aws_route_table aws_security_group"
EXPECTED_RESOURCES[staging]="aws_vpc aws_subnet aws_internet_gateway aws_route_table aws_security_group"
EXPECTED_RESOURCES[prod]="aws_vpc aws_subnet aws_internet_gateway aws_route_table aws_security_group"

echo "=================================================================="
echo -e "${YELLOW}Running Terraform Plan Verification Test for $ENV environment${NC}"
echo "=================================================================="

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform is not installed or not in PATH${NC}"
    exit 1
fi

# Check if environment directory exists
if [ ! -d "$REPO_ROOT/terraform/$ENV" ]; then
    echo -e "${RED}Error: Directory terraform/$ENV does not exist${NC}"
    exit 1
fi

cd "$REPO_ROOT/terraform/$ENV"

# Initialize Terraform without backend
echo "Initializing Terraform..."
if ! terraform init -backend=false -input=false > /dev/null; then
    echo -e "${RED}Error: Failed to initialize Terraform for $ENV environment${NC}"
    exit 1
fi

# Run Terraform plan and capture output
echo "Running Terraform plan..."
PLAN_OUTPUT=$(terraform plan -input=false -no-color 2>&1)
PLAN_EXIT_CODE=$?

if [ $PLAN_EXIT_CODE -ne 0 ]; then
    echo -e "${RED}Error: Terraform plan failed for $ENV environment${NC}"
    echo "$PLAN_OUTPUT"
    exit 1
fi

# Check for expected resources in plan output
MISSING_RESOURCES=()
for resource in ${EXPECTED_RESOURCES[$ENV]}; do
    if ! echo "$PLAN_OUTPUT" | grep -q "$resource"; then
        MISSING_RESOURCES+=("$resource")
    fi
done

# Print results
if [ ${#MISSING_RESOURCES[@]} -gt 0 ]; then
    echo -e "\n${RED}Error: The following expected resources are missing from the plan:${NC}"
    for resource in "${MISSING_RESOURCES[@]}"; do
        echo -e "  - $resource"
    done
    exit 1
else
    echo -e "\n${GREEN}✓ All expected resources found in plan output for $ENV environment${NC}"
    echo -e "Expected resources:"
    for resource in ${EXPECTED_RESOURCES[$ENV]}; do
        echo -e "  - $resource"
    done
    exit 0
fi 