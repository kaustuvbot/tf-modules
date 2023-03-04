output "resource_name" {
  description = "Full generated resource name (project-environment-component-suffix)"
  value       = local.resource_name
}

output "short_name" {
  description = "Short resource name (project-environment) for constrained contexts"
  value       = local.short_name
}

output "project" {
  description = "Project name passed through for convenience"
  value       = var.project
}

output "environment" {
  description = "Environment name passed through for convenience"
  value       = var.environment
}
