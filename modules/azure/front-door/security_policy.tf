resource "azurerm_cdn_frontdoor_security_policy" "this" {
  for_each = local.security_policies

  name                     = "sec-${local.name_prefix}-${each.key}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  dynamic "waf_policy" {
    for_each = each.value.waf_policy_id != null ? [1] : []
    content {
      cdn_frontdoor_waf_policy_id = each.value.waf_policy_id
    }
  }
}
