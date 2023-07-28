# -----------------------------------------------------------------------------
# Azure AKS Variables
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
  description = "Azure region for the AKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the AKS cluster"
  type        = string
  default     = null
}

variable "system_node_pool_subnet_id" {
  description = "Subnet ID for the system node pool"
  type        = string
}

variable "private_cluster_enabled" {
  description = "Deploy the API server as a private endpoint (recommended for prod)"
  type        = bool
  default     = false
}

variable "authorized_ip_ranges" {
  description = "List of CIDR ranges allowed to reach the public API server endpoint. Ignored when private_cluster_enabled=true."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to merge with default tags"
  type        = map(string)
  default     = {}
}
