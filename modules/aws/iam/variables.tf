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

variable "github_org" {
  description = "GitHub organization or username for OIDC trust"
  type        = string
}

variable "github_repositories" {
  description = "List of GitHub repositories allowed to assume CI roles (e.g., ['my-org/my-repo'])"
  type        = list(string)

  validation {
    condition     = length(var.github_repositories) > 0
    error_message = "At least one GitHub repository must be specified."
  }
}

variable "tags" {
  description = "Additional tags to apply to all IAM resources"
  type        = map(string)
  default     = {}
}
