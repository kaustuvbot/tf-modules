output "alb_controller_role_arn" {
  description = "ARN of the ALB controller IRSA role"
  value       = var.enable_alb_controller ? aws_iam_role.alb_controller[0].arn : null
}

output "external_dns_role_arn" {
  description = "ARN of the ExternalDNS IRSA role"
  value       = var.enable_external_dns ? aws_iam_role.external_dns[0].arn : null
}

output "cert_manager_role_arn" {
  description = "ARN of the cert-manager IRSA role"
  value       = var.enable_cert_manager ? aws_iam_role.cert_manager[0].arn : null
}

output "prometheus_namespace" {
  description = "Namespace where kube-prometheus-stack is installed"
  value       = var.enable_prometheus ? var.prometheus_namespace : null
}

output "loki_namespace" {
  description = "Namespace where Loki is installed"
  value       = var.enable_loki ? var.loki_namespace : null
}

output "karpenter_role_arn" {
  description = "ARN of the Karpenter controller IRSA role, or null when enable_karpenter=false"
  value       = var.enable_karpenter ? aws_iam_role.karpenter[0].arn : null
}

output "karpenter_sqs_queue_url" {
  description = "URL of the SQS interruption queue used by Karpenter, or null when enable_karpenter=false"
  value       = var.enable_karpenter ? aws_sqs_queue.karpenter[0].url : null
}

output "efs_csi_addon_id" {
  description = "ID of the EFS CSI Driver managed add-on (cluster_name:addon_name), or null when enable_efs_csi_driver=false"
  value       = var.enable_efs_csi_driver ? aws_eks_addon.efs_csi[0].id : null
}
