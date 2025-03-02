#!/bin/bash
# Terraform and Ansible Integration Script
# This script integrates Terraform outputs with Ansible inventory and runs Ansible playbooks

set -e

# Default values
ENVIRONMENT="prod"
TERRAFORM_DIR="terraform/${ENVIRONMENT}"
ANSIBLE_DIR="ansible"
INVENTORY_DIR="${ANSIBLE_DIR}/inventory/${ENVIRONMENT}"
PLAYBOOK="${ANSIBLE_DIR}/playbooks/${ENVIRONMENT}/site.yml"
TERRAFORM_OUTPUT_FILE="terraform_output.json"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --env)
      ENVIRONMENT="$2"
      TERRAFORM_DIR="terraform/${ENVIRONMENT}"
      INVENTORY_DIR="${ANSIBLE_DIR}/inventory/${ENVIRONMENT}"
      PLAYBOOK="${ANSIBLE_DIR}/playbooks/${ENVIRONMENT}/site.yml"
      shift 2
      ;;
    --terraform-dir)
      TERRAFORM_DIR="$2"
      shift 2
      ;;
    --ansible-dir)
      ANSIBLE_DIR="$2"
      shift 2
      ;;
    --inventory-dir)
      INVENTORY_DIR="$2"
      shift 2
      ;;
    --playbook)
      PLAYBOOK="$2"
      shift 2
      ;;
    --check-only)
      CHECK_ONLY=true
      shift
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --env ENV                Environment (dev, staging, prod). Default: prod"
      echo "  --terraform-dir DIR      Terraform directory. Default: terraform/ENV"
      echo "  --ansible-dir DIR        Ansible directory. Default: ansible"
      echo "  --inventory-dir DIR      Ansible inventory directory. Default: ansible/inventory/ENV"
      echo "  --playbook FILE          Ansible playbook to run. Default: ansible/playbooks/ENV/site.yml"
      echo "  --check-only             Only run Ansible in check mode (dry run)"
      echo "  --help                   Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "=== Configuration ==="
echo "Environment: ${ENVIRONMENT}"
echo "Terraform directory: ${TERRAFORM_DIR}"
echo "Ansible directory: ${ANSIBLE_DIR}"
echo "Inventory directory: ${INVENTORY_DIR}"
echo "Playbook: ${PLAYBOOK}"
echo "Check only: ${CHECK_ONLY:-false}"
echo "===================="

# Ensure directories exist
mkdir -p "${INVENTORY_DIR}"

# Export Terraform outputs to JSON
echo "Exporting Terraform outputs to JSON..."
cd "${TERRAFORM_DIR}"
terraform output -json > "${TERRAFORM_OUTPUT_FILE}"
cd - > /dev/null

# Convert Terraform outputs to Ansible inventory
echo "Converting Terraform outputs to Ansible inventory..."
python3 scripts/inventory/terraform_to_ansible_inventory.py \
  --env "${ENVIRONMENT}" \
  --tf-output "${TERRAFORM_DIR}/${TERRAFORM_OUTPUT_FILE}" \
  --output "${INVENTORY_DIR}/hosts.yml"

# Verify Ansible inventory
echo "Verifying Ansible inventory..."
ansible-inventory -i "${INVENTORY_DIR}" --list

# Run Ansible syntax check
echo "Running Ansible syntax check..."
ansible-playbook -i "${INVENTORY_DIR}" "${PLAYBOOK}" --syntax-check

# Run Ansible playbook
if [ "${CHECK_ONLY}" = true ]; then
  echo "Running Ansible playbook in check mode (dry run)..."
  ansible-playbook -i "${INVENTORY_DIR}" "${PLAYBOOK}" --check --diff
else
  echo "Running Ansible playbook..."
  ansible-playbook -i "${INVENTORY_DIR}" "${PLAYBOOK}"
  
  # Run idempotency check
  echo "Running idempotency check..."
  ansible-playbook -i "${INVENTORY_DIR}" "${PLAYBOOK}" --diff | tee /tmp/idempotency_output.txt
  
  # Check if any changes were made during the second run
  if grep -q "changed=" /tmp/idempotency_output.txt && ! grep -q "changed=0" /tmp/idempotency_output.txt; then
    echo "Warning: Playbook is not idempotent. Changes were made during the second run."
    exit 1
  else
    echo "Success: Playbook is idempotent. No changes were made during the second run."
  fi
fi

echo "Integration completed successfully!" 