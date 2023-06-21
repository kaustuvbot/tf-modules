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
    labels         = optional(map(string), {})
  }))
  default = {
    default = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 1
      max_size       = 4
    }
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN for EKS secrets encryption (optional)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to all EKS resources"
  type        = map(string)
  default     = {}
}
