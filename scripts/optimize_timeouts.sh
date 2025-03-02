#!/bin/bash
#
# Timeout Optimization Script
# This script analyzes test run reports and suggests optimal timeout values
#

set -e

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Define the repository root directory
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Default safety margin (multiplier) for timeouts
SAFETY_MARGIN=1.5

# Function to display usage information
display_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help             Display this help message"
    echo "  -m, --margin NUMBER    Set safety margin multiplier (default: 1.5)"
    echo "  -r, --report FILE      Specify a specific report file to analyze"
    echo ""
    echo "Description:"
    echo "  This script analyzes test execution times from previous runs and"
    echo "  recommends optimal timeout values for the run_all_tests.sh script."
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            display_usage
            exit 0
            ;;
        -m|--margin)
            SAFETY_MARGIN="$2"
            shift 2
            ;;
        -r|--report)
            SPECIFIC_REPORT="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            display_usage
            exit 1
            ;;
    esac
done

# Ensure the reports directory exists
if [ ! -d "$REPO_ROOT/reports" ]; then
    echo -e "${YELLOW}Warning: No reports directory found. No data to analyze.${NC}"
    exit 0
fi

# Find all report files
if [ -n "$SPECIFIC_REPORT" ]; then
    if [ -f "$REPO_ROOT/reports/$SPECIFIC_REPORT" ]; then
        REPORT_FILES=("$REPO_ROOT/reports/$SPECIFIC_REPORT")
    elif [ -f "$SPECIFIC_REPORT" ]; then
        REPORT_FILES=("$SPECIFIC_REPORT")
    else
        echo -e "${YELLOW}Error: Specified report file not found.${NC}"
        exit 1
    fi
else
    REPORT_FILES=("$REPO_ROOT"/reports/test_run_*.txt)
    if [ ${#REPORT_FILES[@]} -eq 0 ]; then
        echo -e "${YELLOW}No test reports found in the reports directory.${NC}"
        exit 0
    fi
fi

echo "=================================================================="
echo -e "${BOLD}Timeout Optimization Analysis${NC}"
echo "=================================================================="
echo "Analyzing test execution times from previous runs..."
echo "Safety margin multiplier: ${SAFETY_MARGIN}x"
echo ""

# Initialize data structures for test durations
declare -A test_durations
declare -A test_counts
declare -A max_durations
declare -A test_categories

# Extract test durations from reports
for report_file in "${REPORT_FILES[@]}"; do
    echo -e "Analyzing report: ${CYAN}$(basename "$report_file")${NC}"
    
    # Extract test durations using regex
    while read -r line; do
        if [[ $line =~ Test\ Passed:\ (.+)\ \(completed\ in\ ([0-9]+)s\) || 
              $line =~ Test\ Failed:\ (.+)\ \(completed\ in\ ([0-9]+)s\) ]]; then
            test_name="${BASH_REMATCH[1]}"
            duration="${BASH_REMATCH[2]}"
            
            # Clean up the test name (remove extra info)
            test_name=$(echo "$test_name" | sed -E 's/ \(.+\)$//')
            
            # Categorize the test
            if [[ "$test_name" == *"Terraform"* ]]; then
                test_categories["$test_name"]="terraform"
            elif [[ "$test_name" == *"Ansible"* ]]; then
                test_categories["$test_name"]="ansible"
            elif [[ "$test_name" == *"Validation"* || "$test_name" == *"Validate"* ]]; then
                test_categories["$test_name"]="validation"
            else
                test_categories["$test_name"]="default"
            fi
            
            # Update running totals
            test_durations["$test_name"]=$((test_durations["$test_name"] + duration))
            test_counts["$test_name"]=$((test_counts["$test_name"] + 1))
            
            # Update max duration if needed
            if [ -z "${max_durations[$test_name]}" ] || [ "$duration" -gt "${max_durations[$test_name]}" ]; then
                max_durations["$test_name"]=$duration
            fi
        fi
    done < "$report_file"
done

# Print analysis results
echo -e "\n${BOLD}Test Duration Analysis:${NC}"
printf "%-50s %-10s %-10s %-15s %-15s\n" "Test Name" "Avg (s)" "Max (s)" "Category" "Recommended (s)"

for test_name in "${!test_counts[@]}"; do
    avg_duration=$(( test_durations["$test_name"] / test_counts["$test_name"] ))
    max_duration=${max_durations["$test_name"]}
    category=${test_categories["$test_name"]}
    
    # Calculate recommended timeout with safety margin
    recommended_timeout=$(echo "$max_duration * $SAFETY_MARGIN" | bc | sed 's/\..*$//')
    if [ -z "$recommended_timeout" ] || [ "$recommended_timeout" -lt 30 ]; then
        recommended_timeout=30
    fi
    
    printf "%-50s %-10s %-10s %-15s %-15s\n" \
        "$test_name" \
        "$avg_duration" \
        "$max_duration" \
        "$category" \
        "$recommended_timeout"
done

# Generate recommended timeout values for run_all_tests.sh
echo -e "\n${BOLD}Recommended timeout settings for run_all_tests.sh:${NC}"

# Calculate category-based timeout recommendations
declare -A category_max_recommended
category_max_recommended["default"]=60
category_max_recommended["validation"]=60
category_max_recommended["terraform"]=300
category_max_recommended["ansible"]=180

for category in "default" "validation" "terraform" "ansible"; do
    max_value=0
    
    for test_name in "${!test_categories[@]}"; do
        if [ "${test_categories[$test_name]}" = "$category" ]; then
            max_duration=${max_durations["$test_name"]}
            if [ "$max_duration" -gt "$max_value" ]; then
                max_value=$max_duration
            fi
        fi
    done
    
    # Calculate recommended timeout with safety margin
    recommended_timeout=$(echo "$max_value * $SAFETY_MARGIN" | bc | sed 's/\..*$//')
    
    # Ensure a minimum reasonable timeout
    if [ -z "$recommended_timeout" ] || [ "$recommended_timeout" -lt 30 ]; then
        recommended_timeout=30
    fi
    
    # Update the category recommendation
    if [ "$recommended_timeout" -gt "${category_max_recommended[$category]}" ]; then
        category_max_recommended["$category"]=$recommended_timeout
    fi
done

# Output the recommended timeout variables to add to run_all_tests.sh
echo "# Default timeout values (in seconds)"
echo "DEFAULT_TIMEOUT=${category_max_recommended["default"]}  # Default timeout"
echo "TERRAFORM_TIMEOUT=${category_max_recommended["terraform"]}  # Terraform operations"
echo "ANSIBLE_TIMEOUT=${category_max_recommended["ansible"]}  # Ansible operations"
echo "VALIDATION_TIMEOUT=${category_max_recommended["validation"]}  # Validation operations"

echo -e "\nTo apply these recommendations, update the timeout values in scripts/run_all_tests.sh"
echo "or adjust individual test timeouts using the --timeout parameter."
echo -e "\nExample:\nrun_test \"Repository Validation\" \"\$REPO_ROOT/scripts/validate_repo.sh\" --timeout=${category_max_recommended["validation"]} || true"

exit 0 