output "table_name" {
  description = "The name of the DynamoDB lock table"
  value       = aws_dynamodb_table.lock.name
}

output "table_arn" {
  description = "The ARN of the DynamoDB lock table"
  value       = aws_dynamodb_table.lock.arn
}
