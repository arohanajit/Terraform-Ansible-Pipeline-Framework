#!/bin/bash
#
# Terraform State Isolation Test
# Verifies that each environment uses a separate state file
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

ENVIRONMENTS=("dev" "staging" "prod")
FAILED=false

echo "=================================================================="
echo -e "${BOLD}Running Terraform State Isolation Test${NC}"
echo "=================================================================="

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform is not installed.${NC}"
    exit 1
fi

# Create a temporary directory to store backend configs
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

echo -e "Checking state configuration for each environment...\n"

# Check state configuration for each environment
for env in "${ENVIRONMENTS[@]}"; do
    echo -e "${YELLOW}Checking $env environment...${NC}"
    
    # Go to environment directory
    cd "$REPO_ROOT/terraform/$env"
    
    # Extract backend configuration
    echo "Extracting backend configuration..."
    if ! grep -q "backend" *.tf; then
        echo -e "${RED}No backend configuration found in $env environment.${NC}"
        FAILED=true
        continue
    fi
    
    # Verify backend type (should be S3 for this implementation)
    if ! grep -q "backend \"s3\"" *.tf; then
        echo -e "${RED}Backend is not configured to use S3 in $env environment.${NC}"
        FAILED=true
        continue
    fi
    
    # Extract key path from backend configuration
    KEY_PATH=$(grep -A 10 "backend \"s3\"" *.tf | grep "key" | sed -E 's/.*key[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/')
    
    if [ -z "$KEY_PATH" ]; then
        echo -e "${RED}Could not extract state file key path for $env environment.${NC}"
        FAILED=true
        continue
    fi
    
    echo "State file key path: $KEY_PATH"
    
    # Store key path for later comparison
    echo "$KEY_PATH" > "$TEMP_DIR/$env-key-path"
done

# Compare state paths to ensure they are different
echo -e "\nComparing state paths across environments..."

for (( i=0; i<${#ENVIRONMENTS[@]}; i++ )); do
    for (( j=i+1; j<${#ENVIRONMENTS[@]}; j++ )); do
        ENV1="${ENVIRONMENTS[$i]}"
        ENV2="${ENVIRONMENTS[$j]}"
        
        KEY_PATH1=$(cat "$TEMP_DIR/$ENV1-key-path")
        KEY_PATH2=$(cat "$TEMP_DIR/$ENV2-key-path")
        
        echo "Comparing $ENV1 and $ENV2 state paths..."
        
        if [ "$KEY_PATH1" == "$KEY_PATH2" ]; then
            echo -e "${RED}Error: $ENV1 and $ENV2 environments use the same state file path: $KEY_PATH1${NC}"
            FAILED=true
        else
            echo -e "${GREEN}$ENV1 and $ENV2 use different state file paths:${NC}"
            echo -e "  $ENV1: $KEY_PATH1"
            echo -e "  $ENV2: $KEY_PATH2"
        fi
    done
done

# Return to repo root
cd "$REPO_ROOT"

# Check for state locking
echo -e "\nChecking for state locking mechanism..."
for env in "${ENVIRONMENTS[@]}"; do
    cd "$REPO_ROOT/terraform/$env"
    
    if ! grep -q "dynamodb_table" *.tf; then
        echo -e "${RED}No DynamoDB table configured for state locking in $env environment.${NC}"
        FAILED=true
    else
        LOCK_TABLE=$(grep -A 10 "backend \"s3\"" *.tf | grep "dynamodb_table" | sed -E 's/.*dynamodb_table[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/')
        echo -e "${GREEN}$env environment uses DynamoDB table for locking: $LOCK_TABLE${NC}"
    fi
done

# Return to repo root
cd "$REPO_ROOT"

if [ "$FAILED" = true ]; then
    echo -e "\n${RED}${BOLD}✖ Terraform state isolation test failed.${NC}"
    echo -e "${RED}Each environment must use a separate state file with proper locking mechanism.${NC}"
    exit 1
else
    echo -e "\n${GREEN}${BOLD}✓ Terraform state isolation test passed!${NC}"
    echo -e "${GREEN}All environments are using separate state files with proper locking.${NC}"
    exit 0
fi 