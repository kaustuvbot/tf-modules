# -----------------------------------------------------------------------------
# AWS KMS Module
# -----------------------------------------------------------------------------
# Manages baseline KMS keys for encryption across the platform.
#
# Keys available:
#   - Logs key: encrypts CloudWatch logs, S3 log buckets, CloudTrail
#   - State key: encrypts Terraform state in S3
#   - General key: general-purpose encryption for other services
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  common_tags = merge(
    {
      Module      = "kms"
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}

# -----------------------------------------------------------------------------
# Logs Encryption Key
# -----------------------------------------------------------------------------

resource "aws_kms_key" "logs" {
  count = var.enable_logs_key ? 1 : 0

  description                        = "Encryption key for ${var.project}-${var.environment} logs"
  deletion_window_in_days            = var.deletion_window_in_days
  enable_key_rotation                = var.enable_key_rotation
  bypass_policy_lockout_safety_check = var.bypass_policy_lockout_safety_check

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootAccountAccess"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${local.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowCloudWatchLogs"
        Effect    = "Allow"
        Principal = { Service = "logs.amazonaws.com" }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
        ]
        Resource = "*"
      },
      {
        Sid       = "AllowCloudTrail"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action = [
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
        ]
        Resource = "*"
      },
    ]
  })

  tags = merge(local.common_tags, {
    Name    = "${var.project}-${var.environment}-logs-key"
    Purpose = "logs-encryption"
  })
}

resource "aws_kms_alias" "logs" {
  count = var.enable_logs_key ? 1 : 0

  name          = "alias/${var.project}-${var.environment}-logs"
  target_key_id = aws_kms_key.logs[0].key_id
}

# -----------------------------------------------------------------------------
# State Encryption Key
# -----------------------------------------------------------------------------

resource "aws_kms_key" "state" {
  count = var.enable_state_key ? 1 : 0

  description                        = "Encryption key for ${var.project}-${var.environment} Terraform state"
  deletion_window_in_days            = var.deletion_window_in_days
  enable_key_rotation                = var.enable_key_rotation
  bypass_policy_lockout_safety_check = var.bypass_policy_lockout_safety_check

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootAccountAccess"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${local.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
    ]
  })

  tags = merge(local.common_tags, {
    Name    = "${var.project}-${var.environment}-state-key"
    Purpose = "state-encryption"
  })
}

resource "aws_kms_alias" "state" {
  count = var.enable_state_key ? 1 : 0

  name          = "alias/${var.project}-${var.environment}-state"
  target_key_id = aws_kms_key.state[0].key_id
}

# -----------------------------------------------------------------------------
# General-Purpose Encryption Key
# -----------------------------------------------------------------------------

resource "aws_kms_key" "general" {
  count = var.enable_general_key ? 1 : 0

  description                        = "General-purpose encryption key for ${var.project}-${var.environment}"
  deletion_window_in_days            = var.deletion_window_in_days
  enable_key_rotation                = var.enable_key_rotation
  bypass_policy_lockout_safety_check = var.bypass_policy_lockout_safety_check

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootAccountAccess"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${local.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
    ]
  })

  tags = merge(local.common_tags, {
    Name    = "${var.project}-${var.environment}-general-key"
    Purpose = "general-encryption"
  })
}

resource "aws_kms_alias" "general" {
  count = var.enable_general_key ? 1 : 0

  name          = "alias/${var.project}-${var.environment}-general"
  target_key_id = aws_kms_key.general[0].key_id
}
