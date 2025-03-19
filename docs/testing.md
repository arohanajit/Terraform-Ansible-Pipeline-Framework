# Testing Strategy for Terraform-Ansible Pipeline Framework

This document outlines the testing strategy for the Terraform-Ansible Pipeline Framework, including the types of tests implemented, how to run them, and how to interpret the results.

## Testing Objectives

The testing framework aims to ensure:

1. **Repository Structure Integrity**: Verify that all required directories and files exist
2. **Configuration Validation**: Ensure all configuration files are correctly formatted and syntactically valid
3. **Infrastructure Verification**: Test Terraform plan and state management
4. **Ansible Configuration**: Validate Ansible playbooks and roles

## Test Organization

All tests are now organized in a consistent structure:

- **Repository validation tests**: Located in the project root's `scripts/` directory
- **Infrastructure and configuration tests**: Located in the `scripts/tests/` directory
- **Running all tests**: Simplified with the main test runner script

## Available Tests

### 1. Repository Validation Test

This test verifies that the required directory structure and key files exist in the repository.

**Script**: `scripts/validate_repo.sh`

**What it checks**:
- Presence of required directories (`terraform`, `ansible`, `scripts`, etc.)
- Presence of key files (configuration files, playbooks, etc.)

**How to run**:
```bash
./scripts/validate_repo.sh
```

### 2. Configuration Validation

This test verifies that all configuration files are correctly formatted and syntactically valid.

**Script**: `scripts/validate_configs.sh`

**What it checks**:
- Terraform configuration syntax for each environment
- Terraform formatting
- Ansible YAML syntax for inventory files and playbooks

**How to run**:
```bash
./scripts/validate_configs.sh
```

### 3. Terraform Tests

These tests verify Terraform configuration, plan generation, and state management.

**Scripts**: Located in `scripts/tests/` directory
- `test_terraform_validation.sh`: Validates Terraform syntax
- `test_terraform_plan.sh`: Validates Terraform plan generation
- `test_terraform_state_isolation.sh`: Tests state isolation between environments

**How to run individual tests**:
```bash
./scripts/tests/test_terraform_validation.sh
```

### 4. Ansible Tests

These tests verify Ansible playbooks, roles, and integration with Terraform.

**Scripts**: Located in `scripts/tests/` directory
- `test_ansible_lint.sh`: Lints Ansible files
- `test_ansible_roles.sh`: Validates Ansible roles
- `test_terraform_ansible_integration.sh`: Tests Terraform and Ansible integration

**How to run individual tests**:
```bash
./scripts/tests/test_ansible_lint.sh
```

## Running All Tests

For convenience, a main test runner script is provided that runs all validation tests in sequence.

**Script**: `scripts/run_all_tests.sh`

**What it does**:
- Automatically runs all test scripts in sequence
- Reports which tests passed and which failed
- Generates a comprehensive test report in the `reports` directory

**How to run**:
```bash
./scripts/run_all_tests.sh
```

## Interpreting Test Results

### Success Criteria

All tests should pass with no errors. This indicates that:
- The repository structure is correct
- All configuration files are syntactically valid
- Terraform plans can be generated correctly
- Ansible playbooks and roles are valid

### Common Failures and Remediation

1. **Missing Directories or Files**:
   - Check the error message to identify what's missing
   - Create the missing directories or files according to the repository structure

2. **Terraform Validation Errors**:
   - Check the Terraform configuration files for syntax errors
   - Ensure all required providers and modules are properly configured

3. **Terraform Formatting Errors**:
   - Run `terraform fmt` in the affected directory to fix formatting issues

4. **YAML Syntax Errors**:
   - Check the identified YAML files for syntax errors
   - Use a YAML validator to identify and fix issues

## Continuous Integration

All tests are automatically run as part of the CI/CD pipeline on:
- Every push to the main branch
- Every pull request

This ensures that any changes to the codebase are validated before they are merged. 