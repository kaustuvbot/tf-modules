locals {
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "vpc"
    },
    var.tags,
  )

  az_count = length(var.availability_zones)
}
