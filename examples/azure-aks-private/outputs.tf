output "resource_group_name" {
  value = module.resource_group.name
}

output "aks_cluster_name" {
  value = module.aks.cluster_name
}

output "vnet_id" {
  value = module.vnet.vnet_id
}
