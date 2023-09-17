# Platform Blueprint — Multi-Cloud Orchestration Module
#
# This module provides a unified entry point for deploying a standard
# platform stack (networking + compute + observability) on a target cloud.
#
# Design principle: cloud-specific config is isolated in typed objects
# (aws_config, azure_config). The blueprint module itself has no
# direct resource dependencies on cloud-specific providers — all cloud
# resources are created inside the aws-stack and azure-stack child modules.
# This keeps the blueprint free of implicit provider coupling.
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

  # Validate that the required cloud config is provided
  validate_aws_config   = local.is_aws && var.aws_config == null ? tobool("aws_config must be set when cloud=aws") : true
  validate_azure_config = local.is_azure && var.azure_config == null ? tobool("azure_config must be set when cloud=azure") : true

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
