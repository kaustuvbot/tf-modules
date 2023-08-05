# -----------------------------------------------------------------------------
# Azure Monitoring Variables
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
  description = "Azure region for alert resources"
  type        = string
}

variable "aks_cluster_id" {
  description = "Resource ID of the AKS cluster to monitor"
  type        = string
}

variable "action_group_email" {
  description = "Email address to notify on alert"
  type        = string
  default     = null
}

variable "cpu_threshold_percent" {
  description = "CPU usage threshold percentage to trigger alert"
  type        = number
  default     = 80
}

variable "memory_threshold_percent" {
  description = "Memory working set threshold percentage to trigger alert"
  type        = number
  default     = 80
}

variable "tags" {
  description = "Additional tags to merge with default tags"
  type        = map(string)
  default     = {}
}
