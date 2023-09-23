output "cluster_id" {
  description = "ID of the EKS cluster. Equivalent to cluster_name for EKS."
  value       = aws_eks_cluster.this.id
}

output "cluster_name" {
  description = "Name of the EKS cluster. Pass to eks-addons.cluster_name."
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster. Use for IAM policy conditions and CloudWatch log group naming."
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "HTTPS endpoint of the EKS API server. Pass to eks-addons.cluster_endpoint and Kubernetes provider host."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority" {
  description = "Base64 encoded certificate data for the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for the cluster (alias for cluster_certificate_authority)"
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "node_group_role_arn" {
  description = "ARN of the IAM role used by node groups"
  value       = aws_iam_role.node_group.arn
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider for IRSA (without https:// prefix)"
  value       = replace(aws_iam_openid_connect_provider.eks.url, "https://", "")
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for IRSA (alias for oidc_provider_url, matches AWS provider naming)"
  value       = replace(aws_iam_openid_connect_provider.eks.url, "https://", "")
}

output "cluster_autoscaler_role_arn" {
  description = "ARN of the IRSA role for Cluster Autoscaler. Empty string when enable_cluster_autoscaler_irsa=false."
  value       = var.enable_cluster_autoscaler_irsa ? aws_iam_role.cluster_autoscaler[0].arn : ""
}

output "psa_namespace_labels" {
  description = "Map of namespace to Pod Security Admission enforce label. Apply these as Kubernetes namespace labels after cluster creation."
  value = {
    for ns, level in var.pod_security_standards :
    ns => "pod-security.kubernetes.io/enforce=${level}"
  }
}
