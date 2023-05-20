output "vpc_id" {
  description = "The ID of the VPC"
  value       = "" # Will be wired up when resources are added
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = var.vpc_cidr
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [] # Will be populated when subnets are created
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [] # Will be populated when subnets are created
}

output "nat_gateway_ids" {
  description = "List of NAT gateway IDs"
  value       = [] # Will be populated when NAT gateways are created
}
