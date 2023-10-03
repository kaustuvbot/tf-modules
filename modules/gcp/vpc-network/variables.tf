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

variable "routing_mode" {
  description = "Regional or global routing mode"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "routing_mode must be REGIONAL or GLOBAL."
  }
}

variable "mtu" {
  description = "MTU for the VPC network"
  type        = number
  default     = 1460
}

variable "subnets" {
  description = "Map of subnet name to subnet configuration"
  type = map(object({
    region                 = string
    ip_cidr_range        = string
    private_ip_google_access = optional(bool, false)
    secondary_ranges = optional(map(string), null)
  }))
  default = {}
}

variable "labels" {
  description = "Additional labels"
  type        = map(string)
  default     = {}
}
