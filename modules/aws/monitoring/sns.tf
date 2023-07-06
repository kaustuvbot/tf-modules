# -----------------------------------------------------------------------------
# SNS → Slack Notification Bridge
# -----------------------------------------------------------------------------
# Forwards CloudWatch alarm notifications to a Slack channel via
# an SNS subscription to HTTPS (Slack incoming webhook).
#
# For production use, consider a Lambda bridge instead of direct
# HTTPS subscription for better message formatting and retry logic.
# A Lambda bridge will be added in a future enhancement.
# -----------------------------------------------------------------------------

resource "aws_sns_topic_subscription" "slack" {
  count = var.slack_webhook_url != null ? 1 : 0

  topic_arn              = local.sns_topic_arn
  protocol               = "https"
  endpoint               = var.slack_webhook_url
  endpoint_auto_confirms = true

  # Deliver raw JSON payload — Slack accepts this format
  raw_message_delivery = false
}

# -----------------------------------------------------------------------------
# SNS Topic Policy
# -----------------------------------------------------------------------------
# Allows CloudWatch to publish alarm state changes to the SNS topic.

data "aws_caller_identity" "current" {}

resource "aws_sns_topic_policy" "alerts" {
  count = var.sns_topic_arn == null ? 1 : 0

  arn = aws_sns_topic.alerts[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchPublish"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.alerts[0].arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:cloudwatch:*:${data.aws_caller_identity.current.account_id}:alarm:*"
          }
        }
      },
    ]
  })
}

# -----------------------------------------------------------------------------
# Email Subscription (optional)
# -----------------------------------------------------------------------------

resource "aws_sns_topic_subscription" "email" {
  count = length(var.alarm_email_addresses)

  topic_arn = local.sns_topic_arn
  protocol  = "email"
  endpoint  = var.alarm_email_addresses[count.index]
}
