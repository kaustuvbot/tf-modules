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

variable "apply_branch" {
  description = "Branch name that the apply role is restricted to (e.g., main)"
  type        = string
  default     = "main"
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds for CI roles (1h–12h)"
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "Session duration must be between 3600 (1h) and 43200 (12h) seconds."
  }
}

variable "permissions_boundary_arn" {
  description = "ARN of an IAM policy to use as permissions boundary for CI roles (optional)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to all IAM resources"
  type        = map(string)
  default     = {}
}
