locals {
  name_prefix = "${var.project}-${var.environment}"

  default_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  tags = merge(local.default_tags, var.tags)
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
    sample_size                        = var.health_probe.sample_size
    successful_samples_required        = var.health_probe.successful_samples_required
    additional_latency_in_milliseconds = var.health_probe.additional_latency_in_milliseconds
  }

  health_probe {
    interval_in_seconds = var.health_probe.interval_in_seconds
    path                = var.health_probe.path
    protocol            = var.health_probe.protocol
    request_type        = var.health_probe.request_type
  }
}

resource "azurerm_cdn_frontdoor_origin" "this" {
  for_each = var.origins

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
