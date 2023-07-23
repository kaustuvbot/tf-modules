# -----------------------------------------------------------------------------
# Azure Resource Group Variables
# -----------------------------------------------------------------------------

variable "project" {
  description = "Project name used in resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Azure region for the resource group"
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "Additional tags to merge with default tags"
  type        = map(string)
  default     = {}
}
