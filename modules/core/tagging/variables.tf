variable "project" {
  description = "Project name for tagging"
  type        = string
}

variable "environment" {
  description = "Environment name for tagging (e.g., dev, staging, prod)"
  type        = string
}

variable "extra_tags" {
  description = "Additional tags to merge with defaults"
  type        = map(string)
  default     = {}
}

variable "cloud_provider" {
  description = "Cloud provider: aws, azure, or gcp"
  type        = string
  default     = "aws"

  validation {
    condition     = contains(["aws", "azure", "gcp"], var.cloud_provider)
    error_message = "cloud_provider must be aws, azure, or gcp."
  }
}
