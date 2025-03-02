# Staging Environment Terraform Configuration

terraform {
  required_version = ">= 0.14.0"

  backend "s3" {
    bucket         = "terraform-ansible-pipeline-state"
    key            = "staging/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = "staging"
      Project     = var.project_name
      ManagedBy   = "terraform"
    }
  }
}

# Include environment-specific variables
variable "region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "terraform-ansible-pipeline"
}

# Variables for VPC, subnets, etc. are defined in variables.tf

module "vpc" {
  source = "../modules/vpc"

  environment        = "staging"
  vpc_cidr           = var.vpc_cidr
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones
  region             = var.region
}

module "security_groups" {
  source = "../modules/security_groups"

  environment = "staging"
  vpc_id      = module.vpc.vpc_id
} 