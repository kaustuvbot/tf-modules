# -----------------------------------------------------------------------------
# Azure Key Vault Variables
# -----------------------------------------------------------------------------

variable "project" {
  description = "Project name used in resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
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

variable "tags" {
  description = "Additional tags to merge with default tags"
  type        = map(string)
  default     = {}
}
