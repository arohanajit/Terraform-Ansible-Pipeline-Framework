#!/bin/bash
#
# Repository Structure Validation Script
# Verifies that all required directories and key files exist in the repository
#

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Base directory (repository root)
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Required directories
REQUIRED_DIRS=(
    "terraform"
    "terraform/dev"
    "terraform/staging"
    "terraform/prod"
    "ansible"
    "ansible/inventory"
    "ansible/inventory/dev"
    "ansible/inventory/staging"
    "ansible/inventory/prod"
    "ansible/playbooks"
    "scripts"
    ".github/workflows"
)

# Required files
REQUIRED_FILES=(
    ".gitignore"
    "README.md"
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
)

echo "========================================================"
echo "        Repository Structure Validation Test"
echo "========================================================"

# Check required directories
echo -e "\nChecking required directories..."
MISSING_DIRS=0

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$REPO_ROOT/$dir" ]; then
        echo -e "✅ ${GREEN}Found directory:${NC} $dir"
    else
        echo -e "❌ ${RED}Missing directory:${NC} $dir"
        MISSING_DIRS=$((MISSING_DIRS + 1))
    fi
done

# Check required files
echo -e "\nChecking required files..."
MISSING_FILES=0

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$REPO_ROOT/$file" ]; then
        echo -e "✅ ${GREEN}Found file:${NC} $file"
    else
        echo -e "❌ ${RED}Missing file:${NC} $file"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done

# Print summary
echo -e "\n========================================================"
echo "                      SUMMARY"
echo "========================================================"
echo "Directories: $((${#REQUIRED_DIRS[@]} - MISSING_DIRS))/${#REQUIRED_DIRS[@]} found"
echo "Files: $((${#REQUIRED_FILES[@]} - MISSING_FILES))/${#REQUIRED_FILES[@]} found"

# Check if any items are missing
if [ $MISSING_DIRS -gt 0 ] || [ $MISSING_FILES -gt 0 ]; then
    echo -e "\n${RED}VALIDATION FAILED:${NC} Some required items are missing"
    echo -e "Please create the missing directories and files."
    exit 1
else
    echo -e "\n${GREEN}VALIDATION PASSED:${NC} All required directories and files exist!"
fi 