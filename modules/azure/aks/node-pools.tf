# -----------------------------------------------------------------------------
# AKS User Node Pools
# -----------------------------------------------------------------------------
# Additional node pools beyond the system pool. User pools run workload pods;
# the system pool is reserved for cluster-critical add-ons.
# -----------------------------------------------------------------------------

variable "user_node_pools" {
  description = "Map of user node pool name to configuration"
  type = map(object({
    vm_size         = string
    subnet_id       = string
    node_count      = optional(number, 2)
    min_count       = optional(number, 1)
    max_count       = optional(number, 5)
    os_disk_type    = optional(string, "Managed")
    os_disk_size_gb = optional(number, 128)
    node_labels     = optional(map(string), {})
    node_taints     = optional(list(string), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.user_node_pools :
      contains(["Managed", "Ephemeral"], v.os_disk_type)
    ])
    error_message = "os_disk_type must be Managed or Ephemeral for all user node pools."
  }

  validation {
    condition = alltrue([
      for k, v in var.user_node_pools :
      v.os_disk_type != "Ephemeral" || v.os_disk_size_gb <= 128
    ])
    error_message = "Ephemeral OS disks must be <= 128 GB to fit within the VM cache disk of common AKS-certified SKUs. Use a larger SKU or switch to os_disk_type=Managed if you need a larger OS disk."
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  for_each = var.user_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = each.value.vm_size
  vnet_subnet_id        = each.value.subnet_id
  mode                  = "User"
  enable_auto_scaling   = true
  node_count            = each.value.node_count
  min_count             = each.value.min_count
  max_count             = each.value.max_count
  os_disk_type          = each.value.os_disk_type
  os_disk_size_gb       = each.value.os_disk_size_gb
  node_labels           = each.value.node_labels
  node_taints           = each.value.node_taints

  upgrade_settings {
    max_surge = "33%"
  }

  tags = local.tags
}
