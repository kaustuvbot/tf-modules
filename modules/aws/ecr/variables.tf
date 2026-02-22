variable "project" {
  description = "Project name for resource naming and tagging"
  type        = string

  validation {
    condition     = length(var.project) >= 2 && length(var.project) <= 32
    error_message = "project must be between 2 and 32 characters."
  }
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "repositories" {
  description = "Map of repository name to configuration. The name is appended to <project>/<environment>/ to form the full repository path."
  type = map(object({
    image_tag_mutability = optional(string, "MUTABLE")
    scan_on_push         = optional(bool, true)
    untagged_expiry_days = optional(number, 14)
    tagged_keep_count    = optional(number, 30)
    kms_key_arn          = optional(string, null)
  }))

  validation {
    condition = alltrue([
      for repo in values(var.repositories) :
      contains(["MUTABLE", "IMMUTABLE"], repo.image_tag_mutability)
    ])
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE for each repository."
  }
}

variable "replication_configuration" {
  description = "Cross-region replication configuration for the registry"
  type = object({
    regions = list(string)
  })
  default = null
}

variable "tags" {
  description = "Additional tags to apply to all ECR resources"
  type        = map(string)
  default     = {}
}
