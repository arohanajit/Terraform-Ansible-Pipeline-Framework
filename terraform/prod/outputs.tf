# Production Environment Outputs

# Web Server Outputs
output "webserver_ips" {
  description = "Public IP addresses of web servers"
  value       = module.webservers.instance_public_ips
}

output "webserver_private_ips" {
  description = "Private IP addresses of web servers"
  value       = module.webservers.instance_private_ips
}

# App Server Outputs
output "appserver_ips" {
  description = "Public IP addresses of application servers"
  value       = module.appservers.instance_public_ips
}

output "appserver_private_ips" {
  description = "Private IP addresses of application servers"
  value       = module.appservers.instance_private_ips
}

# Database Server Outputs
output "dbserver_ips" {
  description = "Public IP addresses of database servers"
  value       = module.dbservers.instance_public_ips
}

output "dbserver_private_ips" {
  description = "Private IP addresses of database servers"
  value       = module.dbservers.instance_private_ips
}

# Database Primary/Replica Outputs
output "database_primary_ip" {
  description = "Public IP address of the primary database"
  value       = module.database_primary.instance_public_ip
}

output "database_replica_ips" {
  description = "Public IP addresses of database replicas"
  value       = module.database_replicas.instance_public_ip
}

# Monitoring Server Outputs
output "monitoring_ips" {
  description = "Public IP addresses of monitoring servers"
  value       = module.monitoring.instance_public_ips
}

# Load Balancer Outputs
output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = module.load_balancer.dns_name
}

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnet_ids
} 