variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "alert_email" {
  description = "Email address for Azure Monitor alert notifications"
  type        = string
  default     = null
}

variable "tags" {
  description = "Extra tags"
  type        = map(string)
  default     = {}
}
