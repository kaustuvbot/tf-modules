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

variable "tags" {
  description = "Tags to apply to the DynamoDB table"
  type        = map(string)
  default     = {}
}
