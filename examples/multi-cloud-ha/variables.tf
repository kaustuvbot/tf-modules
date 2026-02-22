variable "project" {
  description = "Project name for AWS resources"
  type       = string
}

variable "domain" {
  description = "Domain for DNS records"
  type       = string
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID"
  type       = string
}

variable "gcp_project_id" {
  description = "GCP project ID"
  type       = string
}
