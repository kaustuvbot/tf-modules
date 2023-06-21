locals {
  cluster_name = "${var.project}-${var.environment}-eks"

  common_tags = merge(
    {
      Module      = "eks"
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}
