# -----------------------------------------------------------------------------
# AKS User Node Pools
# -----------------------------------------------------------------------------
# Additional node pools beyond the system pool. User pools run workload pods;
# the system pool is reserved for cluster-critical add-ons.
# -----------------------------------------------------------------------------

variable "user_node_pools" {
  description = "Map of user node pool name to configuration"
  type = map(object({
    vm_size        = string
    subnet_id      = string
    node_count     = optional(number, 2)
    min_count      = optional(number, 1)
    max_count      = optional(number, 5)
    node_labels    = optional(map(string), {})
    node_taints    = optional(list(string), [])
  }))
  default = {}
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
  node_labels           = each.value.node_labels
  node_taints           = each.value.node_taints

  upgrade_settings {
    max_surge = "33%"
  }

  tags = local.tags
}
