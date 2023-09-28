variable "project" {
  description = "Project name used in resource naming (2-24 lowercase alphanumeric or hyphens)"
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
  description = "Name of the resource group to deploy the registry into"
  type        = string
}

variable "location" {
  description = "Azure region for the container registry"
  type        = string
}

variable "sku" {
  description = "SKU tier for the container registry. Basic: dev/test. Standard: production. Premium: geo-replication and private endpoints."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be one of: Basic, Standard, Premium."
  }
}

variable "public_network_access_enabled" {
  description = "Allow public network access to the registry. Set to false and configure private endpoints for production environments."
  type        = bool
  default     = true
}

variable "zone_redundancy_enabled" {
  description = "Enable zone redundancy for the registry. Requires Premium SKU and a region that supports availability zones."
  type        = bool
  default     = false

  validation {
    condition     = !(var.zone_redundancy_enabled && var.sku != "Premium")
    error_message = "zone_redundancy_enabled requires sku = Premium."
  }
}

variable "georeplications" {
  description = "List of geo-replication locations for Premium SKU registries. Each entry specifies the Azure region and zone redundancy for the replica."
  type = list(object({
    location                = string
    zone_redundancy_enabled = optional(bool, false)
  }))
  default = []

  validation {
    condition     = length(var.georeplications) == 0 || var.sku == "Premium"
    error_message = "georeplications requires sku = Premium."
  }
}

variable "tags" {
  description = "Additional tags to merge with default module tags"
  type        = map(string)
  default     = {}
}
