# Test Scripts

This directory contains scripts for validating and testing the Terraform-Ansible Pipeline Framework.

## Available Scripts

### Main Test Runner

- **`run_all_tests.sh`**: Runs all validation tests in sequence and generates a comprehensive report.

### Individual Test Scripts

- **`validate_repo.sh`** or **`validate_repo_structure.sh`**: Validates the repository structure by checking for required directories and files.
- **`validate_configs.sh`**: Validates Terraform configurations and Ansible files for correct syntax and formatting.
- **`validate_config_files.sh`**: Alternative configuration validation script with more detailed output.
- **`test_cicd_connection.sh`**: Tests the CI/CD pipeline connection and generates a report.
- **`deploy.sh`**: Deployment script for deploying infrastructure using Terraform and configuring it with Ansible.

## Usage

### Running All Tests

For a complete validation of the framework, run:

```bash
./run_all_tests.sh
```

This will execute all test scripts in sequence, report which tests passed or failed, and generate a comprehensive test report in the `reports` directory.

### Running Individual Tests

You can also run individual test scripts:

```bash
./validate_repo.sh
./validate_configs.sh
./test_cicd_connection.sh
```

### Reports

All tests generate reports in the `reports` directory at the root of the repository. These reports include detailed information about the test run, including:

- Timestamp
- Environment information
- Test results
- Failure details (if any)

## Adding New Tests

When adding new test scripts:

1. Place the script in the `scripts` directory
2. Make it executable (`chmod +x scriptname.sh`)
3. Add it to the `run_all_tests.sh` script
4. Update the documentation in `docs/testing.md`

## Best Practices

- Always run the full test suite before pushing changes
- Fix any failing tests before deploying
- Keep the test scripts up to date with the repository structure

For more detailed information about the testing strategy, refer to the [Testing Documentation](../docs/testing.md). 