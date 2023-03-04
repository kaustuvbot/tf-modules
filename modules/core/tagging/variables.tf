variable "project" {
  description = "Project name for tagging"
  type        = string
}

variable "environment" {
  description = "Environment name for tagging (e.g., dev, staging, prod)"
  type        = string
}

variable "extra_tags" {
  description = "Additional tags to merge with defaults"
  type        = map(string)
  default     = {}
}
