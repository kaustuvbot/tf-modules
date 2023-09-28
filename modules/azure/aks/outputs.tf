output "cluster_id" {
  description = "Resource ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.id
}

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.name
}

output "kube_config" {
  description = "Raw kubeconfig for the cluster"
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "host" {
  description = "Kubernetes API server hostname"
  value       = azurerm_kubernetes_cluster.this.kube_config[0].host
  sensitive   = true
}

output "kubelet_identity_object_id" {
  description = "Object ID of the kubelet managed identity (used for ACR pull assignments)"
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for Workload Identity federation (null when workload_identity_enabled=false)"
  value       = var.workload_identity_enabled ? azurerm_kubernetes_cluster.this.oidc_issuer_url : null
}

output "user_node_pool_ids" {
  description = "Map of user node pool name to resource ID"
  value       = { for k, v in azurerm_kubernetes_cluster_node_pool.user : k => v.id }
}

output "node_resource_group" {
  description = "Name of the auto-generated resource group containing AKS node VMs, disks, and NICs. Required when assigning RBAC roles to node infrastructure."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "fqdn" {
  description = "FQDN of the AKS cluster API server. Populated only when private_cluster_enabled=false; null for private clusters (use private_fqdn instead)."
  value       = var.private_cluster_enabled ? null : azurerm_kubernetes_cluster.this.fqdn
}

output "private_fqdn" {
  description = "Private FQDN of the AKS cluster API server. Populated only when private_cluster_enabled=true."
  value       = var.private_cluster_enabled ? azurerm_kubernetes_cluster.this.private_fqdn : null
}
