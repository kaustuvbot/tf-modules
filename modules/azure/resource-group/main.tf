# -----------------------------------------------------------------------------
# Azure Resource Group
# -----------------------------------------------------------------------------
# Creates a resource group with standardised naming and tagging.
# Naming convention: rg-{project}-{environment}
# -----------------------------------------------------------------------------

locals {
  name = "rg-${var.project}-${var.environment}"

  default_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_resource_group" "this" {
  name     = local.name
  location = var.location
  tags     = local.tags
}
