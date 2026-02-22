locals {
  # AWS-style tags (Title_Case)
  aws_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  # Azure-style tags (Title_Case)
  azure_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  # GCP-style labels (lowercase with hyphens)
  gcp_labels = {
    project     = lower(var.project)
    environment = lower(var.environment)
    managed_by  = "terraform"
  }

  # Default tags based on cloud provider
  default_tags = var.cloud_provider == "gcp" ? local.gcp_labels : (
    var.cloud_provider == "azure" ? local.azure_tags : local.aws_tags
  )

  # Merged tags: defaults + user-provided extras
  # User-provided tags take precedence over defaults
  tags = merge(local.default_tags, var.extra_tags)
}
