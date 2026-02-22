variable "project" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "bucket_name_suffix" {
  description = "Suffix for bucket name (prefix is environment-project)"
  type        = string
  default     = "bucket"
}

variable "location" {
  description = "GCP region"
  type        = string
  default     = "US"
}

variable "storage_class" {
  description = "Default storage class (STANDARD, NEARLINE, COLDLINE, ARCHIVE)"
  type        = string
  default     = "STANDARD"
}

variable "versioning_enabled" {
  description = "Enable object versioning"
  type        = bool
  default     = true
}

variable "uniform_bucket_level_access" {
  description = "Enforce uniform bucket-level access"
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules"
  type = list(object({
    action_type        = string
    storage_class      = optional(string, null)
    age                = optional(number, null)
    created_before     = optional(string, null)
    is_live            = optional(bool, null)
    matches_prefix     = optional(list(string), [])
    matches_suffix     = optional(list(string), [])
    num_newer_versions = optional(number, null)
  }))
  default = []
}

variable "kms_key_name" {
  description = "KMS key name for bucket encryption"
  type        = string
  default     = null
}

variable "retention_period_days" {
  description = "Object retention period in days (null to disable)"
  type        = number
  default     = null
}

variable "retention_policy_locked" {
  description = "Lock retention policy (cannot be changed)"
  type        = bool
  default     = false
}

variable "viewer_members" {
  description = "Members to grant objectViewer role"
  type        = list(string)
  default     = []
}

variable "editor_members" {
  description = "Members to grant objectAdmin role"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Additional labels"
  type        = map(string)
  default     = {}
}
