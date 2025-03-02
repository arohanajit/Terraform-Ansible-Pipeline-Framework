#!/bin/bash
#
# Deployment script for Terraform-Ansible Pipeline Framework
# This script helps to deploy infrastructure using Terraform and configure it using Ansible
#

set -e

# Default values
ENVIRONMENT="dev"
ACTION="plan"
SKIP_ANSIBLE=false

# Display help information
function show_help {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -e, --environment ENV     Specify environment (dev, staging, prod) (default: dev)"
    echo "  -a, --action ACTION       Specify action (plan, apply, destroy) (default: plan)"
    echo "  -s, --skip-ansible        Skip Ansible configuration (default: false)"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --environment dev --action plan     # Plan changes for dev environment"
    echo "  $0 -e staging -a apply                # Apply changes to staging environment"
    echo "  $0 -e prod -a destroy                 # Destroy prod environment"
    echo "  $0 -e dev -a apply -s                 # Apply infrastructure changes but skip configuration"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -e|--environment)
            ENVIRONMENT="$2"
            shift
            shift
            ;;
        -a|--action)
            ACTION="$2"
            shift
            shift
            ;;
        -s|--skip-ansible)
            SKIP_ANSIBLE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "Error: Invalid environment. Must be one of: dev, staging, prod"
    exit 1
fi

# Validate action
if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
    echo "Error: Invalid action. Must be one of: plan, apply, destroy"
    exit 1
fi

echo "==================================================================="
echo "Deploying to environment: $ENVIRONMENT"
echo "Action: $ACTION"
echo "Skip Ansible: $SKIP_ANSIBLE"
echo "==================================================================="

# Change to the Terraform directory for the specified environment
cd "$(dirname "$0")/../terraform/$ENVIRONMENT"

# Execute Terraform
echo "Initializing Terraform..."
terraform init

# Execute the requested action
case $ACTION in
    plan)
        echo "Planning Terraform changes..."
        terraform plan -out=tfplan
        ;;
    apply)
        echo "Applying Terraform changes..."
        terraform apply -auto-approve
        # Export Terraform outputs for Ansible if needed
        if [ "$SKIP_ANSIBLE" = false ]; then
            echo "Exporting Terraform outputs for Ansible..."
            terraform output -json > ../../ansible/inventory/$ENVIRONMENT/terraform_outputs.json
        fi
        ;;
    destroy)
        echo "Destroying Terraform infrastructure..."
        terraform destroy -auto-approve
        ;;
esac

# Run Ansible if not skipped and not destroying
if [ "$SKIP_ANSIBLE" = false ] && [ "$ACTION" != "destroy" ]; then
    echo "Running Ansible configuration..."
    cd "$(dirname "$0")/../ansible"
    
    # Execute Ansible playbook for the specified environment
    ansible-playbook -i inventory/$ENVIRONMENT/hosts.yml playbooks/site.yml -e "environment=$ENVIRONMENT"
fi

echo "==================================================================="
echo "Deployment completed successfully!"
echo "===================================================================" 