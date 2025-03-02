#!/usr/bin/env python3
"""
Convert Terraform outputs to Ansible inventory.

This script reads Terraform output JSON and converts it to an Ansible inventory YAML file.
It supports dynamic inventory generation for different environments.

Usage:
    python terraform_to_ansible_inventory.py --env prod --tf-output /path/to/terraform.output.json --output /path/to/ansible/inventory/hosts.yml
"""

import argparse
import json
import os
import sys
import yaml


def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description='Convert Terraform outputs to Ansible inventory')
    parser.add_argument('--env', required=True, choices=['dev', 'staging', 'prod'],
                        help='Environment (dev, staging, prod)')
    parser.add_argument('--tf-output', required=True,
                        help='Path to Terraform output JSON file')
    parser.add_argument('--output', required=True,
                        help='Path to output Ansible inventory YAML file')
    return parser.parse_args()


def load_terraform_output(tf_output_path):
    """Load Terraform output JSON file."""
    try:
        with open(tf_output_path, 'r') as f:
            return json.load(f)
    except (IOError, json.JSONDecodeError) as e:
        print(f"Error loading Terraform output: {e}", file=sys.stderr)
        sys.exit(1)


def create_ansible_inventory(tf_output, environment):
    """Create Ansible inventory from Terraform output."""
    inventory = {
        'all': {
            'children': {},
            'vars': {
                'ansible_user': 'ubuntu',
                'ansible_ssh_private_key_file': f'~/.ssh/{environment}_key.pem',
                'environment': environment
            }
        }
    }

    # Process webservers
    if 'webserver_ips' in tf_output:
        webservers = {}
        for i, ip in enumerate(tf_output['webserver_ips']['value']):
            webservers[f'web{i+1:02d}'] = {'ansible_host': ip}
        inventory['all']['children']['webservers'] = {'hosts': webservers}

    # Process appservers
    if 'appserver_ips' in tf_output:
        appservers = {}
        for i, ip in enumerate(tf_output['appserver_ips']['value']):
            appservers[f'app{i+1:02d}'] = {'ansible_host': ip}
        inventory['all']['children']['appservers'] = {'hosts': appservers}

    # Process dbservers
    if 'dbserver_ips' in tf_output:
        dbservers = {}
        for i, ip in enumerate(tf_output['dbserver_ips']['value']):
            dbservers[f'db{i+1:02d}'] = {'ansible_host': ip}
        inventory['all']['children']['dbservers'] = {'hosts': dbservers}

    # Process database servers (primary/replica)
    if 'database_primary_ip' in tf_output or 'database_replica_ips' in tf_output:
        databases = {'children': {}}
        
        if 'database_primary_ip' in tf_output:
            primary = {
                'hosts': {
                    f'db-{environment}-primary': {
                        'ansible_host': tf_output['database_primary_ip']['value']
                    }
                }
            }
            databases['children']['primary'] = primary
            
        if 'database_replica_ips' in tf_output:
            replicas = {'hosts': {}}
            for i, ip in enumerate(tf_output['database_replica_ips']['value']):
                replicas['hosts'][f'db-{environment}-replica-{i+1:02d}'] = {'ansible_host': ip}
            databases['children']['replicas'] = replicas
            
        inventory['all']['children']['databases'] = databases

    # Process monitoring servers
    if 'monitoring_ips' in tf_output:
        monitoring = {'hosts': {}}
        for i, ip in enumerate(tf_output['monitoring_ips']['value']):
            monitoring['hosts'][f'monitor-{environment}-{i+1:02d}'] = {'ansible_host': ip}
        inventory['all']['children']['monitoring'] = monitoring

    return inventory


def write_ansible_inventory(inventory, output_path):
    """Write Ansible inventory to YAML file."""
    try:
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        with open(output_path, 'w') as f:
            f.write("---\n# Generated from Terraform output\n\n")
            yaml.dump(inventory, f, default_flow_style=False)
        print(f"Inventory written to {output_path}")
    except IOError as e:
        print(f"Error writing inventory: {e}", file=sys.stderr)
        sys.exit(1)


def main():
    """Main function."""
    args = parse_args()
    tf_output = load_terraform_output(args.tf_output)
    inventory = create_ansible_inventory(tf_output, args.env)
    write_ansible_inventory(inventory, args.output)


if __name__ == '__main__':
    main() 