# AWS provider configuration baseline
#
# This module establishes the standard AWS provider configuration
# pattern used across all AWS modules in this project.
#
# Usage:
#   provider "aws" {
#     region  = var.aws_region
#     profile = var.aws_profile
#
#     default_tags {
#       tags = module.tagging.tags
#     }
#   }
#
# Note: Provider configuration should be done at the root module level.
# Child modules inherit the provider from their caller.
