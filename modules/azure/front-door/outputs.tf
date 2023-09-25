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

output "origin_ids" {
  description = "Map of origin IDs by origin name"
  value       = { for o in azurerm_cdn_frontdoor_origin.this : o.name => o.id }
}

output "route_ids" {
  description = "Map of route IDs by route name"
  value       = { for r in azurerm_cdn_frontdoor_route.this : r.name => r.id }
}

output "security_policy_ids" {
  description = "Map of security policy IDs by policy name"
  value       = { for p in azurerm_cdn_frontdoor_security_policy.this : p.name => p.id }
}

output "profile_name" {
  description = "Name of the Front Door profile"
  value       = azurerm_cdn_frontdoor_profile.this.name
}
