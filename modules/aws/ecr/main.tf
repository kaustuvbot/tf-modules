# -----------------------------------------------------------------------------
# AWS ECR Repositories
# -----------------------------------------------------------------------------
# Creates one ECR repository per entry in var.repositories. Each repository:
#   - Enables image scanning on push (CIS Benchmark 5.3)
#   - Applies a lifecycle policy to expire untagged images and cap tagged count
#   - Optionally enables KMS encryption (defaults to AES-256 managed by AWS)
# -----------------------------------------------------------------------------

locals {
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "ecr"
    },
    var.tags,
  )
}

data "aws_caller_identity" "current" {}

resource "aws_ecr_repository" "this" {
  for_each = var.repositories

  name                 = "${var.project}/${var.environment}/${each.key}"
  image_tag_mutability = each.value.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = each.value.scan_on_push
  }

  dynamic "encryption_configuration" {
    for_each = each.value.kms_key_arn != null ? [1] : []

    content {
      encryption_type = "KMS"
      kms_key         = each.value.kms_key_arn
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}/${var.environment}/${each.key}"
  })
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = var.repositories

  repository = aws_ecr_repository.this[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after ${each.value.untagged_expiry_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = each.value.untagged_expiry_days
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep only the ${each.value.tagged_keep_count} most recent tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "sha-", "release-"]
          countType     = "imageCountMoreThan"
          countNumber   = each.value.tagged_keep_count
        }
        action = { type = "expire" }
      },
    ]
  })
}

resource "aws_ecr_registry_policy" "this" {
  count = var.replication_configuration != null ? 1 : 0

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "Replication"
        Effect = "Allow",
        Principal = {
          Service = "ecr.amazonaws.com"
        },
        Action = [
          "ecr:BatchImportImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ],
        Resource = "arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/${var.project}/${var.environment}/*"
      }
    ]
  })
}

resource "aws_ecr_replication_configuration" "this" {
  count = var.replication_configuration != null ? 1 : 0

  dynamic "rule" {
    for_each = var.replication_configuration.regions
    content {
      destination {
        region      = rule.value
        registry_id = data.aws_caller_identity.current.account_id
      }
    }
  }
}
