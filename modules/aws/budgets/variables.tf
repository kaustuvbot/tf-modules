variable "project" {
  description = "Project name for budget naming and tagging"
  type        = string

  validation {
    condition     = length(var.project) >= 2 && length(var.project) <= 32
    error_message = "Project name must be between 2 and 32 characters."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "monthly_budget_amount" {
  description = "Monthly budget limit in USD"
  type        = number

  validation {
    condition     = var.monthly_budget_amount > 0
    error_message = "Monthly budget amount must be greater than 0."
  }
}

variable "currency" {
  description = "Currency for budget amounts (ISO 4217)"
  type        = string
  default     = "USD"

  validation {
    condition     = contains(["USD", "EUR", "GBP"], var.currency)
    error_message = "Currency must be one of: USD, EUR, GBP."
  }
}

variable "alert_email_addresses" {
  description = "List of email addresses to receive budget alert notifications"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.alert_email_addresses) <= 10
    error_message = "A maximum of 10 email addresses are supported per budget alert."
  }
}

variable "cost_filters" {
  description = "Map of cost filter key/value pairs (e.g., tag-based filters)"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags for budget-related resources"
  type        = map(string)
  default     = {}
}
