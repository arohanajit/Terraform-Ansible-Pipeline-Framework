#!/bin/bash
#
# Configuration Parsing Test Script
# This script verifies that environment configuration files are correctly formatted
#

set -e

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Define the repository root directory
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Function to validate Terraform files
validate_terraform() {
  local env=$1
  local errors=0
  
  echo -e "\n${YELLOW}Validating Terraform configuration for $env environment:${NC}"
  
  # Check if directory exists
  if [ ! -d "terraform/$env" ]; then
    echo -e "${RED}✗${NC} Environment directory not found: terraform/$env"
    return 1
  fi
  
  # Initialize Terraform (without backend)
  echo "Initializing Terraform... (this may take a moment)"
  (cd "terraform/$env" && terraform init -backend=false -input=false -no-color) || {
    echo -e "${RED}✗${NC} Terraform initialization failed for $env environment"
    return 1
  }
  
  # Validate Terraform configuration
  echo "Validating Terraform configuration..."
  (cd "terraform/$env" && terraform validate -no-color) || {
    echo -e "${RED}✗${NC} Terraform validation failed for $env environment"
    return 1
  }
  
  # Check Terraform formatting
  echo "Checking Terraform formatting..."
  (cd "terraform/$env" && terraform fmt -check -no-color) || {
    echo -e "${RED}✗${NC} Terraform formatting check failed for $env environment"
    echo -e "${YELLOW}Hint:${NC} Run 'terraform fmt' to fix formatting issues"
    ((errors++))
  }
  
  if [ $errors -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Terraform configuration for $env environment is valid"
    return 0
  else
    echo -e "${RED}✗${NC} Terraform configuration for $env environment has formatting issues"
    return 1
  fi
}

# Function to validate Ansible files
validate_ansible() {
  local env=$1
  
  echo -e "\n${YELLOW}Validating Ansible configuration for $env environment:${NC}"
  
  # Check if inventory directory exists
  if [ ! -d "ansible/inventory/$env" ]; then
    echo -e "${RED}✗${NC} Environment inventory directory not found: ansible/inventory/$env"
    return 1
  fi
  
  # Check if hosts file exists
  if [ ! -f "ansible/inventory/$env/hosts.yml" ]; then
    echo -e "${RED}✗${NC} Hosts file not found: ansible/inventory/$env/hosts.yml"
    return 1
  fi
  
  # Validate YAML syntax of hosts file
  echo "Validating YAML syntax of hosts file..."
  if command -v yamllint >/dev/null 2>&1; then
    yamllint -d relaxed "ansible/inventory/$env/hosts.yml" >/dev/null 2>&1 || {
      echo -e "${RED}✗${NC} YAML syntax validation failed for ansible/inventory/$env/hosts.yml"
      return 1
    }
  else
    python3 -c "import yaml; yaml.safe_load(open('ansible/inventory/$env/hosts.yml'))" || {
      echo -e "${RED}✗${NC} YAML syntax validation failed for ansible/inventory/$env/hosts.yml"
      return 1
    }
  fi
  
  # Check if environment playbook exists
  if [ ! -f "ansible/playbooks/$env/main.yml" ]; then
    echo -e "${YELLOW}!${NC} Environment playbook not found: ansible/playbooks/$env/main.yml"
  else
    # Validate YAML syntax of playbook
    echo "Validating YAML syntax of playbook..."
    if command -v yamllint >/dev/null 2>&1; then
      yamllint -d relaxed "ansible/playbooks/$env/main.yml" >/dev/null 2>&1 || {
        echo -e "${RED}✗${NC} YAML syntax validation failed for ansible/playbooks/$env/main.yml"
        return 1
      }
    else
      python3 -c "import yaml; yaml.safe_load(open('ansible/playbooks/$env/main.yml'))" || {
        echo -e "${RED}✗${NC} YAML syntax validation failed for ansible/playbooks/$env/main.yml"
        return 1
      }
    fi
  fi
  
  echo -e "${GREEN}✓${NC} Ansible configuration for $env environment is valid"
  return 0
}

# Main function
main() {
  local terraform_errors=0
  local ansible_errors=0
  local start_time=$(date +%s)
  
  echo "==================================================================="
  echo "Configuration Parsing Test"
  echo "==================================================================="
  
  # Validate Terraform configurations
  for env in dev staging prod; do
    validate_terraform "$env" || ((terraform_errors++))
    echo -e "Progress: Completed Terraform validation for $env environment"
  done
  
  # Validate Ansible configurations
  for env in dev staging prod; do
    validate_ansible "$env" || ((ansible_errors++))
    echo -e "Progress: Completed Ansible validation for $env environment"
  done
  
  # Summary
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  
  echo -e "\n==================================================================="
  echo -e "Test completed in ${duration} seconds."
  if [ $terraform_errors -eq 0 ] && [ $ansible_errors -eq 0 ]; then
    echo -e "${GREEN}Configuration parsing test passed!${NC}"
    echo "All configuration files are correctly formatted."
    exit 0
  else
    echo -e "${RED}Configuration parsing test failed!${NC}"
    echo "Terraform errors: $terraform_errors"
    echo "Ansible errors: $ansible_errors"
    exit 1
  fi
}

# Execute main function
main 