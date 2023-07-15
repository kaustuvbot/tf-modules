output "monthly_budget_name" {
  description = "Name of the monthly cost budget"
  value       = aws_budgets_budget.monthly.name
}

output "forecast_budget_name" {
  description = "Name of the forecast budget"
  value       = aws_budgets_budget.forecast.name
}

output "anomaly_monitor_arn" {
  description = "ARN of the cost anomaly monitor"
  value       = ""
}
