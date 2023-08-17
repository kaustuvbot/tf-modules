# S3 bucket for Terraform remote state storage.
#
# Features:
# - Versioning enabled for state history
# - Server-side encryption (AES256 by default, KMS CMK if kms_key_arn is set)
# - Public access fully blocked
# - Optional force_destroy for dev environments

locals {
  tags          = merge({ ManagedBy = "terraform" }, var.tags)
  sse_algorithm = var.kms_key_arn != null ? "aws:kms" : "AES256"
}

resource "aws_s3_bucket" "state" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = local.sse_algorithm
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_logging" "state" {
  count = var.access_log_bucket != null ? 1 : 0

  bucket        = aws_s3_bucket.state.id
  target_bucket = var.access_log_bucket
  target_prefix = var.access_log_prefix
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
