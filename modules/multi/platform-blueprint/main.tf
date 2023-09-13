# Platform Blueprint — Multi-Cloud Orchestration Module
#
# This module provides a unified entry point for deploying a standard
# platform stack (networking + compute + observability) on a target cloud.
#
# Usage:
#   module "platform" {
#     source      = "../../modules/multi/platform-blueprint"
#     cloud       = "aws"
#     project     = "myapp"
#     environment = "prod"
#     aws_config  = { ... }
#   }

locals {
  is_aws   = var.cloud == "aws"
  is_azure = var.cloud == "azure"

  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Blueprint   = "platform-v1"
    },
    var.tags
  )
}
