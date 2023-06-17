# -----------------------------------------------------------------------------
# AWS Logging Module
# -----------------------------------------------------------------------------
# Central logging infrastructure for audit and operational logs.
#
# Resources created:
#   - CloudWatch log group (central)
#   - S3 bucket for log delivery
#   - CloudTrail trail (optional)
#   - AWS Config recorder (optional)
# -----------------------------------------------------------------------------

locals {
  common_tags = merge(
    {
      Module      = "logging"
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}
