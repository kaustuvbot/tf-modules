output "cluster_id" {
  description = "ID of the GKE cluster"
  value       = google_container_cluster.this.id
}

output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.this.name
}

output "cluster_endpoint" {
  description = "HTTPS endpoint of the GKE API server"
  value       = google_container_cluster.this.endpoint
}

output "cluster_master_version" {
  description = "Master version of the cluster"
  value       = google_container_cluster.this.master_version
}

output "cluster_arn" {
  description = "ARN of the GKE cluster"
  value       = google_container_cluster.this.id
}

output "node_pool_names" {
  description = "List of node pool names"
  value       = [for k, v in google_container_node_pool.this : k]
}

output "node_pool_ids" {
  description = "Map of node pool name to ID"
  value       = { for k, v in google_container_node_pool.this : k => v.id }
}

output "workload_pool" {
  description = "Workload Identity pool"
  value       = "${var.project}.svc.id.goog"
}
