# -----------------------------------------------------------------------------
# AKS Diagnostic Settings
# -----------------------------------------------------------------------------
# Streams control-plane logs and metrics to a Log Analytics Workspace.
# Requires the caller to provision a workspace and pass its ID.
# -----------------------------------------------------------------------------

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace for diagnostic logs. Set to null to disable diagnostics."
  type        = string
  default     = null
}

resource "azurerm_monitor_diagnostic_setting" "aks" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "diag-${local.cluster_name}"
  target_resource_id         = azurerm_kubernetes_cluster.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "kube-scheduler"
  }

  enabled_log {
    category = "kube-audit-admin"
  }

  enabled_log {
    category = "guard"
  }

}
