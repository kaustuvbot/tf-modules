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

variable "retention_in_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 90

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.retention_in_days)
    error_message = "Retention must be a valid CloudWatch log group retention value."
  }
}

variable "enable_cloudtrail" {
  description = "Whether to create a CloudTrail trail"
  type        = bool
  default     = false
}

variable "enable_config" {
  description = "Whether to enable AWS Config recorder"
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting logs (optional, uses AWS managed key if not set)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to all logging resources"
  type        = map(string)
  default     = {}
}
