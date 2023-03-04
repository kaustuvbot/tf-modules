# Core tagging module
# Provides a consistent tagging/labels interface for all cloud resources.
# AWS uses "tags", Azure uses "tags" (but historically "labels" in some contexts).
# This module normalizes the interface.

locals {
  default_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  tags = merge(local.default_tags, var.extra_tags)
}
