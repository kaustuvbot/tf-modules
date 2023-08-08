# -----------------------------------------------------------------------------
# AKS Cluster and System Node Pool
# -----------------------------------------------------------------------------

variable "system_node_pool_vm_size" {
  description = "VM size for system node pool nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "system_node_pool_node_count" {
  description = "Initial node count for the system node pool"
  type        = number
  default     = 2
}

variable "system_node_pool_min_count" {
  description = "Minimum node count when autoscaling is enabled"
  type        = number
  default     = 1
}

variable "system_node_pool_max_count" {
  description = "Maximum node count when autoscaling is enabled"
  type        = number
  default     = 3
}

locals {
  api_server_authorized_ip_ranges = var.private_cluster_enabled ? null : (
    length(var.authorized_ip_ranges) > 0 ? var.authorized_ip_ranges : null
  )
}

resource "azurerm_kubernetes_cluster" "this" {
  name                    = local.cluster_name
  location                = var.location
  resource_group_name     = var.resource_group_name
  dns_prefix              = "${var.project}-${var.environment}"
  kubernetes_version      = var.kubernetes_version
  private_cluster_enabled = var.private_cluster_enabled

  api_server_access_profile {
    authorized_ip_ranges = local.api_server_authorized_ip_ranges
  }

  default_node_pool {
    name                = "system"
    vm_size             = var.system_node_pool_vm_size
    vnet_subnet_id      = var.system_node_pool_subnet_id
    enable_auto_scaling = true
    node_count          = var.system_node_pool_node_count
    min_count           = var.system_node_pool_min_count
    max_count           = var.system_node_pool_max_count

    upgrade_settings {
      max_surge = "33%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  oidc_issuer_enabled       = var.workload_identity_enabled
  workload_identity_enabled = var.workload_identity_enabled
  azure_policy_enabled      = var.azure_policy_enabled

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  tags = local.tags
}
