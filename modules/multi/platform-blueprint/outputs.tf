output "cloud" {
  description = "Target cloud for this blueprint deployment"
  value       = var.cloud
}

output "project" {
  description = "Project name"
  value       = var.project
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

# Populated by aws.tf or azure.tf sub-compositions
output "cluster_endpoint" {
  description = "Kubernetes API server endpoint"
  value       = local.is_aws ? (length(module.aws_stack) > 0 ? module.aws_stack[0].cluster_endpoint : null) : (length(module.azure_stack) > 0 ? module.azure_stack[0].cluster_endpoint : null)
}

output "network_id" {
  description = "VPC ID (AWS) or VNet ID (Azure)"
  value       = local.is_aws ? (length(module.aws_stack) > 0 ? module.aws_stack[0].network_id : null) : (length(module.azure_stack) > 0 ? module.azure_stack[0].network_id : null)
}
