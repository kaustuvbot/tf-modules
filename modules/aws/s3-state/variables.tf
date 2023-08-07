variable "bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
}

variable "force_destroy" {
  description = "Allow destroying the bucket even if it contains objects (use for dev only)"
  type        = bool
  default     = false
}

variable "access_log_bucket" {
  description = "Name of an existing S3 bucket to deliver access logs to. Set to null to disable access logging."
  type        = string
  default     = null
}

variable "access_log_prefix" {
  description = "Prefix for access log objects in the target bucket"
  type        = string
  default     = "s3-access-logs/"
}

variable "tags" {
  description = "Tags to apply to the S3 bucket"
  type        = map(string)
  default     = {}
}
