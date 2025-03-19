# Production Environment Terraform Configuration

terraform {
  required_version = ">= 0.14.0"

  # Comment out the S3 backend for local validation
  /*
  backend "s3" {
    bucket         = "terraform-ansible-pipeline-state"
    key            = "prod/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
  */

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
      Environment = "prod"
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

  environment        = "prod"
  vpc_cidr           = var.vpc_cidr
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones
  region             = var.region
}

module "security_groups" {
  source = "../modules/security_groups"

  environment = "prod"
  vpc_id      = module.vpc.vpc_id
}

module "webservers" {
  source = "../modules/webservers"

  environment    = "prod"
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnet_ids
  security_group = module.security_groups.web_security_group_id
}

module "appservers" {
  source = "../modules/appservers"

  environment    = "prod"
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnet_ids
  security_group = module.security_groups.app_security_group_id
}

module "dbservers" {
  source = "../modules/dbservers"

  environment    = "prod"
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnet_ids
  security_group = module.security_groups.db_security_group_id
}

module "database_primary" {
  source = "../modules/database"

  environment    = "prod"
  vpc_id         = module.vpc.vpc_id
  subnet_id      = module.vpc.private_subnet_ids[0]
  security_group = module.security_groups.db_security_group_id
  is_primary     = true
}

module "database_replicas" {
  source = "../modules/database"

  environment    = "prod"
  vpc_id         = module.vpc.vpc_id
  subnet_id      = module.vpc.private_subnet_ids[1]
  security_group = module.security_groups.db_security_group_id
  is_primary     = false
}

module "monitoring" {
  source = "../modules/monitoring"

  environment    = "prod"
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnet_ids
  security_group = module.security_groups.web_security_group_id
}

module "load_balancer" {
  source = "../modules/load_balancer"

  environment    = "prod"
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.public_subnet_ids
  security_group = module.security_groups.web_security_group_id
  target_groups = {
    web = {
      port     = 80
      protocol = "HTTP"
      targets  = module.webservers.instance_ids
    }
    app = {
      port     = 8080
      protocol = "HTTP"
      targets  = module.appservers.instance_ids
    }
  }
} 