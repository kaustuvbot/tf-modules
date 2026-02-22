output "vpc_network_id" {
  description = "VPC network ID"
  value       = module.vpc.network_id
}

output "kms_key_id" {
  description = "KMS crypto key ID"
  value       = module.kms.crypto_key_id
}

output "storage_bucket_name" {
  description = "Storage bucket name"
  value       = module.storage.bucket_name
}

output "gke_cluster_name" {
  description = "GKE cluster name"
  value       = module.gke.cluster_name
}

output "gke_cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = module.gke.cluster_endpoint
}

output "workload_pool" {
  description = "Workload Identity pool"
  value       = module.gke.workload_pool
}
