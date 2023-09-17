locals {
  name_prefix = "${var.project}-${var.environment}"

  default_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  tags = merge(local.default_tags, var.tags)
}

resource "aws_guardduty_detector" "this" {
  enable = true

  datasources {
    s3_logs {
      enable = var.enable_s3_logs
    }

    kubernetes {
      audit_logs {
        enable = var.enable_kubernetes_logs
      }
    }

    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = var.enable_malware_protection
        }
      }
    }
  }

  tags = local.tags
}

resource "aws_guardduty_publishing_destination" "s3" {
  count = var.findings_s3_bucket_arn != null ? 1 : 0

  detector_id     = aws_guardduty_detector.this.id
  destination_arn = var.findings_s3_bucket_arn
  kms_key_arn     = var.findings_s3_kms_key_arn

  destination_type = "S3"
}
