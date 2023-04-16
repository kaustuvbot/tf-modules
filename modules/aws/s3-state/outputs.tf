output "bucket_id" {
  description = "The name of the S3 state bucket"
  value       = aws_s3_bucket.state.id
}

output "bucket_arn" {
  description = "The ARN of the S3 state bucket"
  value       = aws_s3_bucket.state.arn
}

output "bucket_name" {
  description = "The name of the S3 state bucket"
  value       = aws_s3_bucket.state.bucket
}
