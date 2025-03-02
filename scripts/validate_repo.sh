#!/bin/bash
#
# Repository Validation Script
# This script verifies that the required directories and files exist in the repository
#

set -e

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Define the repository root directory
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Define required directories and files
REQUIRED_DIRS=(
  "terraform"
  "terraform/dev"
  "terraform/staging"
  "terraform/prod"
  "ansible"
  "ansible/inventory"
  "ansible/playbooks"
  "ansible/roles"
  "scripts"
  ".github/workflows"
)

REQUIRED_FILES=(
  "terraform/dev/main.tf"
  "terraform/staging/main.tf"
  "terraform/prod/main.tf"
  "ansible/ansible.cfg"
  "ansible/inventory/dev/hosts.yml"
  "ansible/inventory/staging/hosts.yml"
  "ansible/inventory/prod/hosts.yml"
  "ansible/playbooks/site.yml"
  ".github/workflows/terraform-validate.yml"
  ".github/workflows/ansible-lint.yml"
  ".gitignore"
  "README.md"
)

# Function to check if a directory exists
check_directory() {
  local dir="$1"
  if [ -d "$REPO_ROOT/$dir" ]; then
    echo -e "${GREEN}✓${NC} Directory exists: $dir"
    return 0
  else
    echo -e "${RED}✗${NC} Directory missing: $dir"
    return 1
  fi
}

# Function to check if a file exists
check_file() {
  local file="$1"
  if [ -f "$REPO_ROOT/$file" ]; then
    echo -e "${GREEN}✓${NC} File exists: $file"
    return 0
  else
    echo -e "${RED}✗${NC} File missing: $file"
    return 1
  fi
}

# Main validation function
validate_repository() {
  local errors=0
  
  echo "==================================================================="
  echo "Validating Repository Structure"
  echo "==================================================================="
  
  echo -e "\n${YELLOW}Checking required directories:${NC}"
  for dir in "${REQUIRED_DIRS[@]}"; do
    check_directory "$dir" || ((errors++))
  done
  
  echo -e "\n${YELLOW}Checking required files:${NC}"
  for file in "${REQUIRED_FILES[@]}"; do
    check_file "$file" || ((errors++))
  done
  
  echo -e "\n==================================================================="
  if [ $errors -eq 0 ]; then
    echo -e "${GREEN}Repository validation passed! All required directories and files exist.${NC}"
    return 0
  else
    echo -e "${RED}Repository validation failed! $errors issues found.${NC}"
    return 1
  fi
}

# Execute validation
validate_repository
exit $? 