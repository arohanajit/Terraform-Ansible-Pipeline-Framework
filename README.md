# Terraform-Ansible-Pipeline-Framework

A comprehensive infrastructure-as-code framework combining Terraform for provisioning and Ansible for configuration management, with integrated CI/CD pipeline support.

## Repository Structure

- `/terraform`: Contains all Terraform code for infrastructure provisioning
  - Organized by environments (dev, staging, prod)
  - Modular structure for reusable components

- `/ansible`: Contains Ansible playbooks and roles for configuration management
  - Playbooks organized by purpose
  - Roles for different system configurations

- `/scripts`: Utility scripts for automation and management
  - Deployment helpers
  - Environment setup scripts
  - Maintenance utilities

- `/ci`: CI/CD configuration files
  - Pipeline definitions
  - Build configurations
  - Testing frameworks

- `/docs`: Documentation files
  - Testing strategy
  - Architecture diagrams
  - User guides

## Environment Configuration

This framework supports multiple environments:
- Development
- Staging
- Production

Each environment has its own configuration files located in the respective directories.

## Getting Started

1. Clone this repository
2. Navigate to the appropriate directory for your task:
   - Use `/terraform` for infrastructure provisioning
   - Use `/ansible` for configuration management
3. Follow the specific README in each directory for detailed instructions

## CI/CD Pipeline

The CI/CD pipeline is configured to:
- Validate code on commit
- Run tests for infrastructure changes
- Deploy to the appropriate environment based on the branch

## Testing Framework

The framework includes several validation tests to ensure code quality and correctness:

1. **Repository Structure Validation**: Verifies that all required directories and files exist
   ```bash
   ./scripts/validate_repo.sh
   ```

2. **Configuration Parsing Test**: Ensures all configuration files are correctly formatted
   ```bash
   ./scripts/validate_configs.sh
   ```

3. **CI/CD Connection Test**: Confirms that the CI/CD pipeline can successfully connect
   - Automatically runs on push to main/develop branches
   - Can be manually triggered in GitHub Actions

For more details on testing, see [Testing Documentation](docs/testing.md).

## Deployment

To deploy infrastructure and configure it:

```bash
./scripts/deploy.sh --environment dev --action apply
```

Options:
- `--environment` (or `-e`): dev, staging, prod
- `--action` (or `-a`): plan, apply, destroy
- `--skip-ansible` (or `-s`): Skip Ansible configuration

## Contributing

1. Create a feature branch from `main`
2. Make your changes
3. Submit a pull request

## License

[Specify your license here]