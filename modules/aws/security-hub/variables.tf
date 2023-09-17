variable "project" {
  description = "Project name for tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "enable_cis_standard" {
  description = "Enable the CIS AWS Foundations Benchmark security standard"
  type        = bool
  default     = true
}

variable "enable_aws_foundational_standard" {
  description = "Enable the AWS Foundational Security Best Practices standard"
  type        = bool
  default     = true
}

variable "enable_pci_dss_standard" {
  description = "Enable the PCI DSS security standard"
  type        = bool
  default     = false
}

variable "auto_enable_controls" {
  description = "Automatically enable new controls as they are added to enabled standards"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to Security Hub resources"
  type        = map(string)
  default     = {}
}
