resource "azurerm_cdn_frontdoor_route" "this" {
  for_each = local.routes

  name                      = each.key
  cdn_frontdoor_endpoint_id = azurerm_cdn_frontdoor_endpoint.this.id

  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id
  cdn_frontdoor_origin_ids      = [for o in azurerm_cdn_frontdoor_origin.this : o.id]

  patterns_to_match      = each.value.patterns_to_match
  supported_protocols    = each.value.supported_protocols
  forwarding_protocol    = each.value.forwarding_protocol
  https_redirect_enabled = each.value.https_redirect_enabled
  link_to_default_domain = each.value.link_to_default_domain
  enabled                = each.value.enabled

  dynamic "cache" {
    for_each = each.value.cache_enabled ? [1] : []
    content {
      query_string_caching_behavior = each.value.cache_query_string_behavior
      compression_enabled           = each.value.cache_compression_enabled
    }
  }
}
