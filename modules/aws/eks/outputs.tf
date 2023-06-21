output "cluster_id" {
  description = "The EKS cluster ID"
  value       = ""
}

output "cluster_name" {
  description = "The EKS cluster name"
  value       = ""
}

output "cluster_endpoint" {
  description = "The EKS cluster API endpoint"
  value       = ""
}

output "cluster_certificate_authority" {
  description = "Base64 encoded certificate data for the cluster"
  value       = ""
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = ""
}

output "node_group_role_arn" {
  description = "ARN of the IAM role used by node groups"
  value       = ""
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = ""
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider for IRSA"
  value       = ""
}
