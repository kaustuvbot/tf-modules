variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use (optional, for local development)"
  type        = string
  default     = null
}

variable "aws_account_id" {
  description = "Expected AWS account ID for validation (optional)"
  type        = string
  default     = null
}

variable "project" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "extra_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
