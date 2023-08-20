output "log_group_name" {
  description = "Name of the central CloudWatch log group"
  value       = aws_cloudwatch_log_group.central.name
}

output "log_group_arn" {
  description = "ARN of the central CloudWatch log group"
  value       = aws_cloudwatch_log_group.central.arn
}

output "log_bucket_id" {
  description = "ID of the S3 bucket for log delivery"
  value       = aws_s3_bucket.logs.id
}

output "log_bucket_arn" {
  description = "ARN of the S3 bucket for log delivery"
  value       = aws_s3_bucket.logs.arn
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail (if enabled)"
  value       = var.enable_cloudtrail ? aws_cloudtrail.this[0].arn : null
}

output "config_recorder_id" {
  description = "ID of the AWS Config recorder (if enabled)"
  value       = var.enable_config ? aws_config_configuration_recorder.this[0].id : null
}

output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector (if enabled)"
  value       = var.enable_guardduty ? aws_guardduty_detector.this[0].id : null
}
