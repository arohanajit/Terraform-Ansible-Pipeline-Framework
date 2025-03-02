#!/bin/bash
#
# Terraform State Isolation Test
# Confirms each environment uses separate state
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

# Environments to test
ENVIRONMENTS=("dev" "staging" "prod")

echo "=================================================================="
echo -e "${YELLOW}Running Terraform State Isolation Test${NC}"
echo "=================================================================="

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform is not installed or not in PATH${NC}"
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${YELLOW}Warning: AWS CLI is not installed, skipping remote state checks${NC}"
    AWS_CLI_AVAILABLE=false
else
    AWS_CLI_AVAILABLE=true
fi

# Function to extract backend configuration
extract_backend_config() {
    local env=$1
    local config_file="$REPO_ROOT/terraform/$env/main.tf"
    
    if [ ! -f "$config_file" ]; then
        echo "File not found"
        return 1
    fi
    
    # Extract backend configuration
    local backend_type=$(grep -A 1 "backend" "$config_file" | grep -v "backend" | tr -d ' "{}')
    local backend_config=$(sed -n '/backend/,/}/p' "$config_file")
    
    echo "$backend_type"
    echo "$backend_config"
}

# Check backend configuration for each environment
declare -A BACKEND_CONFIGS
ISOLATION_ISSUES=()

for ENV in "${ENVIRONMENTS[@]}"; do
    echo -e "\nChecking ${YELLOW}$ENV${NC} environment..."
    
    if [ ! -d "$REPO_ROOT/terraform/$ENV" ]; then
        echo -e "${RED}Error: Directory terraform/$ENV does not exist${NC}"
        ISOLATION_ISSUES+=("$ENV (missing directory)")
        continue
    fi
    
    # Extract backend configuration
    BACKEND_CONFIG=$(extract_backend_config "$ENV")
    if [ "$BACKEND_CONFIG" == "File not found" ]; then
        echo -e "${RED}Error: Could not find main.tf for $ENV environment${NC}"
        ISOLATION_ISSUES+=("$ENV (missing main.tf)")
        continue
    fi
    
    # Check if backend is configured
    if ! echo "$BACKEND_CONFIG" | grep -q "backend"; then
        echo -e "${RED}Error: No backend configuration found for $ENV environment${NC}"
        ISOLATION_ISSUES+=("$ENV (no backend)")
        continue
    fi
    
    # Extract backend type
    BACKEND_TYPE=$(echo "$BACKEND_CONFIG" | grep -A 1 "backend" | grep -v "backend" | tr -d ' "{}')
    echo "Backend type: $BACKEND_TYPE"
    
    # Extract key for S3 backend
    if [ "$BACKEND_TYPE" == "s3" ]; then
        KEY=$(echo "$BACKEND_CONFIG" | grep "key" | cut -d '=' -f 2 | tr -d ' "')
        BUCKET=$(echo "$BACKEND_CONFIG" | grep "bucket" | cut -d '=' -f 2 | tr -d ' "')
        
        echo "State key: $KEY"
        echo "State bucket: $BUCKET"
        
        # Store for comparison
        BACKEND_CONFIGS["$ENV"]="$BUCKET:$KEY"
    fi
done

# Compare backend configurations to ensure they're different
DUPLICATE_FOUND=false
for i in "${!ENVIRONMENTS[@]}"; do
    for j in "${!ENVIRONMENTS[@]}"; do
        if [ $i -lt $j ]; then
            ENV1=${ENVIRONMENTS[$i]}
            ENV2=${ENVIRONMENTS[$j]}
            
            if [ -n "${BACKEND_CONFIGS[$ENV1]}" ] && [ -n "${BACKEND_CONFIGS[$ENV2]}" ]; then
                if [ "${BACKEND_CONFIGS[$ENV1]}" == "${BACKEND_CONFIGS[$ENV2]}" ]; then
                    echo -e "\n${RED}Error: $ENV1 and $ENV2 environments use the same state location:${NC}"
                    echo -e "  ${BACKEND_CONFIGS[$ENV1]}"
                    ISOLATION_ISSUES+=("$ENV1 and $ENV2 share state")
                    DUPLICATE_FOUND=true
                fi
            fi
        fi
    done
done

# Check if AWS CLI is available and verify S3 buckets
if [ "$AWS_CLI_AVAILABLE" = true ]; then
    echo -e "\nChecking S3 buckets for state files..."
    
    for ENV in "${ENVIRONMENTS[@]}"; do
        if [ -n "${BACKEND_CONFIGS[$ENV]}" ]; then
            BUCKET=$(echo "${BACKEND_CONFIGS[$ENV]}" | cut -d ':' -f 1)
            KEY=$(echo "${BACKEND_CONFIGS[$ENV]}" | cut -d ':' -f 2)
            
            # Check if bucket exists
            if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
                echo -e "${GREEN}✓ Bucket $BUCKET exists${NC}"
            else
                echo -e "${YELLOW}Warning: Bucket $BUCKET does not exist or is not accessible${NC}"
            fi
        fi
    done
fi

# Print summary
echo -e "\n=================================================================="
echo -e "Terraform State Isolation Test Summary"
echo "=================================================================="

if [ ${#ISOLATION_ISSUES[@]} -gt 0 ]; then
    echo -e "\n${RED}State isolation issues found:${NC}"
    for issue in "${ISOLATION_ISSUES[@]}"; do
        echo -e "  - $issue"
    done
    exit 1
else
    echo -e "\n${GREEN}✓ All environments use separate state configurations${NC}"
    exit 0
fi 