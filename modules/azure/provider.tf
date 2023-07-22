# -----------------------------------------------------------------------------
# Azure Provider Configuration
# -----------------------------------------------------------------------------
# Baseline azurerm provider configuration. Consumers must configure the
# provider block in their root module with subscription_id and tenant_id.
#
# Recommended authentication order:
#   1. Azure CLI (local dev)
#   2. Workload Identity (AKS pods)
#   3. Service Principal with OIDC (GitHub Actions)
#   4. Managed Identity (Azure-hosted runners)
# -----------------------------------------------------------------------------

variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = null
}

variable "azure_tenant_id" {
  description = "Azure tenant ID"
  type        = string
  default     = null
}

variable "azure_location" {
  description = "Primary Azure region for resource deployment"
  type        = string
  default     = "eastus"
}
