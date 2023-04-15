output "account_id" {
  description = "The AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "caller_arn" {
  description = "The ARN of the caller (user or role)"
  value       = data.aws_caller_identity.current.arn
}

output "region" {
  description = "The current AWS region"
  value       = data.aws_region.current.name
}
