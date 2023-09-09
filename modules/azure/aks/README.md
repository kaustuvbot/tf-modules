# Azure AKS Module

Manages an Azure Kubernetes Service (AKS) cluster with a system node pool,
optional user node pools, workload identity, network policy, and security
hardening controls including Microsoft Defender for Containers.

## Usage

```hcl
module "aks" {
  source = "../../modules/azure/aks"

  project             = "myapp"
  environment         = "prod"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  kubernetes_version  = "1.28"

  system_node_pool_subnet_id  = module.vnet.subnet_ids["system"]
  private_cluster_enabled     = true
  workload_identity_enabled   = true
  network_policy              = "calico"
  azure_policy_enabled        = true

  enable_defender            = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  maintenance_window = {
    day   = "Sunday"
    hours = [2, 3, 4]
  }

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
| `system_node_pool_subnet_id` | `string` | Subnet ID for the system node pool |

### Optional

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `kubernetes_version` | `string` | `null` | Kubernetes version (null = latest) |
| `private_cluster_enabled` | `bool` | `false` | Deploy API server as private endpoint (required in prod) |
| `authorized_ip_ranges` | `list(string)` | `[]` | CIDR ranges for public API access (ignored when private) |
| `workload_identity_enabled` | `bool` | `false` | Enable OIDC issuer and Workload Identity |
| `azure_policy_enabled` | `bool` | `false` | Enable Azure Policy add-on (OPA Gatekeeper) |
| `network_policy` | `string` | `"calico"` | Network policy engine: `calico`, `azure`, or `none` |
| `enable_defender` | `bool` | `false` | Enable Microsoft Defender for Containers |
| `log_analytics_workspace_id` | `string` | `null` | Log Analytics workspace ID (required when `enable_defender=true`) |
| `auto_upgrade_channel` | `string` | `"patch"` | Automatic upgrade channel: `none`, `patch`, `stable`, `rapid`, `node-image` |
| `maintenance_window` | `object` | `null` | Allowed maintenance window (`{ day, hours }`) |
| `system_node_pool_vm_size` | `string` | `"Standard_D2s_v3"` | VM size for system node pool |
| `system_node_pool_node_count` | `number` | `2` | Initial node count |
| `system_node_pool_min_count` | `number` | `1` | Minimum nodes when autoscaling |
| `system_node_pool_max_count` | `number` | `3` | Maximum nodes when autoscaling |
| `user_node_pools` | `map(object)` | `{}` | Map of user node pool name to configuration |
| `tags` | `map(string)` | `{}` | Additional tags |

### user_node_pools object shape

```hcl
user_node_pools = {
  "apps" = {
    vm_size     = "Standard_D4s_v3"
    subnet_id   = module.vnet.subnet_ids["apps"]
    node_count  = 2
    min_count   = 1
    max_count   = 10
    node_labels = { "workload" = "apps" }
    node_taints = ["dedicated=apps:NoSchedule"]
  }
}
```

## Outputs

| Name | Description |
|------|-------------|
| `cluster_id` | Resource ID of the AKS cluster |
| `cluster_name` | Name of the AKS cluster |
| `kube_config` | Raw kubeconfig (sensitive) |
| `host` | Kubernetes API server hostname (sensitive) |
| `kubelet_identity_object_id` | Kubelet managed identity object ID (for ACR pull assignments) |
| `oidc_issuer_url` | OIDC issuer URL for Workload Identity (null when disabled) |
| `user_node_pool_ids` | Map of user node pool name to resource ID |

## Security Notes

- `private_cluster_enabled` is **enforced as required** in `prod` environments via input validation.
- `network_policy = "calico"` enables pod-level traffic enforcement by default.
- `enable_defender` attaches Microsoft Defender for Containers, which provides runtime threat detection and vulnerability scanning. Requires a Log Analytics workspace.
- `azure_policy_enabled` enables OPA Gatekeeper for policy-as-code admission control.
- `workload_identity_enabled` enables the OIDC issuer required for federated pod credentials — preferred over node-level managed identity for workloads.

## Phase 4 Security Hardening Checklist

| Control | Variable | Recommended (prod) |
|---------|----------|--------------------|
| Private API server | `private_cluster_enabled` | `true` |
| Pod network policy | `network_policy` | `"calico"` or `"azure"` |
| Defender for Containers | `enable_defender` | `true` |
| Azure Policy | `azure_policy_enabled` | `true` |
| Workload Identity | `workload_identity_enabled` | `true` |
| Auto upgrade | `auto_upgrade_channel` | `"patch"` |
