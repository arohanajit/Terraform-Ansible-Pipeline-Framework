variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the database instance"
  type        = string
}

variable "security_group" {
  description = "Security group ID for database instance"
  type        = string
}

variable "is_primary" {
  description = "Whether this is a primary database instance"
  type        = bool
  default     = false
}

resource "aws_instance" "database" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI
  instance_type = "t2.large"

  subnet_id                   = var.subnet_id
  vpc_security_group_ids     = [var.security_group]
  associate_public_ip_address = false

  root_block_device {
    volume_size = 100
    volume_type = "gp2"
  }

  tags = {
    Name        = "${var.environment}-database-${var.is_primary ? "primary" : "replica"}"
    Environment = var.environment
    Role        = "database"
    Type        = var.is_primary ? "primary" : "replica"
  }
}

output "instance_id" {
  description = "ID of created instance"
  value       = aws_instance.database.id
}

output "instance_public_ip" {
  description = "Public IP address of instance"
  value       = aws_instance.database.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of instance"
  value       = aws_instance.database.private_ip
} 