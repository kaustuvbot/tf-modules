# Azure AKS Module

## Overview

The `modules/azure/aks` module provisions an Azure Kubernetes Service cluster with:

- System-assigned managed identity
- Azure CNI networking (pods get VNet IPs)
- Autoscaling system node pool
- Standard load balancer SKU

## Usage

```hcl
module "rg" {
  source      = "../../modules/azure/resource-group"
  project     = "myapp"
  environment = "prod"
  location    = "eastus"
}

module "vnet" {
  source              = "../../modules/azure/vnet"
  project             = "myapp"
  environment         = "prod"
  resource_group_name = module.rg.name
  location            = module.rg.location
  address_space       = ["10.20.0.0/16"]

  subnets = {
    aks-system = { address_prefixes = ["10.20.1.0/24"] }
    aks-user   = { address_prefixes = ["10.20.2.0/24"] }
  }
}

module "aks" {
  source              = "../../modules/azure/aks"
  project             = "myapp"
  environment         = "prod"
  resource_group_name = module.rg.name
  location            = module.rg.location

  system_node_pool_subnet_id  = module.vnet.subnet_ids["aks-system"]
  system_node_pool_vm_size    = "Standard_D4s_v3"
  system_node_pool_node_count = 2
  system_node_pool_min_count  = 2
  system_node_pool_max_count  = 5
}
```

## Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `project` | string | — | Project name |
| `environment` | string | — | Environment (dev/staging/prod) |
| `resource_group_name` | string | — | Target resource group |
| `location` | string | — | Azure region |
| `kubernetes_version` | string | `null` | Pin K8s version; `null` uses latest |
| `system_node_pool_subnet_id` | string | — | Subnet for system nodes |
| `system_node_pool_vm_size` | string | `Standard_D2s_v3` | VM size for system nodes |
| `system_node_pool_node_count` | number | `2` | Initial node count |
| `system_node_pool_min_count` | number | `1` | Autoscale minimum |
| `system_node_pool_max_count` | number | `3` | Autoscale maximum |

## Outputs

| Output | Description |
|--------|-------------|
| `cluster_id` | AKS resource ID |
| `cluster_name` | Cluster name |
| `kube_config` | Raw kubeconfig (sensitive) |
| `host` | API server URL (sensitive) |
| `kubelet_identity_object_id` | Kubelet identity for ACR assignments |

## Design Notes

- **System-assigned identity**: Simplest to manage; no pre-created service principal required.
- **Azure CNI**: Required for AKS features like network policies. Ensure subnets are sized to accommodate `max_count × max_pods_per_node` IPs.
- **Autoscaling max_surge = 33%**: Limits the number of additional nodes created during upgrades to minimise disruption.
