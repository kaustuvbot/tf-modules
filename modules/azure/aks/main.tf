# -----------------------------------------------------------------------------
# Azure Kubernetes Service (AKS)
# -----------------------------------------------------------------------------
# Provisions an AKS cluster with a system node pool.
# User node pools are managed separately (node-pools.tf).
# Naming convention: aks-{project}-{environment}
# -----------------------------------------------------------------------------

locals {
  cluster_name = "aks-${var.project}-${var.environment}"

  default_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  tags = merge(local.default_tags, var.tags)
}

# Placeholder: cluster resource defined in cluster.tf
