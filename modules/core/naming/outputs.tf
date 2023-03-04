output "resource_name" {
  description = "Generated resource name"
  value       = local.resource_name
}

output "project" {
  description = "Project name"
  value       = var.project
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}
