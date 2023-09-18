output "action_group_id" {
  description = "Resource ID of the action group (null if no email configured)"
  value       = length(azurerm_monitor_action_group.this) > 0 ? azurerm_monitor_action_group.this[0].id : null
}

output "cpu_alert_id" {
  description = "Resource ID of the CPU metric alert"
  value       = azurerm_monitor_metric_alert.cpu.id
}

output "memory_alert_id" {
  description = "Resource ID of the memory metric alert"
  value       = azurerm_monitor_metric_alert.memory.id
}

output "defender_containers_enabled" {
  description = "Whether Defender for Containers is enabled"
  value       = var.enable_defender_for_containers
}

output "defender_keyvault_enabled" {
  description = "Whether Defender for Key Vault is enabled"
  value       = var.enable_defender_for_keyvault
}
