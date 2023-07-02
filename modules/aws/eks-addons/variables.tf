variable "project" {
  description = "Project name for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider for IRSA"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the EKS OIDC provider (without https://)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the cluster is deployed"
  type        = string
}

variable "enable_alb_controller" {
  description = "Whether to install the AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "alb_controller_version" {
  description = "Helm chart version for AWS Load Balancer Controller"
  type        = string
  default     = "1.6.2"
}

variable "tags" {
  description = "Additional tags to apply to all add-on resources"
  type        = map(string)
  default     = {}
}
