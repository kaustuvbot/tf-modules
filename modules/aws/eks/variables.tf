variable "project" {
  description = "Project name for resource naming and tagging"
  type        = string

  validation {
    condition     = length(var.project) >= 2 && length(var.project) <= 32
    error_message = "Project name must be between 2 and 32 characters."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster (private subnets recommended)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnets in different AZs are required for EKS."
  }
}

variable "node_groups" {
  description = "Map of managed node group configurations"
  type = map(object({
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    disk_size      = optional(number, 50)
    capacity_type  = optional(string, "ON_DEMAND")
    ami_type       = optional(string, "AL2_x86_64")
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })), [])
  }))
  default = {
    default = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 1
      max_size       = 4
    }
  }

  validation {
    condition = alltrue([
      for ng in values(var.node_groups) :
      contains(["ON_DEMAND", "SPOT"], ng.capacity_type)
    ])
    error_message = "capacity_type must be ON_DEMAND or SPOT for each node group."
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN for EKS secrets encryption. Required in prod environments."
  type        = string
  default     = null

  validation {
    condition     = !(var.environment == "prod" && var.kms_key_arn == null)
    error_message = "kms_key_arn must be set in prod to enable secrets encryption at rest."
  }
}

variable "enabled_cluster_log_types" {
  description = "List of EKS control plane log types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "endpoint_public_access" {
  description = "Enable public access to the EKS API server endpoint"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks allowed to reach the public API server. Defaults to 0.0.0.0/0 when empty."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to apply to all EKS resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Launch Template / IMDS
# -----------------------------------------------------------------------------

variable "imdsv2_required" {
  description = "Require IMDSv2 (token-based) on all nodes. Recommended: true."
  type        = bool
  default     = true
}

variable "metadata_http_put_response_hop_limit" {
  description = "Number of network hops the metadata PUT response can traverse. Set to 1 to block pod access to IMDS."
  type        = number
  default     = 1
}

# -----------------------------------------------------------------------------
# Managed Add-ons
# -----------------------------------------------------------------------------

variable "enable_managed_addons" {
  description = "Enable EKS managed add-ons (vpc-cni, coredns, kube-proxy)"
  type        = bool
  default     = true
}

variable "vpc_cni_version" {
  description = "Version of the vpc-cni managed add-on. null = latest."
  type        = string
  default     = null
}

variable "coredns_version" {
  description = "Version of the coredns managed add-on. null = latest."
  type        = string
  default     = null
}

variable "kube_proxy_version" {
  description = "Version of the kube-proxy managed add-on. null = latest."
  type        = string
  default     = null
}
