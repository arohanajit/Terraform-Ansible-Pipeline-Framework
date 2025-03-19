#!/bin/bash
#
# Ansible Roles Validation Test
# Validates the structure and essential files of Ansible roles
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

echo -e "${BLUE}Validating Ansible roles structure...${NC}"

# Environments to check
ENVIRONMENTS=("prod" "dev" "staging")

# Required directories and files for each role
REQUIRED_DIRECTORIES=("tasks" "handlers" "defaults")
REQUIRED_FILES=("tasks/main.yml" "handlers/main.yml" "defaults/main.yml")

# Initialize validation status
VALIDATION_PASSED=true
FAILED_VALIDATIONS=()

# Check each environment
for ENV in "${ENVIRONMENTS[@]}"; do
    echo -e "\n${BOLD}Checking $ENV environment roles:${NC}"
    
    # Check if the environment roles directory exists
    if [ ! -d "$REPO_ROOT/ansible/roles/$ENV" ]; then
        echo -e "${YELLOW}⚠️ $ENV environment roles directory not found, skipping...${NC}"
        continue
    fi
    
    # Get all roles in this environment
    ROLES=$(find "$REPO_ROOT/ansible/roles/$ENV" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
    
    if [ -z "$ROLES" ]; then
        echo -e "${YELLOW}⚠️ No roles found in $ENV environment${NC}"
        continue
    fi
    
    # Check each role
    for ROLE in $ROLES; do
        echo -e "\n${BLUE}Validating role: $ROLE${NC}"
        ROLE_PATH="$REPO_ROOT/ansible/roles/$ENV/$ROLE"
        
        # Check required directories
        for DIR in "${REQUIRED_DIRECTORIES[@]}"; do
            if [ ! -d "$ROLE_PATH/$DIR" ]; then
                echo -e "${RED}❌ Required directory missing: $DIR${NC}"
                VALIDATION_PASSED=false
                FAILED_VALIDATIONS+=("$ENV/$ROLE: Missing directory $DIR")
            else
                echo -e "${GREEN}✅ Directory found: $DIR${NC}"
            fi
        done
        
        # Check required files
        for FILE in "${REQUIRED_FILES[@]}"; do
            if [ ! -f "$ROLE_PATH/$FILE" ]; then
                echo -e "${RED}❌ Required file missing: $FILE${NC}"
                VALIDATION_PASSED=false
                FAILED_VALIDATIONS+=("$ENV/$ROLE: Missing file $FILE")
            else
                echo -e "${GREEN}✅ File found: $FILE${NC}"
                
                # Check if the file is not empty
                if [ ! -s "$ROLE_PATH/$FILE" ]; then
                    echo -e "${YELLOW}⚠️ File is empty: $FILE${NC}"
                fi
            fi
        done
        
        # Verify that task files are properly formatted
        if [ -f "$ROLE_PATH/tasks/main.yml" ]; then
            # Check if the file starts with --- (YAML header)
            if ! grep -q "^---" "$ROLE_PATH/tasks/main.yml"; then
                echo -e "${RED}❌ tasks/main.yml is missing YAML header (---)${NC}"
                VALIDATION_PASSED=false
                FAILED_VALIDATIONS+=("$ENV/$ROLE: tasks/main.yml missing YAML header")
            fi
            
            # Check if file has at least one task
            if ! grep -q "name:" "$ROLE_PATH/tasks/main.yml"; then
                echo -e "${RED}❌ tasks/main.yml doesn't contain any named tasks${NC}"
                VALIDATION_PASSED=false
                FAILED_VALIDATIONS+=("$ENV/$ROLE: tasks/main.yml has no named tasks")
            fi
        fi
    done
done

# Check that at least one playbook is using the roles
PLAYBOOKS_USING_ROLES=0
for ENV in "${ENVIRONMENTS[@]}"; do
    PLAYBOOKS_DIR="$REPO_ROOT/ansible/playbooks/$ENV"
    
    if [ -d "$PLAYBOOKS_DIR" ]; then
        # Look for yaml/yml files that contain "roles:"
        PLAYBOOKS_WITH_ROLES=$(grep -l "roles:" "$PLAYBOOKS_DIR"/*.{yml,yaml} 2>/dev/null | wc -l)
        PLAYBOOKS_USING_ROLES=$((PLAYBOOKS_USING_ROLES + PLAYBOOKS_WITH_ROLES))
    fi
done

if [ "$PLAYBOOKS_USING_ROLES" -eq 0 ]; then
    echo -e "\n${RED}❌ No playbooks found that use roles${NC}"
    VALIDATION_PASSED=false
    FAILED_VALIDATIONS+=("No playbooks found that use roles")
else
    echo -e "\n${GREEN}✅ Found $PLAYBOOKS_USING_ROLES playbooks using roles${NC}"
fi

# Print summary
echo -e "\n=================================================================="
echo -e "${BOLD}Ansible Roles Validation Summary${NC}"
echo "=================================================================="

if [ "${#FAILED_VALIDATIONS[@]}" -gt 0 ]; then
    echo -e "\n${RED}Failed validations:${NC}"
    for validation in "${FAILED_VALIDATIONS[@]}"; do
        echo -e "  - $validation"
    done
fi

# Create validation report
REPORT_FILE="reports/ansible_roles_validation_$(date +%Y%m%d%H%M%S).txt"
{
    echo "ANSIBLE ROLES VALIDATION REPORT"
    echo "================================"
    echo "Run date: $(date)"
    echo ""
    echo "SUMMARY"
    echo "-------"
    if [ "$VALIDATION_PASSED" = true ]; then
        echo "Validation status: PASSED"
    else
        echo "Validation status: FAILED"
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
} > "$REPORT_FILE"

echo -e "Validation report saved to: ${YELLOW}$REPORT_FILE${NC}"

# Deactivate virtual environment if we activated it
if [ "$DEACTIVATE_VENV" = true ]; then
    deactivate
fi

# Exit with appropriate status code
if [ "$VALIDATION_PASSED" = true ]; then
    echo -e "\n${GREEN}✅ Ansible roles validation passed!${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Ansible roles validation failed! See details above.${NC}"
    exit 1
fi