output "log_group_name" {
  description = "Name of the central CloudWatch log group"
  value       = ""
}

output "log_group_arn" {
  description = "ARN of the central CloudWatch log group"
  value       = ""
}

output "log_bucket_id" {
  description = "ID of the S3 bucket for log delivery"
  value       = ""
}

output "log_bucket_arn" {
  description = "ARN of the S3 bucket for log delivery"
  value       = ""
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail (if enabled)"
  value       = ""
}

output "config_recorder_id" {
  description = "ID of the AWS Config recorder (if enabled)"
  value       = ""
}
