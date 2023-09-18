# Azure Key Vault Module

Manages an Azure Key Vault with configurable SKU, soft-delete retention,
purge protection, and network ACL controls. Designed for use with AKS
Workload Identity for pod-level secret access without node-level credentials.

## Usage

```hcl
module "key_vault" {
  source = "../../modules/azure/key-vault"

  project             = "myapp"
  environment         = "prod"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name                   = "standard"
  soft_delete_retention_days = 90
  purge_protection_enabled   = true

  # Restrict network access to specific subnets
  network_acls_default_action = "Deny"
  network_acls_bypass         = "AzureServices"
  network_acls_subnet_ids     = [module.vnet.subnet_ids["aks-apps"]]

  tags = {
    Team = "platform"
  }
}
```

## Variables

### Required

| Name | Type | Description |
|------|------|-------------|
| `project` | `string` | Project name (2–24 lowercase alphanumeric or hyphens) |
| `environment` | `string` | Environment: `dev`, `staging`, or `prod` |
| `resource_group_name` | `string` | Resource group to deploy into |
| `location` | `string` | Azure region |
| `tenant_id` | `string` | Azure tenant ID (required for access policies) |

### Optional

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `sku_name` | `string` | `"standard"` | SKU: `standard` or `premium` (required for HSM-backed keys) |
| `soft_delete_retention_days` | `number` | `30` | Days to retain soft-deleted objects (7–90) |
| `purge_protection_enabled` | `bool` | `true` | Prevent permanent deletion before retention period expires |
| `network_acls_default_action` | `string` | `"Allow"` | Default network ACL action: `Allow` or `Deny` |
| `network_acls_bypass` | `string` | `"AzureServices"` | Allow Azure services to bypass the ACL: `AzureServices` or `None` |
| `network_acls_ip_rules` | `list(string)` | `[]` | IP ranges allowed through the network ACL |
| `network_acls_subnet_ids` | `list(string)` | `[]` | Subnet IDs allowed through the network ACL |
| `tags` | `map(string)` | `{}` | Additional tags |

## Outputs

| Name | Description |
|------|-------------|
| `id` | Resource ID of the Key Vault |
| `name` | Name of the Key Vault |
| `vault_uri` | URI of the Key Vault for SDK access (e.g., `https://<name>.vault.azure.net/`) |

## Security Notes

### Purge Protection
`purge_protection_enabled = true` (the default) means that once a key, secret, or certificate is soft-deleted, it **cannot** be permanently destroyed until the `soft_delete_retention_days` window expires. This protects against accidental or malicious deletion but also means recovery operations require waiting out the retention period.

Set `purge_protection_enabled = false` only in dev environments where you need to quickly recreate the vault with the same name.

### Network ACLs
For production deployments, set `network_acls_default_action = "Deny"` and explicitly list allowed subnets in `network_acls_subnet_ids`. This prevents access from any IP not in the allow list.

```hcl
network_acls_default_action = "Deny"
network_acls_bypass         = "AzureServices"  # allows Backup, Event Grid, etc.
network_acls_subnet_ids     = [
  module.vnet.subnet_ids["aks-apps"],
]
```

### Integration with AKS Workload Identity

With AKS Workload Identity enabled (`workload_identity_enabled = true` in the AKS module), pods can access Key Vault secrets without node-level credentials:

1. Create a managed identity or use the AKS OIDC issuer for federated credentials
2. Assign `Key Vault Secrets User` role to the pod's identity on this Key Vault
3. Reference the vault URI (`module.key_vault.vault_uri`) in your application config

This approach is preferable to node-level identity because secret access is scoped to the individual workload, not the entire node pool.
