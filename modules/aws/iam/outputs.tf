output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC identity provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "oidc_provider_url" {
  description = "URL of the GitHub OIDC identity provider"
  value       = aws_iam_openid_connect_provider.github.url
}

output "plan_role_arn" {
  description = "ARN of the CI plan (read-only) role"
  value       = ""
}

output "apply_role_arn" {
  description = "ARN of the CI apply (read-write) role"
  value       = ""
}
