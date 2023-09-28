# -----------------------------------------------------------------------------
# Azure Container Registry
# -----------------------------------------------------------------------------
# Creates an ACR with admin access disabled (RBAC-only). For production,
# set public_network_access_enabled=false and configure a private endpoint
# and private DNS zone outside this module.
# -----------------------------------------------------------------------------

locals {
  # ACR names: alphanumeric only, 5-50 chars. Strip hyphens from project name.
  registry_name = substr(
    replace("${var.project}${var.environment}", "-", ""),
    0, 50
  )

  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "container-registry"
    },
    var.tags,
  )
}

resource "azurerm_container_registry" "this" {
  name                          = local.registry_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  admin_enabled                 = false
  public_network_access_enabled = var.public_network_access_enabled
  zone_redundancy_enabled       = var.zone_redundancy_enabled

  dynamic "georeplications" {
    for_each = var.georeplications

    content {
      location                = georeplications.value.location
      zone_redundancy_enabled = georeplications.value.zone_redundancy_enabled
    }
  }

  tags = local.common_tags
}
