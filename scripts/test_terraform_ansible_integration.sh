#!/bin/bash
#
# Terraform-Ansible Integration Test
# Tests the integration between Terraform outputs and Ansible inventory
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

# Activate virtual environment if it exists and we're not already in it
if [ -f "$REPO_ROOT/venv/bin/activate" ] && [ -z "$VIRTUAL_ENV" ]; then
    echo -e "${BLUE}Activating Python virtual environment...${NC}"
    source "$REPO_ROOT/venv/bin/activate"
    DEACTIVATE_VENV=true
fi

# Check for required Python packages
if ! python3 -c "import yaml" &> /dev/null; then
    echo -e "${YELLOW}PyYAML package not found. Please ensure it's installed.${NC}"
    echo -e "${YELLOW}You can install it with: python -m pip install pyyaml${NC}"
    exit 1
fi

if ! command -v ansible-inventory &> /dev/null; then
    echo -e "${YELLOW}ansible-inventory command not found. Please ensure Ansible is installed.${NC}"
    echo -e "${YELLOW}You can install it with: python -m pip install ansible${NC}"
    exit 1
fi

echo -e "${BLUE}Testing Terraform-Ansible integration...${NC}"

# Environments to test
ENVIRONMENTS=("prod" "dev" "staging")

# Test environment (using the first available environment)
TEST_ENV=""
for ENV in "${ENVIRONMENTS[@]}"; do
    if [ -d "$REPO_ROOT/terraform/$ENV" ] && [ -d "$REPO_ROOT/ansible/playbooks/$ENV" ]; then
        TEST_ENV="$ENV"
        break
    fi
done

if [ -z "$TEST_ENV" ]; then
    echo -e "${RED}❌ No valid environment found for testing${NC}"
    # Deactivate virtual environment if we activated it
    if [ "$DEACTIVATE_VENV" = true ]; then
        deactivate
    fi
    exit 1
fi

echo -e "Using ${YELLOW}$TEST_ENV${NC} environment for testing"

# Create a temporary directory for test files
TEMP_DIR=$(mktemp -d)
echo -e "Using temporary directory: ${YELLOW}$TEMP_DIR${NC}"

# Create a test Terraform output file
echo -e "\n${BLUE}Creating sample Terraform output for testing...${NC}"
cat > "$TEMP_DIR/terraform_output.json" << EOF
{
  "webserver_ips": {
    "sensitive": false,
    "type": ["list", "string"],
    "value": ["192.168.1.10", "192.168.1.11", "192.168.1.12"]
  },
  "appserver_ips": {
    "sensitive": false,
    "type": ["list", "string"],
    "value": ["192.168.2.10", "192.168.2.11"]
  },
  "dbserver_ips": {
    "sensitive": false,
    "type": ["list", "string"],
    "value": ["192.168.3.10"]
  },
  "database_primary_ip": {
    "sensitive": false,
    "type": "string",
    "value": "192.168.3.20"
  },
  "database_replica_ips": {
    "sensitive": false,
    "type": ["list", "string"],
    "value": ["192.168.3.21", "192.168.3.22"]
  },
  "monitoring_ips": {
    "sensitive": false,
    "type": ["list", "string"],
    "value": ["192.168.4.10"]
  }
}
EOF

# Ensure the inventory directory exists
mkdir -p "$REPO_ROOT/ansible/inventory/$TEST_ENV"

# Run the inventory conversion script
echo -e "\n${BLUE}Converting Terraform output to Ansible inventory...${NC}"
python3 "$REPO_ROOT/scripts/inventory/terraform_to_ansible_inventory.py" \
  --env "$TEST_ENV" \
  --tf-output "$TEMP_DIR/terraform_output.json" \
  --output "$TEMP_DIR/hosts.yml"

# Check if the inventory file was created
if [ ! -f "$TEMP_DIR/hosts.yml" ]; then
    echo -e "${RED}❌ Failed to create Ansible inventory file${NC}"
    rm -rf "$TEMP_DIR"
    # Deactivate virtual environment if we activated it
    if [ "$DEACTIVATE_VENV" = true ]; then
        deactivate
    fi
    exit 1
fi

# Validate that the inventory contains the expected groups
echo -e "\n${BLUE}Validating generated inventory...${NC}"

VALIDATION_PASSED=true
FAILED_VALIDATIONS=()

