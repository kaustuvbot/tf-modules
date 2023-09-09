# -----------------------------------------------------------------------------
# Shared Helm release defaults
# -----------------------------------------------------------------------------
# Centralise common settings so all Helm releases stay in sync.
# Individual releases may override timeout or add wait_for_jobs as needed.
# -----------------------------------------------------------------------------

locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "eks-addons"
  }

  helm_release_defaults = {
    atomic          = true
    cleanup_on_fail = true
    wait            = true
    timeout         = 300
  }
}
