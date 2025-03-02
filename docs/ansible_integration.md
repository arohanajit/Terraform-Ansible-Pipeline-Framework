# Ansible Integration

This document describes the Ansible integration with Terraform in our infrastructure pipeline.

## Overview

The Ansible integration phase allows for configuration management of the infrastructure provisioned by Terraform. This includes:

1. Converting Terraform outputs to Ansible inventory
2. Role-based configuration of different server types
3. Automated testing and deployment of configurations
4. Idempotency checks to ensure consistent state

## Directory Structure

```
ansible/
├── ansible.cfg                 # Ansible configuration
├── inventory/                  # Inventory files
│   ├── dev/                    # Development environment inventory
│   ├── staging/                # Staging environment inventory
│   └── prod/                   # Production environment inventory
│       └── hosts.yml           # Production hosts inventory
├── playbooks/                  # Playbooks for different environments
│   ├── dev/                    # Development environment playbooks
│   ├── staging/                # Staging environment playbooks
│   └── prod/                   # Production environment playbooks
│       ├── site.yml            # Main production playbook
│       ├── webservers.yml      # Webserver configuration playbook
│       ├── appservers.yml      # Application server configuration playbook
│       ├── dbservers.yml       # Database server configuration playbook
│       └── monitoring.yml      # Monitoring server configuration playbook
└── roles/                      # Roles for different server types
    ├── dev/                    # Development environment roles
    ├── staging/                # Staging environment roles
    └── prod/                   # Production environment roles
        ├── webserver/          # Webserver role
        │   ├── defaults/       # Default variables
        │   ├── handlers/       # Handlers
        │   └── tasks/          # Tasks
        ├── appserver/          # Application server role
        │   ├── defaults/       # Default variables
        │   ├── handlers/       # Handlers
        │   └── tasks/          # Tasks
        ├── database/           # Database server role
        │   ├── defaults/       # Default variables
        │   ├── handlers/       # Handlers
        │   └── tasks/          # Tasks
        └── monitoring/         # Monitoring server role
            ├── defaults/       # Default variables
            ├── handlers/       # Handlers
            └── tasks/          # Tasks
```

## Terraform Output Integration

Terraform outputs are converted to Ansible inventory using the `terraform_to_ansible_inventory.py` script. This script:

1. Reads Terraform output JSON
2. Converts it to Ansible inventory YAML format
3. Organizes hosts into appropriate groups
4. Sets environment-specific variables

## Role-Based Configuration

Each server type has a dedicated role with:

- **Tasks**: Configuration steps to be performed
- **Handlers**: Actions triggered by task notifications
- **Defaults**: Default variable values
- **Templates**: Configuration file templates

## Pipeline Integration

The Ansible integration is part of the CI/CD pipeline with the following stages:

1. **Ansible Lint**: Static code analysis for Ansible files
2. **Syntax Check**: Validates playbook syntax
3. **Terraform Integration**: Converts Terraform outputs to Ansible inventory
4. **Dry Run**: Executes playbooks in check mode
5. **Configuration Application**: Applies configurations to servers
6. **Idempotency Check**: Verifies that repeated runs don't make changes

## Usage

### Manual Execution

To manually run the Terraform-Ansible integration:

```bash
./scripts/terraform_ansible_integration.sh --env prod
```

Options:
- `--env`: Environment (dev, staging, prod)
- `--check-only`: Run in check mode without making changes
- `--help`: Show help message

### CI/CD Pipeline

The integration is automatically triggered in the CI/CD pipeline:
- On pull requests: Syntax and lint checks are performed
- On merge to develop: Dry run is performed
- On merge to main: Full configuration is applied

## Testing

Recommended testing approaches:

1. **Syntax Check**: `ansible-playbook --syntax-check playbook.yml`
2. **Dry Run**: `ansible-playbook --check --diff playbook.yml`
3. **Idempotency Test**: Run playbook twice and verify no changes on second run 