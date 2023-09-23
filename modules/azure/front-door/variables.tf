variable "project" {
  description = "Project name for resource naming and tagging"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{2,24}$", var.project))
    error_message = "project must be 2-24 lowercase alphanumeric characters or hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "resource_group_name" {
  description = "Resource group to deploy Front Door into"
  type        = string
}

variable "sku_name" {
  description = "Front Door SKU: Standard_AzureFrontDoor or Premium_AzureFrontDoor"
  type        = string
  default     = "Standard_AzureFrontDoor"

  validation {
    condition     = contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], var.sku_name)
    error_message = "sku_name must be Standard_AzureFrontDoor or Premium_AzureFrontDoor."
  }
}

variable "origins" {
  description = "Map of origin configurations. Key = origin name, value = origin settings."
  type = map(object({
    host_name           = string
    http_port           = optional(number, 80)
    https_port          = optional(number, 443)
    origin_host_header  = optional(string, null)
    priority            = optional(number, 1)
    weight              = optional(number, 1000)
    enabled             = optional(bool, true)
  }))
  default = {}
}

variable "tags" {
  description = "Additional tags to apply to Front Door resources"
  type        = map(string)
  default     = {}
}
