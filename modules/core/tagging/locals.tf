locals {
  # Default tags applied to all resources
  default_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  # Merged tags: defaults + user-provided extras
  # User-provided tags take precedence over defaults
  tags = merge(local.default_tags, var.extra_tags)
}
