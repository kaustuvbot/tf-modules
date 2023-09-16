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

  validation {
    condition     = !(var.environment == "prod" && var.private_cluster_enabled == false)
    error_message = "private_cluster_enabled must be true in prod environments."
  }
}

variable "authorized_ip_ranges" {
  description = "List of CIDR ranges allowed to reach the public API server endpoint. Ignored when private_cluster_enabled=true."
  type        = list(string)
  default     = []
}

variable "workload_identity_enabled" {
  description = "Enable Azure Workload Identity and the OIDC issuer on the cluster"
  type        = bool
  default     = false
}

variable "azure_policy_enabled" {
  description = "Enable the Azure Policy add-on for Kubernetes (OPA Gatekeeper integration)"
  type        = bool
  default     = false
}

variable "maintenance_window" {
  description = "Maintenance window configuration for automatic upgrades. Set to null to use the default maintenance window."
  type = object({
    day   = string       # Monday, Tuesday, ..., Sunday
    hours = list(number) # UTC hours (0-23) during which maintenance is allowed
  })
  default = null
}

variable "network_policy" {
  description = "Network policy engine for the cluster. 'calico' or 'azure'. Enables pod-level traffic control."
  type        = string
  default     = "calico"

  validation {
    condition     = contains(["calico", "azure", "none"], var.network_policy)
    error_message = "network_policy must be one of: calico, azure, none."
  }
}

variable "auto_upgrade_channel" {
  description = "Automatic upgrade channel for the AKS cluster. 'patch' applies only patch-level upgrades automatically."
  type        = string
  default     = "patch"

  validation {
    condition     = contains(["none", "patch", "stable", "rapid", "node-image"], var.auto_upgrade_channel)
    error_message = "auto_upgrade_channel must be one of: none, patch, stable, rapid, node-image."
  }
}

variable "enable_defender" {
  description = "Enable Microsoft Defender for Containers on the AKS cluster"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace resource ID. Required when enable_defender is true."
  type        = string
  default     = null

  validation {
    condition     = !(var.enable_defender == true && var.log_analytics_workspace_id == null)
    error_message = "log_analytics_workspace_id must be set when enable_defender is true."
  }
}

variable "tags" {
  description = "Additional tags to merge with default tags"
  type        = map(string)
  default     = {}
}
