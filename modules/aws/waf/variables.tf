variable "project" {
  description = "Project name for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "scope" {
  description = "WAF scope: REGIONAL (for ALB/API GW) or CLOUDFRONT (for CloudFront distributions)"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "scope must be REGIONAL or CLOUDFRONT."
  }
}

variable "enable_rate_limiting" {
  description = "Enable rate-based rule to limit requests per IP"
  type        = bool
  default     = true
}

variable "rate_limit_threshold" {
  description = "Maximum number of requests per 5-minute window per IP before blocking"
  type        = number
  default     = 2000
}

variable "enable_aws_managed_common_ruleset" {
  description = "Enable the AWS Managed Rules Common Rule Set (OWASP Top 10 baseline)"
  type        = bool
  default     = true
}

variable "enable_aws_managed_bad_inputs" {
  description = "Enable the AWS Managed Rules Known Bad Inputs Rule Set"
  type        = bool
  default     = true
}

variable "enable_aws_managed_sql_injection" {
  description = "Enable the AWS Managed Rules SQL Database Rule Set"
  type        = bool
  default     = false
}

variable "alb_arn_list" {
  description = "List of ALB ARNs to associate this Web ACL with. Empty list = no association."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to apply to WAF resources"
  type        = map(string)
  default     = {}
}
