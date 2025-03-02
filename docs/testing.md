# Testing Strategy for Terraform-Ansible Pipeline Framework

This document outlines the testing strategy for the Terraform-Ansible Pipeline Framework, including the types of tests implemented, how to run them, and how to interpret the results.

## Testing Objectives

The testing framework aims to ensure:

1. **Repository Structure Integrity**: Verify that all required directories and files exist
2. **CI/CD Connection**: Confirm that the CI/CD pipeline can successfully connect and execute commands
3. **Configuration Validation**: Ensure all configuration files are correctly formatted and syntactically valid

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

**Expected output**:
- Success: "Repository validation passed! All required directories and files exist."
- Failure: "Repository validation failed! X issues found." (with details about missing items)

### 2. CI/CD Connection Test

This test verifies that the CI/CD pipeline can successfully connect to the repository and execute basic commands.

**Workflow**: `.github/workflows/ci-connection-test.yml`

**What it checks**:
- Ability to check out the code
- Ability to run the repository validation script
- Access to environment variables
- Ability to execute system commands

**How to run**:
- Automatically triggered on push to main/develop branches
- Manually triggered via GitHub Actions UI

**Expected output**:
- Success: All steps complete without errors
- Failure: One or more steps fail with specific error messages

### 3. Configuration Parsing Test

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

**Expected output**:
- Success: "Configuration parsing test passed! All configuration files are correctly formatted."
- Failure: "Configuration parsing test failed!" (with details about errors)

### 4. Comprehensive Validation Tests

A GitHub Actions workflow that runs all the above tests in sequence.

**Workflow**: `.github/workflows/validation-tests.yml`

**What it checks**:
- Repository structure
- Terraform configuration for all environments
- Ansible configuration

**How to run**:
- Automatically triggered on push to main/develop branches
- Manually triggered via GitHub Actions UI

**Expected output**:
- Success: All jobs complete without errors
- Failure: One or more jobs fail with specific error messages

## Interpreting Test Results

### Success Criteria

All tests should pass with no errors. This indicates that:
- The repository structure is correct
- All configuration files are syntactically valid
- The CI/CD pipeline can successfully connect and execute commands

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

## Adding New Tests

To add new tests to the framework:

1. Create a new test script in the `scripts` directory
2. Update the GitHub Actions workflows to include the new test
3. Document the new test in this file

## Continuous Integration

All tests are automatically run as part of the CI/CD pipeline on:
- Every push to the main and develop branches
- Every pull request to these branches

This ensures that any changes to the codebase are validated before they are merged.

## Running All Tests

For convenience, a main test runner script is provided that runs all validation tests in sequence.

**Script**: `scripts/run_all_tests.sh`

**What it does**:
- Automatically runs all available test scripts in sequence
- Reports which tests passed and which failed
- Continues running all tests even if some fail
- Generates a comprehensive test report in the `reports` directory

**How to run**:
```bash
./scripts/run_all_tests.sh
```

**Expected output**:
- A colored summary of all tests that were run
- The number of tests that passed and failed
- A list of any failed tests
- The location of the test report file

This is the recommended way to run all tests locally before pushing changes to the repository. 