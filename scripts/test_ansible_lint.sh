#!/bin/bash
#
# Ansible Linting Test
# Validates Ansible playbooks and roles for syntax and style issues
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

echo -e "${BLUE}Running Ansible linting tests...${NC}"

# Check if ansible-lint is installed
if ! command -v ansible-lint &> /dev/null; then
    echo -e "${YELLOW}ansible-lint command not found. Please ensure ansible-lint is installed.${NC}"
    echo -e "${YELLOW}You can install it with: python -m pip install ansible-lint${NC}"
    exit 1
fi

# Create temporary directory for reports
TEMP_DIR=$(mktemp -d)
LINT_REPORT="$TEMP_DIR/ansible-lint-report.txt"

# Run ansible-lint
echo -e "${BLUE}Running ansible-lint on all playbooks and roles...${NC}"
ansible-lint ansible/ -p > "$LINT_REPORT" || true

# Check if there are any errors in the report
ERRORS_COUNT=$(grep -c "ERROR" "$LINT_REPORT" || true)
WARNINGS_COUNT=$(grep -c "WARNING" "$LINT_REPORT" || true)

# Display report summary
echo -e "\n${BOLD}Ansible Lint Results:${NC}"
echo "-------------------"
echo -e "Errors found: ${RED}$ERRORS_COUNT${NC}"
echo -e "Warnings found: ${YELLOW}$WARNINGS_COUNT${NC}"

# Display the lint results
if [ -s "$LINT_REPORT" ]; then
    echo -e "\n${BOLD}Lint Issues:${NC}"
    cat "$LINT_REPORT"
fi

# Copy report to reports directory
REPORT_FILE="reports/ansible_lint_$(date +%Y%m%d%H%M%S).txt"
cp "$LINT_REPORT" "$REPORT_FILE"
echo -e "\nDetailed lint report saved to: ${YELLOW}$REPORT_FILE${NC}"

# Clean up
rm -rf "$TEMP_DIR"

# Deactivate virtual environment if we activated it
if [ "$DEACTIVATE_VENV" = true ]; then
    deactivate
fi

# If there are errors, fail the test
if [ "$ERRORS_COUNT" -gt 0 ]; then
    echo -e "\n${RED}❌ Ansible linting test failed: $ERRORS_COUNT errors found${NC}"
    exit 1
else
    echo -e "\n${GREEN}✅ Ansible linting test passed: No critical errors found${NC}"
    # Warnings don't cause a test failure, but we report them
    if [ "$WARNINGS_COUNT" -gt 0 ]; then
        echo -e "${YELLOW}⚠️ $WARNINGS_COUNT warnings were found. Consider fixing them.${NC}"
    fi
    exit 0
fi 