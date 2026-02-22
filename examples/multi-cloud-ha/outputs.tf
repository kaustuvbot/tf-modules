output "aws_vpc_id" {
  description = "AWS VPC ID (primary)"
  value       = module.aws_vpc.vpc_id
}

output "azure_vnet_id" {
  description = "Azure VNet ID (secondary)"
  value       = module.azure_vnet.vnet_id
}

output "gcp_network_id" {
  description = "GCP Network ID (tertiary)"
  value       = module.gcp_vpc.network_id
}

output "primary_health_check_id" {
  description = "Route53 health check ID for primary"
  value       = aws_route53_health_check.primary.id
}

output "secondary_health_check_id" {
  description = "Route53 health check ID for secondary"
  value       = aws_route53_health_check.secondary.id
}

output "tertiary_health_check_id" {
  description = "Route53 health check ID for tertiary"
  value       = aws_route53_health_check.tertiary.id
}
