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
