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
  description = "URL of the EKS OIDC provider, including the https:// scheme. Passed as-is to IRSA trust policies."
  type        = string

  validation {
    condition     = startswith(var.oidc_provider_url, "https://")
    error_message = "oidc_provider_url must include the https:// scheme, e.g. \"https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE\"."
  }
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
  description = "List of Route53 hosted zone IDs for ExternalDNS to manage. Each ID must start with 'Z' (the standard AWS hosted zone ID prefix)."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for id in var.route53_zone_ids :
      startswith(id, "Z") && length(id) >= 14
    ])
    error_message = "Each route53_zone_ids entry must be a valid Route53 hosted zone ID starting with 'Z' and at least 14 characters long."
  }
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

variable "enable_node_termination_handler" {
  description = "Install the AWS Node Termination Handler (NTH) to gracefully drain SPOT nodes before reclamation. Enable when any node group uses capacity_type = SPOT."
  type        = bool
  default     = false
}

variable "node_termination_handler_version" {
  description = "Helm chart version for AWS Node Termination Handler"
  type        = string
  default     = "0.21.0"
}

variable "enable_sealed_secrets" {
  description = "Install the Bitnami Sealed Secrets controller, enabling GitOps-safe encrypted secret management. SealedSecret resources are encrypted with the controller's key and safe to commit to version control."
  type        = bool
  default     = false
}

variable "sealed_secrets_version" {
  description = "Helm chart version for Sealed Secrets controller"
  type        = string
  default     = "2.15.0"
}

variable "enable_karpenter" {
  description = "Install Karpenter node autoscaler. When enabled, creates an IRSA role with EC2/SQS/SSM permissions and an SQS queue for SPOT interruption handling. Mutually exclusive with enable_cluster_autoscaler_irsa on the EKS module."
  type        = bool
  default     = false
}

variable "karpenter_version" {
  description = "Helm chart version for Karpenter"
  type        = string
  default     = "0.37.0"
}

variable "karpenter_namespace" {
  description = "Kubernetes namespace to install Karpenter into"
  type        = string
  default     = "kube-system"
}

variable "tags" {
  description = "Additional tags to apply to all add-on resources"
  type        = map(string)
  default     = {}
}
