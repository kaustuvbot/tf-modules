variable "project" {
  description = "Project name used as a prefix in resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "component" {
  description = "Component or service name"
  type        = string
  default     = ""
}

variable "suffix" {
  description = "Optional suffix for the resource name"
  type        = string
  default     = ""
}

variable "extra_tags" {
  description = "Additional tags to merge into the tags output"
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
