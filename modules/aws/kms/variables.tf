variable "project" {
  description = "Project name for resource naming and tagging"
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

variable "enable_logs_key" {
  description = "Whether to create a KMS key for log encryption"
  type        = bool
  default     = true
}

variable "enable_state_key" {
  description = "Whether to create a KMS key for Terraform state encryption"
  type        = bool
  default     = true
}

variable "enable_general_key" {
  description = "Whether to create a general-purpose KMS key"
  type        = bool
  default     = false
}

variable "deletion_window_in_days" {
  description = "Number of days before KMS key deletion (7–30)"
  type        = number
  default     = 30

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "Deletion window must be between 7 and 30 days."
  }
}

variable "tags" {
  description = "Additional tags to apply to all KMS resources"
  type        = map(string)
  default     = {}
}
