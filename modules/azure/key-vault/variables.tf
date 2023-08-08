# -----------------------------------------------------------------------------
# Azure Key Vault Variables
# -----------------------------------------------------------------------------

variable "project" {
  description = "Project name used in resource naming"
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
  description = "Name of the resource group to deploy into"
  type        = string
}

variable "location" {
  description = "Azure region for the Key Vault"
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID (required for access policies)"
  type        = string
}

variable "sku_name" {
  description = "SKU for the Key Vault (standard or premium)"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "sku_name must be standard or premium."
  }
}

variable "soft_delete_retention_days" {
  description = "Number of days to retain soft-deleted objects (7–90)"
  type        = number
  default     = 30
}

variable "purge_protection_enabled" {
  description = "Enable purge protection to prevent permanent deletion before retention expires"
  type        = bool
  default     = true
}

variable "network_acls_bypass" {
  description = "Services to bypass the network ACL (AzureServices, None)"
  type        = string
  default     = "AzureServices"

  validation {
    condition     = contains(["AzureServices", "None"], var.network_acls_bypass)
    error_message = "network_acls_bypass must be AzureServices or None."
  }
}

variable "network_acls_default_action" {
  description = "Default action for the network ACL when no rule matches (Allow, Deny)"
  type        = string
  default     = "Allow"

  validation {
    condition     = contains(["Allow", "Deny"], var.network_acls_default_action)
    error_message = "network_acls_default_action must be Allow or Deny."
  }
}

variable "network_acls_ip_rules" {
  description = "List of IP ranges allowed by the Key Vault network ACL"
  type        = list(string)
  default     = []
}

variable "network_acls_subnet_ids" {
  description = "List of subnet IDs allowed by the Key Vault network ACL"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to merge with default tags"
  type        = map(string)
  default     = {}
}
