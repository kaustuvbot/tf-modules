variable "project" {
  description = "Project name for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name for metric dimensions"
  type        = string
  default     = ""
}

variable "enable_eks_alarms" {
  description = "Whether to create EKS-related CloudWatch alarms"
  type        = bool
  default     = false
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications (optional, created internally if not set)"
  type        = string
  default     = null
}

variable "alarm_cpu_threshold" {
  description = "CPU utilization threshold percentage for alarm"
  type        = number
  default     = 80
}

variable "alarm_memory_threshold" {
  description = "Memory utilization threshold percentage for alarm"
  type        = number
  default     = 80
}

variable "alarm_evaluation_periods" {
  description = "Number of evaluation periods before alarm triggers"
  type        = number
  default     = 3
}

variable "alarm_period" {
  description = "Period in seconds for each evaluation"
  type        = number
  default     = 300
}

variable "alarm_email_addresses" {
  description = "List of email addresses to subscribe to alarm notifications"
  type        = list(string)
  default     = []
}

variable "slack_webhook_url" {
  description = "Slack incoming webhook URL for alarm notifications (optional)"
  type        = string
  default     = null
  sensitive   = true
}

variable "slack_channel" {
  description = "Slack channel name for alarm notifications (e.g., #alerts)"
  type        = string
  default     = "#alerts"
}

variable "tags" {
  description = "Additional tags to apply to all monitoring resources"
  type        = map(string)
  default     = {}
}
