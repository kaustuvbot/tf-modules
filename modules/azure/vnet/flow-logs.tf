# -----------------------------------------------------------------------------
# NSG Flow Logs
# -----------------------------------------------------------------------------
# Creates one flow log resource per NSG when enable_flow_logs=true.
# Requires an existing Network Watcher and storage account in the same region.
# -----------------------------------------------------------------------------

resource "azurerm_network_watcher_flow_log" "this" {
  for_each = var.enable_flow_logs ? var.subnets : {}

  name                 = "flowlog-${each.key}-${var.environment}"
  network_watcher_name = var.flow_log_network_watcher_name
  resource_group_name  = var.flow_log_network_watcher_resource_group
  target_resource_id   = azurerm_network_security_group.this[each.key].id
  storage_account_id   = var.flow_log_storage_account_id
  enabled              = true

  retention_policy {
    enabled = true
    days    = 30
  }

  tags = local.tags
}
