variable "cloud" {
  description = "Target cloud provider: aws or azure"
  type        = string

  validation {
    condition     = contains(["aws", "azure"], var.cloud)
    error_message = "cloud must be one of: aws, azure."
  }
}

variable "project" {
  description = "Project name used across all modules for naming and tagging"
  type        = string

  validation {
    condition     = length(var.project) >= 2 && length(var.project) <= 24
    error_message = "project must be between 2 and 24 characters."
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

variable "aws_config" {
  description = "AWS-specific configuration. Required when cloud=aws."
  type = object({
    region             = string
    vpc_cidr           = string
    availability_zones = list(string)
    eks_version        = optional(string, "1.29")
    enable_nat_gateway = optional(bool, true)
  })
  default = null
}

variable "azure_config" {
  description = "Azure-specific configuration. Required when cloud=azure."
  type = object({
    location            = string
    vnet_cidr           = string
    subscription_id     = string
    kubernetes_version  = optional(string, "1.29")
    enable_private_cluster = optional(bool, false)
  })
  default = null
}

variable "tags" {
  description = "Additional tags/labels to apply to all resources"
  type        = map(string)
  default     = {}
}
