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

variable "cluster_endpoint" {
  description = "EKS cluster API server endpoint (used by Helm provider)"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "Base64-encoded CA certificate for the EKS cluster"
  type        = string
}

variable "region" {
  description = "AWS region where the cluster is deployed"
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

variable "alb_default_ssl_policy" {
  description = "Default SSL policy for ALBs created by the controller. Applies when no per-Ingress annotation overrides it."
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "enable_waf_v2" {
  description = "Enable AWS WAFv2 and Shield Advanced integration on the AWS Load Balancer Controller. When true, sets enableWaf=true and enableShield=true Helm values."
  type        = bool
  default     = false
}

variable "enable_external_dns" {
  description = "Whether to install ExternalDNS"
  type        = bool
  default     = false
}

variable "external_dns_version" {
  description = "Helm chart version for ExternalDNS"
  type        = string
  default     = "1.14.3"
}

variable "route53_zone_ids" {
  description = "List of Route53 hosted zone IDs for ExternalDNS to manage"
  type        = list(string)
  default     = []
}

variable "enable_cert_manager" {
  description = "Whether to install cert-manager"
  type        = bool
  default     = false
}

variable "cert_manager_version" {
  description = "Helm chart version for cert-manager"
  type        = string
  default     = "1.13.3"
}

variable "tags" {
  description = "Additional tags to apply to all add-on resources"
  type        = map(string)
  default     = {}
}
