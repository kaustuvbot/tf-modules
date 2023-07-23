output "vnet_id" {
  description = "Resource ID of the VNet"
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Name of the VNet"
  value       = azurerm_virtual_network.this.name
}

output "address_space" {
  description = "Address space of the VNet"
  value       = azurerm_virtual_network.this.address_space
}
