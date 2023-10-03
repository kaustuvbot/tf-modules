variable "project" {
  description = "Project ID for GCP resources"
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

variable "service_accounts" {
  description = "Map of service account name to configuration"
  type = map(object({
    display_name = string
    description  = optional(string, "")
  }))
  default = {}
}

variable "project_roles" {
  description = "List of project IAM member bindings (role = 'roles/owner', member = 'user:email@example.com')"
  type = map(object({
    role   = string
    member = string
  }))
  default = {}
}

variable "project_bindings" {
  description = "Map of project IAM binding name to configuration"
  type = map(object({
    role    = string
    members = list(string)
  }))
  default = {}
}

variable "workload_identity_enabled" {
  description = "Enable Workload Identity for GKE integration"
  type        = bool
  default     = false
}

variable "workload_identity_pool" {
  description = "Workload Identity pool name"
  type        = string
  default     = "default-pool"
}

variable "service_accounts_keys" {
  description = "List of service account keys to grant Workload Identity access"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Additional labels"
  type        = map(string)
  default     = {}
}
