output "logs_key_arn" {
  description = "ARN of the logs encryption KMS key"
  value       = var.enable_logs_key ? aws_kms_key.logs[0].arn : null
}

output "logs_key_id" {
  description = "ID of the logs encryption KMS key"
  value       = var.enable_logs_key ? aws_kms_key.logs[0].key_id : null
}

output "state_key_arn" {
  description = "ARN of the state encryption KMS key"
  value       = var.enable_state_key ? aws_kms_key.state[0].arn : null
}

output "state_key_id" {
  description = "ID of the state encryption KMS key"
  value       = var.enable_state_key ? aws_kms_key.state[0].key_id : null
}

output "general_key_arn" {
  description = "ARN of the general-purpose KMS key"
  value       = var.enable_general_key ? aws_kms_key.general[0].arn : null
}

output "general_key_id" {
  description = "ID of the general-purpose KMS key"
  value       = var.enable_general_key ? aws_kms_key.general[0].key_id : null
}

output "logs_key_alias" {
  description = "Alias name for the logs KMS key"
  value       = var.enable_logs_key ? aws_kms_alias.logs[0].name : null
}

output "state_key_alias" {
  description = "Alias name for the state KMS key"
  value       = var.enable_state_key ? aws_kms_alias.state[0].name : null
}

output "general_key_alias" {
  description = "Alias name for the general-purpose KMS key"
  value       = var.enable_general_key ? aws_kms_alias.general[0].name : null
}
