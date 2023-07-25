output "cluster_id" {
  description = "Resource ID of the AKS cluster"
  value       = ""
}

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = ""
}

output "kube_config" {
  description = "Kubernetes configuration for the cluster"
  value       = ""
  sensitive   = true
}
