# -----------------------------------------------------------------------------
# AWS Budgets Module
# -----------------------------------------------------------------------------
# Manages cost budgets and anomaly detection for AWS spend governance.
#
# Resources created:
#   - Monthly cost budget with threshold alerts (80% actual, 100% actual, 110% forecast)
#   - Cost Anomaly Detection monitor and subscription
# -----------------------------------------------------------------------------

locals {
  budget_name_prefix = "${var.project}-${var.environment}"

  # Build notification subscriber list from email addresses
  subscribers = [
    for email in var.alert_email_addresses : {
      subscription_type = "EMAIL"
      address           = email
    }
  ]
}

# -----------------------------------------------------------------------------
# Monthly Cost Budget
# -----------------------------------------------------------------------------

resource "aws_budgets_budget" "monthly" {
  name         = "${local.budget_name_prefix}-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_amount)
  limit_unit   = var.currency
  time_unit    = "MONTHLY"

  dynamic "cost_filter" {
    for_each = var.cost_filters

    content {
      name   = cost_filter.key
      values = [cost_filter.value]
    }
  }

  # Alert at 80% actual spend
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.alert_email_addresses
  }

  # Alert at 100% actual spend
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.alert_email_addresses
  }

  # Alert when forecast exceeds 110% of budget
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 110
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.alert_email_addresses
  }
}

# -----------------------------------------------------------------------------
# Forecasted Spend Budget
# -----------------------------------------------------------------------------
# Separate budget that triggers earlier — warns when forecast will exceed
# budget before the month ends.

resource "aws_budgets_budget" "forecast" {
  name         = "${local.budget_name_prefix}-forecast"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_amount)
  limit_unit   = var.currency
  time_unit    = "MONTHLY"

  dynamic "cost_filter" {
    for_each = var.cost_filters

    content {
      name   = cost_filter.key
      values = [cost_filter.value]
    }
  }

  # Early warning: forecast exceeds 90% of budget
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 90
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.alert_email_addresses
  }
}
