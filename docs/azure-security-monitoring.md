# Azure Security and Monitoring

## Overview

Security and observability for Azure workloads is covered by three modules:

| Module | Purpose |
|--------|---------|
| `modules/azure/key-vault` | Secret storage with RBAC and purge protection |
| `modules/azure/aks` (monitoring.tf) | AKS control-plane logs → Log Analytics |
| `modules/azure/monitoring` | Azure Monitor metric alerts for AKS |

---

## Key Vault

### Design

- **RBAC authorisation**: Access is granted via Azure role assignments, not legacy access policies. This simplifies audit and integrates with Entra ID PIM.
- **Purge protection**: Enabled by default; prevents permanent deletion until the soft-delete retention period expires. Recommended for production.
- **Globally unique names**: The module truncates the `kv-{project}-{env}` name to 24 characters.

### Usage

```hcl
module "kv" {
  source              = "../../modules/azure/key-vault"
  project             = "myapp"
  environment         = "prod"
  resource_group_name = module.rg.name
  location            = module.rg.location
  tenant_id           = var.azure_tenant_id
}
```

---

## AKS Diagnostic Logs

Control-plane logs are streamed to a Log Analytics Workspace when `log_analytics_workspace_id` is provided:

```hcl
module "aks" {
  # ...
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
}
```

Categories enabled: `kube-apiserver`, `kube-controller-manager`, `kube-scheduler`, `kube-audit-admin`, `guard`.

---

## Azure Monitor Alerts

### Usage

```hcl
module "aks_alerts" {
  source              = "../../modules/azure/monitoring"
  project             = "myapp"
  environment         = "prod"
  resource_group_name = module.rg.name
  location            = module.rg.location
  aks_cluster_id      = module.aks.cluster_id
  action_group_email  = "ops@example.com"

  cpu_threshold_percent    = 80
  memory_threshold_percent = 80
}
```

### Alerts

| Alert | Metric | Default threshold |
|-------|--------|------------------|
| CPU | `node_cpu_usage_percentage` | > 80% |
| Memory | `node_memory_working_set_percentage` | > 80% |

Action group is only created when `action_group_email` is set, keeping the module safe for environments without notification requirements.
