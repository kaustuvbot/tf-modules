variable "project" {
  description = "Project name for tagging"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{2,24}$", var.project))
    error_message = "project must be 2-24 lowercase alphanumeric characters or hyphens."
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

variable "resource_group_name" {
  description = "Resource group to create the DNS zone in"
  type        = string
}

variable "zone_name" {
  description = <<-EOT
    Private DNS zone name. For AKS private clusters use the zone provided by
    Azure in the format: privatelink.<region>.azmk8s.io
    Example: privatelink.eastus.azmk8s.io
  EOT
  type        = string
}

variable "vnet_links" {
  description = "Map of VNet link name to VNet resource ID. Each linked VNet can resolve names in this zone."
  type        = map(string)
  default     = {}
}

variable "registration_enabled" {
  description = "Enable auto-registration of VM hostnames in this zone for linked VNets. Set to false for AKS private cluster zones."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to all DNS resources"
  type        = map(string)
  default     = {}
}
