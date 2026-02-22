variable "project" {
  description = "GCP project ID"
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
  description = "GCP region for key ring"
  type        = string
  default     = "global"
}

variable "rotation_period" {
  description = "Rotation period for key versions (e.g., 7776000s = 90 days)"
  type        = string
  default     = "7776000s"
}

variable "key_algorithm" {
  description = "Key algorithm (GOOGLE_SYMMETRIC_ENCRYPTION, RSA_OAEP_3072_SHA256, etc.)"
  type        = string
  default     = "GOOGLE_SYMMETRIC_ENCRYPTION"
}

variable "protection_level" {
  description = "Protection level (SOFTWARE, HSM)"
  type        = string
  default     = "SOFTWARE"
}

variable "key_admin_service_accounts" {
  description = "Service accounts to grant cryptoKeyEncrypterDecrypter role"
  type        = list(string)
  default     = []
}

variable "key_viewer_service_accounts" {
  description = "Service accounts to grant cloudkms.viewer role"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Additional labels"
  type        = map(string)
  default     = {}
}
