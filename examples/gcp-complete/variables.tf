variable "project_id" {
  description = "GCP project ID"
  type       = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default    = "prod"
}

variable "region" {
  description = "GCP region"
  type       = string
  default    = "us-central1"
}
