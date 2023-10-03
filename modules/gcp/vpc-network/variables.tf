variable "project" {
  description = "Project ID for GCP resources"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "routing_mode" {
  description = "Regional or global routing mode"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "routing_mode must be REGIONAL or GLOBAL."
  }
}

variable "mtu" {
  description = "MTU for the VPC network"
  type        = number
  default     = 1460
}

variable "subnets" {
  description = "Map of subnet name to subnet configuration"
  type = map(object({
    region                   = string
    ip_cidr_range            = string
    private_ip_google_access = optional(bool, false)
    secondary_ranges         = optional(map(string), null)
  }))
  default = {}
}

variable "labels" {
  description = "Additional labels"
  type        = map(string)
  default     = {}
}

variable "enable_cloud_nat" {
  description = "Enable Cloud NAT for private subnet egress"
  type        = bool
  default     = false
}

variable "nat_region" {
  description = "Region for Cloud NAT"
  type        = string
  default     = "us-central1"
}

variable "nat_ip_allocate_option" {
  description = "NAT IP allocation: AUTO_ONLY or MANUAL_ONLY"
  type        = string
  default     = "AUTO_ONLY"
}

variable "nat_ips" {
  description = "List of NAT IPs (required when MANUAL_ONLY)"
  type        = list(string)
  default     = []
}

variable "nat_source_subnets" {
  description = "Subnets to NAT: ALL_SUBNETWORKS_ALL_IP_RANGES or LIST_OF_SUBNETWORKS"
  type        = string
  default     = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

variable "enable_nat_logging" {
  description = "Enable NAT logging for debugging"
  type        = bool
  default     = false
}

variable "bgp_asn" {
  description = "BGP AS number for Cloud Router"
  type        = number
  default     = 64514
}

variable "enable_private_service_access" {
  description = "Enable Private Service Access for managed services (Cloud SQL, GKE, etc.)"
  type        = bool
  default     = false
}
