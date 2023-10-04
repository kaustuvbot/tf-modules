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

variable "location" {
  description = "GCP region or zone"
  type        = string
  default     = "us-central1"
}

variable "network_id" {
  description = "VPC network ID (projects/{project}/global/networks/{name})"
  type        = string
}

variable "subnetwork_id" {
  description = "Subnet ID (projects/{project}/regions/{region}/subnetworks/{name})"
  type        = string
}

variable "initial_node_count" {
  description = "Initial number of nodes in the default node pool"
  type        = number
  default     = 1
}

variable "enable_shielded_nodes" {
  description = "Enable Shielded Nodes for GKE security hardening"
  type        = bool
  default     = true
}

variable "enable_private_nodes" {
  description = "Enable private nodes (no public IPs for nodes)"
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for the control plane"
  type        = bool
  default     = true
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for GKE master"
  type        = string
  default     = "172.16.0.0/28"
}

variable "master_authorized_networks_enabled" {
  description = "Enable master authorized networks"
  type        = bool
  default     = false
}

variable "enable_network_policy" {
  description = "Enable Network Policy enforcement"
  type        = bool
  default     = true
}

variable "enable_binary_authorization" {
  description = "Enable Binary Authorization"
  type        = bool
  default     = false
}

variable "enable_database_encryption" {
  description = "Enable Customer-Managed Encryption Keys for etcd"
  type        = bool
  default     = false
}

variable "database_encryption_key" {
  description = "KMS key URI for etcd encryption"
  type        = string
  default     = ""
}

variable "enable_kubernetes_alpha" {
  description = "Enable Kubernetes Alpha features"
  type        = bool
  default     = false
}

variable "workload_identity_enabled" {
  description = "Enable Workload Identity for GCP service account access"
  type        = bool
  default     = true
}

variable "node_pools" {
  description = "Map of node pool name to configuration"
  type = map(object({
    machine_type                = string
    node_count                  = number
    min_node_count              = optional(number, 1)
    max_node_count              = optional(number, 3)
    disk_type                   = optional(string, "pd-ssd")
    disk_size_gb                = optional(number, 100)
    service_account             = optional(string, null)
    preemptible                 = optional(bool, false)
    labels                      = optional(map(string), {})
    enable_secure_boot          = optional(bool, true)
    enable_integrity_monitoring = optional(bool, true)
    auto_repair                 = optional(bool, true)
    auto_upgrade                = optional(bool, true)
    max_surge                   = optional(number, null)
    max_unavailable             = optional(number, null)
  }))
  default = {}
}

variable "labels" {
  description = "Additional labels"
  type        = map(string)
  default     = {}
}
