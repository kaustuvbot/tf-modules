# -----------------------------------------------------------------------------
# Subnets and Network Security Groups
# -----------------------------------------------------------------------------
# Each subnet gets a dedicated NSG. Default rules allow VNet-local traffic
# and deny all inbound internet access.
# -----------------------------------------------------------------------------

variable "subnets" {
  description = "Map of subnet name to configuration"
  type = map(object({
    address_prefixes     = list(string)
    service_endpoints    = optional(list(string), [])
    deny_inbound_internet = optional(bool, true)
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

# Deny all inbound internet traffic when requested (enabled per subnet)
resource "azurerm_network_security_rule" "deny_inbound_internet" {
  for_each = { for k, v in var.subnets : k => v if v.deny_inbound_internet }

  name                        = "DenyInboundInternet"
  priority                    = 4000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this[each.key].name
}
