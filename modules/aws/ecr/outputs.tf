output "repository_urls" {
  description = "Map of repository name to full ECR repository URL (e.g. 123456789.dkr.ecr.us-east-1.amazonaws.com/project/env/app)"
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}

output "repository_arns" {
  description = "Map of repository name to ARN. Use to scope IAM policies for push/pull access."
  value       = { for k, v in aws_ecr_repository.this : k => v.arn }
}

output "registry_id" {
  description = "AWS account ID that owns the registry (same for all repositories in an account)"
  value       = length(aws_ecr_repository.this) > 0 ? one(values(aws_ecr_repository.this)).registry_id : null
}
