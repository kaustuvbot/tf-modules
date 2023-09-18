# -----------------------------------------------------------------------------
# Azure Monitor Metric Alerts for AKS
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project}-${var.environment}"

  default_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_monitor_action_group" "this" {
  count = var.action_group_email != null ? 1 : 0

  name                = "ag-${local.name_prefix}"
  resource_group_name = var.resource_group_name
  short_name          = substr("ag-${var.environment}", 0, 12)
  tags                = local.tags

  email_receiver {
    name          = "ops-email"
    email_address = var.action_group_email
  }
}

locals {
  action_group_ids = var.action_group_email != null ? [azurerm_monitor_action_group.this[0].id] : []
}

resource "azurerm_monitor_metric_alert" "cpu" {
  name                = "alert-aks-cpu-${local.name_prefix}"
  resource_group_name = var.resource_group_name
  scopes              = [var.aks_cluster_id]
  description         = "AKS node CPU usage exceeds ${var.cpu_threshold_percent}%"
  severity            = 2
  tags                = local.tags

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.cpu_threshold_percent
  }

  dynamic "action" {
    for_each = local.action_group_ids
    content {
      action_group_id = action.value
    }
  }
}

resource "azurerm_monitor_metric_alert" "memory" {
  name                = "alert-aks-memory-${local.name_prefix}"
  resource_group_name = var.resource_group_name
  scopes              = [var.aks_cluster_id]
  description         = "AKS node memory working set exceeds ${var.memory_threshold_percent}%"
  severity            = 2
  tags                = local.tags

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_memory_working_set_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.memory_threshold_percent
  }

  dynamic "action" {
    for_each = local.action_group_ids
    content {
      action_group_id = action.value
    }
  }
}

# -----------------------------------------------------------------------------
# Microsoft Defender for Cloud — optional baseline
# -----------------------------------------------------------------------------

resource "azurerm_security_center_subscription_pricing" "containers" {
  count         = var.enable_defender_for_containers ? 1 : 0
  tier          = "Standard"
  resource_type = "ContainerRegistry"
}

resource "azurerm_security_center_subscription_pricing" "keyvault" {
  count         = var.enable_defender_for_keyvault ? 1 : 0
  tier          = "Standard"
  resource_type = "KeyVaults"
}
