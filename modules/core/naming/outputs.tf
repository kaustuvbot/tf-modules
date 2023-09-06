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

output "tags" {
  description = "Standard tag map derived from naming inputs, merged with extra_tags"
  value = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.extra_tags,
  )
}
