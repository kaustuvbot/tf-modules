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

# Deprecated: use kubernetes_version instead. Kept for backward compatibility.
# When both are set, kubernetes_version takes precedence.
variable "cluster_version" {
  description = "Deprecated: use kubernetes_version. Kubernetes version for the EKS cluster."
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster. Supersedes the deprecated cluster_version variable. Must be in MAJOR.MINOR format (e.g. \"1.29\")."
  type        = string
  default     = "1.28"

  validation {
    condition     = can(regex("^\\d+\\.\\d+$", var.kubernetes_version))
    error_message = "kubernetes_version must be in MAJOR.MINOR format, e.g. \"1.29\". Do not include a patch version or 'v' prefix."
  }
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
    custom_ami_id  = optional(string, null)
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

  # AWS recommends at least 2 instance types for SPOT capacity pools to reduce
  # the probability of full node group outage on a single instance type interruption.
  validation {
    condition = alltrue([
      for ng in values(var.node_groups) :
      ng.capacity_type != "SPOT" || length(ng.instance_types) >= 2
    ])
    error_message = "SPOT node groups must specify at least 2 instance_types for capacity pool diversification. AWS best practice: use 3+ types from different families."
  }

  # When custom_ami_id is set, ami_type must be CUSTOM so EKS does not attempt
  # to override the launch template image_id with a managed AMI.
  validation {
    condition = alltrue([
      for ng in values(var.node_groups) :
      ng.custom_ami_id == null || ng.ami_type == "CUSTOM"
    ])
    error_message = "Set ami_type = \"CUSTOM\" on any node group that specifies custom_ami_id. Using a managed ami_type with a custom_ami_id causes EKS to override the image."
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

variable "cluster_log_retention_days" {
  description = "Number of days to retain EKS control plane logs in CloudWatch. Valid values: 0 (never expire), 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, or 3653."
  type        = number
  default     = 90

  validation {
    condition = contains(
      [0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653],
      var.cluster_log_retention_days
    )
    error_message = "cluster_log_retention_days must be a valid CloudWatch Logs retention value."
  }
}

variable "enable_cluster_autoscaler_irsa" {
  description = "Create an IRSA IAM role for the Kubernetes Cluster Autoscaler. Set true when running Cluster Autoscaler (not Karpenter) to allow it to describe and modify EC2 Auto Scaling groups."
  type        = bool
  default     = false
}

variable "enable_velero_irsa" {
  description = "Create an IRSA IAM role for Velero backup/restore. When true, an OIDC-scoped role with S3 and EC2 snapshot permissions is created for the velero/velero service account."
  type        = bool
  default     = false
}

variable "velero_backup_bucket_arns" {
  description = "List of S3 bucket ARNs that Velero is allowed to read/write for backups. Required when enable_velero_irsa=true."
  type        = list(string)
  default     = []
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
# Pod Security Admission
# -----------------------------------------------------------------------------

variable "pod_security_standards" {
  description = <<-EOT
    Map of Kubernetes namespace names to their Pod Security Admission enforce level.
    Valid levels: privileged, baseline, restricted.
    These labels must be applied to namespaces after cluster creation via a
    Kubernetes provider. This variable stores the desired state for reference
    and is surfaced via the psa_namespace_labels output.
    Example: { "kube-system" = "privileged", "app" = "restricted" }
  EOT
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for level in values(var.pod_security_standards) :
      contains(["privileged", "baseline", "restricted"], level)
    ])
    error_message = "Pod security levels must be one of: privileged, baseline, restricted."
  }
}

variable "authentication_mode" {
  description = "EKS cluster authentication mode. API_AND_CONFIG_MAP supports both aws-auth ConfigMap and EKS access entries."
  type        = string
  default     = "API_AND_CONFIG_MAP"

  validation {
    condition     = contains(["CONFIG_MAP", "API", "API_AND_CONFIG_MAP"], var.authentication_mode)
    error_message = "authentication_mode must be one of: CONFIG_MAP, API, API_AND_CONFIG_MAP."
  }
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

variable "managed_addon_versions" {
  description = <<-EOT
    Map of EKS managed add-on name to version string. Takes precedence over the
    individual vpc_cni_version, coredns_version, and kube_proxy_version variables.
    Null values resolve to the latest available version for that add-on.
    Example: { "vpc-cni" = "v1.16.0-eksbuild.1", "coredns" = null }
  EOT
  type        = map(string)
  default     = {}
}

# Deprecated: prefer managed_addon_versions = { "vpc-cni" = "<version>" }
variable "vpc_cni_version" {
  description = "Deprecated: use managed_addon_versions. Version of the vpc-cni managed add-on. null = latest."
  type        = string
  default     = null
}

# Deprecated: prefer managed_addon_versions = { "coredns" = "<version>" }
variable "coredns_version" {
  description = "Deprecated: use managed_addon_versions. Version of the coredns managed add-on. null = latest."
  type        = string
  default     = null
}

# Deprecated: prefer managed_addon_versions = { "kube-proxy" = "<version>" }
variable "kube_proxy_version" {
  description = "Deprecated: use managed_addon_versions. Version of the kube-proxy managed add-on. null = latest."
  type        = string
  default     = null
}
