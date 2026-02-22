# Platform Blueprint — Outputs
#
# All outputs use cloud-agnostic keys so application teams can consume
# blueprint outputs without knowing the underlying cloud.

output "cloud" {
  description = "Target cloud for this blueprint deployment"
  value       = var.cloud
}

output "project" {
  description = "Project name"
  value       = var.project
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint. Use to configure kubectl or helm providers in child modules."
  value       = local.is_aws ? try(module.aws_stack[0].cluster_endpoint, null) : (var.cloud == "gcp" ? try(module.gcp_gke[0].cluster_endpoint, null) : try(module.azure_stack[0].cluster_endpoint, null))
}

output "network_id" {
  description = "Primary network ID — VPC ID on AWS, VNet resource ID on Azure, Network ID on GCP."
  value       = local.is_aws ? try(module.aws_stack[0].network_id, null) : (var.cloud == "gcp" ? try(module.gcp_vpc[0].network_id, null) : try(module.azure_stack[0].network_id, null))
}

output "common_tags" {
  description = "Merged tag map applied to all resources in this blueprint deployment."
  value       = local.common_tags
}
