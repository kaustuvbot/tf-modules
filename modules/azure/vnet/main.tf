# -----------------------------------------------------------------------------
# Azure Virtual Network
# -----------------------------------------------------------------------------
# Provisions a VNet with standardised naming.
# Subnets and NSGs are managed separately in the same module (subnets.tf).
# Naming convention: vnet-{project}-{environment}
# -----------------------------------------------------------------------------

locals {
  name = "vnet-${var.project}-${var.environment}"

  default_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_virtual_network" "this" {
  name                = local.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = local.tags

  dynamic "ddos_protection_plan" {
    for_each = var.ddos_protection_plan_id != null ? [1] : []
    content {
      id     = var.ddos_protection_plan_id
      enable = true
    }
  }
}
