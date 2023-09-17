variable "project" {
  description = "Project name for tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "enable_s3_logs" {
  description = "Enable S3 data event protection in GuardDuty"
  type        = bool
  default     = false
}

variable "enable_kubernetes_logs" {
  description = "Enable EKS audit log analysis in GuardDuty"
  type        = bool
  default     = true
}

variable "enable_malware_protection" {
  description = "Enable GuardDuty Malware Protection for EC2 and EBS"
  type        = bool
  default     = false
}

variable "findings_s3_bucket_arn" {
  description = "ARN of S3 bucket to export GuardDuty findings. null disables export."
  type        = string
  default     = null
}

variable "findings_s3_kms_key_arn" {
  description = "KMS key ARN for encrypting exported findings. Required when findings_s3_bucket_arn is set."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to GuardDuty resources"
  type        = map(string)
  default     = {}
}
