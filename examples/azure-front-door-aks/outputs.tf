output "front_door_endpoint" {
  description = "Front Door endpoint hostname"
  value       = module.front_door.endpoint_hostname
}

output "aks_cluster_name" {
  description = "AKS cluster name"
  value       = module.aks.cluster_name
}
