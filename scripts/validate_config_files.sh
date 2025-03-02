#!/bin/bash
#
# Configuration Files Validation Script
# Verifies that environment configuration files are correctly formatted
#

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Base directory (repository root)
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Environments to validate
ENVIRONMENTS=("dev" "staging" "prod")

echo "========================================================"
echo "       Configuration Files Validation Test"
echo "========================================================"

validation_failed=0

# Function to validate Terraform files
validate_terraform_files() {
    env=$1
    env_dir="$REPO_ROOT/terraform/$env"
    
    echo -e "\n${BLUE}Validating Terraform files for $env environment...${NC}"
    
    # Check if main.tf exists
    if [ ! -f "$env_dir/main.tf" ]; then
        echo -e "${RED}❌ Missing main.tf in $env environment${NC}"
        validation_failed=1
        return
    fi
    
    # Check if terraform.tfvars.example exists
    if [ ! -f "$env_dir/terraform.tfvars.example" ]; then
        echo -e "${YELLOW}⚠️ Warning: Missing terraform.tfvars.example in $env environment${NC}"
    fi
    
    # Validate Terraform syntax
    echo -e "Validating Terraform syntax for $env..."
    cd "$env_dir"
    
    if terraform validate -no-color -json; then
        echo -e "${GREEN}✅ Terraform validation passed for $env${NC}"
    else
        echo -e "${RED}❌ Terraform validation failed for $env${NC}"
        validation_failed=1
    fi
    
    # Return to the repository root
    cd "$REPO_ROOT"
}

# Function to validate Ansible inventory files
validate_ansible_inventory() {
    env=$1
    inventory_file="$REPO_ROOT/ansible/inventory/$env/hosts.yml"
    
    echo -e "\n${BLUE}Validating Ansible inventory for $env environment...${NC}"
    
    # Check if inventory file exists
    if [ ! -f "$inventory_file" ]; then
        echo -e "${RED}❌ Missing hosts.yml in $env environment${NC}"
        validation_failed=1
        return
    fi
    
    # Validate YAML syntax
    echo -e "Validating YAML syntax for $env inventory..."
    
    if command -v yamllint >/dev/null 2>&1; then
        # Try to validate with yamllint
        if yamllint -d relaxed "$inventory_file" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ YAML validation passed for $env inventory${NC}"
        else
            echo -e "${RED}❌ YAML validation failed for $env inventory${NC}"
            validation_failed=1
        fi
    elif command -v python3 >/dev/null 2>&1; then
        # If yamllint isn't available, try Python
        if python3 -c "import yaml; yaml.safe_load(open('$inventory_file'))" 2>/dev/null; then
            echo -e "${GREEN}✅ YAML validation passed for $env inventory${NC}"
        else
            echo -e "${RED}❌ YAML validation failed for $env inventory${NC}"
            validation_failed=1
        fi
    else
        echo -e "${YELLOW}⚠️ Warning: Cannot validate YAML syntax (requires Python or yamllint)${NC}"
    fi
}

# Validate configurations for each environment
for env in "${ENVIRONMENTS[@]}"; do
    echo -e "\n========================================================"
    echo "      Validating $env environment"
    echo "========================================================"
    
    validate_terraform_files "$env"
    validate_ansible_inventory "$env"
done

# Print summary
echo -e "\n========================================================"
echo "                      SUMMARY"
echo "========================================================"

if [ $validation_failed -eq 0 ]; then
    echo -e "${GREEN}✅ All configuration files are valid!${NC}"
    exit 0
else
    echo -e "${RED}❌ Validation failed for one or more configuration files.${NC}"
    echo -e "Please fix the issues listed above."
    exit 1
fi