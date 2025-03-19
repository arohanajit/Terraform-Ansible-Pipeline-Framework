variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the monitoring servers"
  type        = list(string)
}

variable "security_group" {
  description = "Security group ID for monitoring servers"
  type        = string
}

resource "aws_instance" "monitoring" {
  count = 1

  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI
  instance_type = "t2.medium"

  subnet_id                   = var.subnet_ids[0]
  vpc_security_group_ids     = [var.security_group]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 50
    volume_type = "gp2"
  }

  tags = {
    Name        = "${var.environment}-monitoring"
    Environment = var.environment
    Role        = "monitoring"
  }
}

output "instance_ids" {
  description = "IDs of created instances"
  value       = aws_instance.monitoring[*].id
}

output "instance_public_ips" {
  description = "Public IP addresses of instances"
  value       = aws_instance.monitoring[*].public_ip
}

output "instance_private_ips" {
  description = "Private IP addresses of instances"
  value       = aws_instance.monitoring[*].private_ip
} 