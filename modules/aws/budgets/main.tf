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

  # AWS Budgets API requires limit_amount as a string with exactly 2 decimal places
  # e.g. "500" is rejected, "500.00" is accepted
  formatted_amount = format("%.2f", var.monthly_budget_amount)

  # Guard against empty email list for anomaly subscription
  anomaly_email = length(var.alert_email_addresses) > 0 ? var.alert_email_addresses[0] : null
}

# -----------------------------------------------------------------------------
# Monthly Cost Budget
# -----------------------------------------------------------------------------

resource "aws_budgets_budget" "monthly" {
  name         = "${local.budget_name_prefix}-monthly"
  budget_type  = "COST"
  limit_amount = local.formatted_amount
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
  limit_amount = local.formatted_amount
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

# -----------------------------------------------------------------------------
# Cost Anomaly Detection
# -----------------------------------------------------------------------------
# Detects unexpected spend spikes outside normal patterns using ML.
# More reliable than threshold-based alerts for catching novel cost events.

resource "aws_ce_anomaly_monitor" "this" {
  count = var.enable_anomaly_detection ? 1 : 0

  name              = "${local.budget_name_prefix}-anomaly-monitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

resource "aws_ce_anomaly_subscription" "this" {
  count = var.enable_anomaly_detection && local.anomaly_email != null ? 1 : 0

  name      = "${local.budget_name_prefix}-anomaly-subscription"
  frequency = "DAILY"

  monitor_arn_list = [aws_ce_anomaly_monitor.this[0].arn]

  subscriber {
    type    = "EMAIL"
    address = local.anomaly_email
  }

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      values        = [tostring(var.anomaly_threshold_amount)]
      match_options = ["GREATER_THAN_OR_EQUAL"]
    }
  }
}
