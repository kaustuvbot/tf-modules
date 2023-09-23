output "profile_id" {
  description = "Resource ID of the Front Door profile"
  value       = azurerm_cdn_frontdoor_profile.this.id
}

output "endpoint_hostname" {
  description = "Default hostname of the Front Door endpoint"
  value       = azurerm_cdn_frontdoor_endpoint.this.host_name
}

output "endpoint_id" {
  description = "Resource ID of the Front Door endpoint"
  value       = azurerm_cdn_frontdoor_endpoint.this.id
}

output "origin_group_id" {
  description = "Resource ID of the Front Door origin group"
  value       = azurerm_cdn_frontdoor_origin_group.this.id
}
