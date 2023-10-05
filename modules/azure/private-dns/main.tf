# -----------------------------------------------------------------------------
# Azure Private DNS Zone and VNet Links
# -----------------------------------------------------------------------------
# Required for AKS private clusters: the API server endpoint resolves via a
# private DNS zone rather than public DNS. Link every VNet that needs to
# resolve the AKS API server hostname to this zone.
# -----------------------------------------------------------------------------

locals {
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "private-dns"
    },
    var.tags,
  )
}

resource "azurerm_private_dns_zone" "this" {
  name                = var.zone_name
  resource_group_name = var.resource_group_name

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = var.vnet_links

  name                  = each.key
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = each.value
  registration_enabled  = var.registration_enabled

  tags = local.common_tags
}