# Function to check if a string exists in a file
check_in_file() {
    local pattern="$1"
    local file="$2"
    local description="$3"
    
    if grep -q "$pattern" "$file"; then
        echo -e "${GREEN}✅ $description found in inventory${NC}"
        return 0
    else
        echo -e "${RED}❌ $description not found in inventory${NC}"
        VALIDATION_PASSED=false
        FAILED_VALIDATIONS+=("$description not found in inventory")
        return 1
    fi
}

# Check for expected inventory content
check_in_file "webservers:" "$TEMP_DIR/hosts.yml" "Webservers group"
check_in_file "appservers:" "$TEMP_DIR/hosts.yml" "Appservers group"
check_in_file "dbservers:" "$TEMP_DIR/hosts.yml" "DBservers group"
check_in_file "databases:" "$TEMP_DIR/hosts.yml" "Databases group"
check_in_file "monitoring:" "$TEMP_DIR/hosts.yml" "Monitoring group"
check_in_file "primary:" "$TEMP_DIR/hosts.yml" "Primary database group"
check_in_file "replicas:" "$TEMP_DIR/hosts.yml" "Replica databases group"
check_in_file "ansible_user:" "$TEMP_DIR/hosts.yml" "Ansible user variable"
check_in_file "environment: $TEST_ENV" "$TEMP_DIR/hosts.yml" "Environment variable"

# Validate the inventory file with Ansible
echo -e "\n${BLUE}Validating inventory with Ansible...${NC}"
if ansible-inventory -i "$TEMP_DIR/hosts.yml" --list > /dev/null; then
    echo -e "${GREEN}✅ Ansible can parse the inventory file${NC}"
else
    echo -e "${RED}❌ Ansible cannot parse the inventory file${NC}"
    VALIDATION_PASSED=false
    FAILED_VALIDATIONS+=("Ansible cannot parse the inventory file")
fi

# Check if the terraform_ansible_integration.sh script exists and is executable
if [ -f "$REPO_ROOT/scripts/terraform_ansible_integration.sh" ]; then
    if [ -x "$REPO_ROOT/scripts/terraform_ansible_integration.sh" ]; then
        echo -e "${GREEN}✅ terraform_ansible_integration.sh is executable${NC}"
    else
        echo -e "${YELLOW}⚠️ terraform_ansible_integration.sh exists but is not executable${NC}"
        chmod +x "$REPO_ROOT/scripts/terraform_ansible_integration.sh"
        echo -e "${GREEN}✅ Made terraform_ansible_integration.sh executable${NC}"
    fi
else
    echo -e "${RED}❌ terraform_ansible_integration.sh does not exist${NC}"
    VALIDATION_PASSED=false
    FAILED_VALIDATIONS+=("terraform_ansible_integration.sh script not found")
fi

# Print summary
echo -e "\n=================================================================="
echo -e "${BOLD}Terraform-Ansible Integration Test Summary${NC}"
echo "=================================================================="

if [ "${#FAILED_VALIDATIONS[@]}" -gt 0 ]; then
    echo -e "\n${RED}Failed validations:${NC}"
    for validation in "${FAILED_VALIDATIONS[@]}"; do
        echo -e "  - $validation"
    done
fi

# Create a test report
REPORT_FILE="reports/terraform_ansible_integration_$(date +%Y%m%d%H%M%S).txt"
{
    echo "TERRAFORM-ANSIBLE INTEGRATION TEST REPORT"
    echo "=========================================="
    echo "Run date: $(date)"
    echo "Test environment: $TEST_ENV"
    echo ""
    echo "SUMMARY"
    echo "-------"
    if [ "$VALIDATION_PASSED" = true ]; then
        echo "Test status: PASSED"
    else
        echo "Test status: FAILED"
    fi
    echo ""
    if [ "${#FAILED_VALIDATIONS[@]}" -gt 0 ]; then
        echo "Failed validations:"
        for validation in "${FAILED_VALIDATIONS[@]}"; do
            echo "  - $validation"
        done
    else
        echo "All validations passed successfully!"
    fi
    
    echo ""
    echo "GENERATED INVENTORY"
    echo "------------------"
    cat "$TEMP_DIR/hosts.yml"
} > "$REPORT_FILE"

echo -e "Test report saved to: ${YELLOW}$REPORT_FILE${NC}"

# Clean up
rm -rf "$TEMP_DIR"

# Deactivate virtual environment if we activated it
if [ "$DEACTIVATE_VENV" = true ]; then
    deactivate
fi

# Exit with appropriate status code
if [ "$VALIDATION_PASSED" = true ]; then
    echo -e "\n${GREEN}✅ Terraform-Ansible integration test passed!${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Terraform-Ansible integration test failed! See details above.${NC}"
    exit 1
fi 