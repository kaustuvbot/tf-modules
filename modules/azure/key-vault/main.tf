# -----------------------------------------------------------------------------
# Azure Key Vault
# -----------------------------------------------------------------------------
# Provisions a Key Vault with soft-delete and purge protection enabled by
# default. Access policies are managed externally to avoid configuration drift.
# Naming convention: kv-{project}-{environment}
# Note: Key Vault names must be globally unique, 3–24 chars.
# -----------------------------------------------------------------------------

locals {
  # Truncate to 24 chars; kv- prefix = 3 chars, leaving 21 for project+env
  name = substr("kv-${var.project}-${var.environment}", 0, 24)

  default_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_key_vault" "this" {
  name                      = local.name
  location                  = var.location
  resource_group_name       = var.resource_group_name
  tenant_id                 = var.tenant_id
  sku_name                  = var.sku_name
  soft_delete_retention_days = var.soft_delete_retention_days
  purge_protection_enabled  = var.purge_protection_enabled

  # Require RBAC authorisation; access policies managed via role assignments
  enable_rbac_authorization = true

  network_acls {
    bypass                     = var.network_acls_bypass
    default_action             = var.network_acls_default_action
    ip_rules                   = var.network_acls_ip_rules
    virtual_network_subnet_ids = var.network_acls_subnet_ids
  }

  tags = local.tags
}
