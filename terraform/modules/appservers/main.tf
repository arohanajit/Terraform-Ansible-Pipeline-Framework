variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the application servers"
  type        = list(string)
}

variable "security_group" {
  description = "Security group ID for application servers"
  type        = string
}

resource "aws_instance" "appserver" {
  count = 2

  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI
  instance_type = "t2.small"

  subnet_id                   = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids     = [var.security_group]
  associate_public_ip_address = true

  tags = {
    Name        = "${var.environment}-appserver-${count.index + 1}"
    Environment = var.environment
    Role        = "appserver"
  }
}

output "instance_ids" {
  description = "IDs of created instances"
  value       = aws_instance.appserver[*].id
}

output "instance_public_ips" {
  description = "Public IP addresses of instances"
  value       = aws_instance.appserver[*].public_ip
}

output "instance_private_ips" {
  description = "Private IP addresses of instances"
  value       = aws_instance.appserver[*].private_ip
} 