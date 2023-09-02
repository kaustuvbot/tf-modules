variable "table_name" {
  description = "Name of the DynamoDB table for Terraform state locking"
  type        = string
}

variable "enable_ttl" {
  description = "Enable TTL on lock entries to auto-expire stale locks"
  type        = bool
  default     = false
}

variable "ttl_attribute" {
  description = "Name of the TTL attribute (only used when enable_ttl is true)"
  type        = string
  default     = "ExpiresAt"
}

variable "enable_delete_protection" {
  description = "Protect the lock table from accidental deletion. Recommended true in prod."
  type        = bool
  default     = false
}

variable "table_class" {
  description = "DynamoDB table class. STANDARD or STANDARD_INFREQUENT_ACCESS (lower cost for infrequently accessed data)."
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "STANDARD_INFREQUENT_ACCESS"], var.table_class)
    error_message = "table_class must be STANDARD or STANDARD_INFREQUENT_ACCESS."
  }
}

variable "tags" {
  description = "Tags to apply to the DynamoDB table"
  type        = map(string)
  default     = {}
}
