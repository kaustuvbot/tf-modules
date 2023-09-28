locals {
  name_prefix = "${var.project}-${var.environment}"

  default_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  tags = merge(local.default_tags, var.tags)

  origins           = var.origins != null ? var.origins : {}
  routes            = var.routes != null ? var.routes : {}
  security_policies = var.security_policies != null ? var.security_policies : {}
  health_probe = var.health_probe != null ? var.health_probe : {
    interval_in_seconds                = 30
    path                               = "/"
    protocol                           = "Https"
    request_type                       = "HEAD"
    sample_size                        = 4
    successful_samples_required        = 3
    additional_latency_in_milliseconds = 50
  }
}

resource "azurerm_cdn_frontdoor_profile" "this" {
  name                = "afd-${local.name_prefix}"
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name
  tags                = local.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "this" {
  name                     = "ep-${local.name_prefix}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  tags                     = local.tags
}

resource "azurerm_cdn_frontdoor_origin_group" "this" {
  name                     = "og-${local.name_prefix}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  load_balancing {
    sample_size                        = local.health_probe.sample_size
    successful_samples_required        = local.health_probe.successful_samples_required
    additional_latency_in_milliseconds = local.health_probe.additional_latency_in_milliseconds
  }

  health_probe {
    interval_in_seconds = local.health_probe.interval_in_seconds
    path                = local.health_probe.path
    protocol            = local.health_probe.protocol
    request_type        = local.health_probe.request_type
  }
}

resource "azurerm_cdn_frontdoor_origin" "this" {
  for_each = local.origins

  name                           = each.key
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.this.id
  host_name                      = each.value.host_name
  http_port                      = each.value.http_port
  https_port                     = each.value.https_port
  origin_host_header             = each.value.origin_host_header != null ? each.value.origin_host_header : each.value.host_name
  priority                       = each.value.priority
  weight                         = each.value.weight
  enabled                        = each.value.enabled
  certificate_name_check_enabled = true
}
