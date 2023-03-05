variable "project" {
  description = "Project name used for state bucket and lock table naming"
  type        = string
}

variable "region" {
  description = "AWS region for the state backend resources"
  type        = string
  default     = "us-east-1"
}
