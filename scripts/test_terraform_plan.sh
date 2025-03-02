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
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Base directory (repository root)
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# Parse arguments
ENVIRONMENT="dev"  # Default to dev environment
if [ $# -gt 0 ]; then
  ENVIRONMENT="$1"
fi

echo "=================================================================="
echo -e "${BOLD}Running Terraform Plan Verification for ${YELLOW}$ENVIRONMENT${NC} environment${BOLD}${NC}"
echo "=================================================================="

# Validate environment
case "$ENVIRONMENT" in
  dev|staging|prod)
    echo -e "Testing environment: ${BLUE}$ENVIRONMENT${NC}"
    ;;
  *)
    echo -e "${RED}Invalid environment: $ENVIRONMENT. Use dev, staging, or prod.${NC}"
    exit 1
    ;;
esac

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform is not installed.${NC}"
    exit 1
fi

# Go to environment directory
cd "$REPO_ROOT/terraform/$ENVIRONMENT"

# Initialize terraform with backend disabled (for test environment)
echo -e "\nInitializing Terraform..."
if ! terraform init -backend=false -no-color > /dev/null; then
    echo -e "${RED}Failed to initialize Terraform.${NC}"
    exit 1
fi

# Generate a plan
echo -e "\nGenerating Terraform plan..."
terraform plan -no-color -out=tfplan > plan_output.txt

# Show the plan in a readable format
echo -e "\nPlan output:"
terraform show -no-color tfplan > plan_display.txt
cat plan_display.txt

# Verify expected resources are in the plan
echo -e "\nVerifying plan contains expected resources..."

# Required resources to check - these are the core resources we expect to see
REQUIRED_RESOURCES=(
  "aws_vpc"
  "aws_subnet"
  "aws_internet_gateway"
  "aws_route_table"
  "aws_security_group"
)

MISSING_RESOURCES=()

for resource in "${REQUIRED_RESOURCES[@]}"; do
  if ! grep -q "$resource" plan_display.txt; then
    echo -e "${RED}Required resource not found in plan: $resource${NC}"
    MISSING_RESOURCES+=("$resource")
  else
    echo -e "${GREEN}Found required resource: $resource${NC}"
  fi
done

# Check plan statistics
RESOURCES_TO_ADD=$(grep -oP 'Plan: \K\d+ to add' plan_display.txt || echo "0")
RESOURCES_TO_CHANGE=$(grep -oP '\K\d+ to change' plan_display.txt || echo "0")
RESOURCES_TO_DESTROY=$(grep -oP '\K\d+ to destroy' plan_display.txt || echo "0")

echo -e "\nPlan statistics:"
echo "Resources to add: $RESOURCES_TO_ADD"
echo "Resources to change: $RESOURCES_TO_CHANGE"
echo "Resources to destroy: $RESOURCES_TO_DESTROY"

# Clean up
rm -f tfplan plan_output.txt plan_display.txt

# Check if any required resources were missing
if [ ${#MISSING_RESOURCES[@]} -gt 0 ]; then
  echo -e "\n${RED}${BOLD}✖ Terraform plan verification failed.${NC}"
  echo -e "${RED}The following required resources were missing from the plan:${NC}"
  for resource in "${MISSING_RESOURCES[@]}"; do
    echo -e "${RED}- $resource${NC}"
  done
  exit 1
else
  echo -e "\n${GREEN}${BOLD}✓ Terraform plan verification passed!${NC}"
  echo -e "${GREEN}All required resources are included in the plan.${NC}"
  exit 0
fi 