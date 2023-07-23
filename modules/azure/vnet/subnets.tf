# -----------------------------------------------------------------------------
# Subnets and Network Security Groups
# -----------------------------------------------------------------------------
# Each subnet gets a dedicated NSG. Default rules allow VNet-local traffic
# and deny all inbound internet access.
# -----------------------------------------------------------------------------

variable "subnets" {
  description = "Map of subnet name to configuration"
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
  }))
  default = {}
}

locals {
  subnet_nsg_pairs = {
    for name, cfg in var.subnets : name => cfg
  }
}

resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = "snet-${each.key}-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints
}

resource "azurerm_network_security_group" "this" {
  for_each = var.subnets

  name                = "nsg-${each.key}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.tags
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = var.subnets

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}
