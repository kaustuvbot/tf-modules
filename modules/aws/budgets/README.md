# AWS Budgets Module

Provisions monthly and forecast cost budgets with email alerts, and optionally enables Cost Anomaly Detection for proactive spend monitoring.

## Usage

```hcl
module "budgets" {
  source = "../../modules/aws/budgets"

  project     = "myproject"
  environment = "prod"

  monthly_budget_amount    = 500
  alert_email_addresses    = ["billing@example.com"]

  enable_anomaly_detection = true
  anomaly_threshold_amount = 50
}
```

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project` | `string` | — | Project name for budget naming |
| `environment` | `string` | — | Environment (`dev`, `staging`, `prod`) |
| `monthly_budget_amount` | `number` | — | Monthly budget limit (must be > 0) |
| `currency` | `string` | `"USD"` | Budget currency (`USD`, `EUR`, `GBP`) |
| `alert_email_addresses` | `list(string)` | `[]` | Email addresses for budget notifications (max 10) |
| `cost_filters` | `map(string)` | `{}` | Tag-based cost filter key/value pairs |
| `enable_anomaly_detection` | `bool` | `true` | Create a Cost Anomaly Detection monitor and subscription |
| `anomaly_threshold_amount` | `number` | `20` | Dollar threshold before anomaly alert fires |
| `tags` | `map(string)` | `{}` | Additional tags |

## Outputs

| Name | Description |
|------|-------------|
| `monthly_budget_name` | Name of the monthly cost budget |
| `forecast_budget_name` | Name of the forecast budget |
| `anomaly_monitor_arn` | ARN of the Cost Anomaly Monitor (null if disabled) |
| `anomaly_subscription_arn` | ARN of the anomaly alert subscription (null if disabled) |

## Notes

- Two budgets are created: a monthly actual-cost budget and a forecast budget (both at `monthly_budget_amount`).
- Budget alerts fire at 80% and 100% of the configured amount.
- Cost Anomaly Detection uses machine learning to detect unusual spend patterns. Set `anomaly_threshold_amount` to avoid noise from small fluctuations.
- `cost_filters` accepts tag key/value pairs. Example: `{ "TagKeyValue" = "user:Project$myproject" }`.
