# Azure Networking Modules

## Overview

The Azure networking layer consists of two composable modules:

- `modules/azure/resource-group` — resource group with standardised naming
- `modules/azure/vnet` — VNet with per-subnet NSGs

## Naming Convention

| Resource | Pattern |
|----------|---------|
| Resource Group | `rg-{project}-{environment}` |
| Virtual Network | `vnet-{project}-{environment}` |
| Subnet | `snet-{name}-{environment}` |
| NSG | `nsg-{name}-{environment}` |

## Usage

```hcl
module "rg" {
  source      = "../../modules/azure/resource-group"
  project     = "myapp"
  environment = "dev"
  location    = "eastus"
}

module "vnet" {
  source              = "../../modules/azure/vnet"
  project             = "myapp"
  environment         = "dev"
  resource_group_name = module.rg.name
  location            = module.rg.location
  address_space       = ["10.10.0.0/16"]

  subnets = {
    aks-system = {
      address_prefixes  = ["10.10.1.0/24"]
      service_endpoints = ["Microsoft.ContainerRegistry"]
    }
    aks-user = {
      address_prefixes = ["10.10.2.0/24"]
    }
  }
}
```

## Outputs

### resource-group

| Output | Description |
|--------|-------------|
| `name` | Resource group name |
| `location` | Azure region |
| `id` | Resource ID |

### vnet

| Output | Description |
|--------|-------------|
| `vnet_id` | VNet resource ID |
| `vnet_name` | VNet name |
| `address_space` | Assigned CIDR blocks |
| `subnet_ids` | Map of subnet name → ID |
| `nsg_ids` | Map of subnet name → NSG ID |

## Design Decisions

- **One NSG per subnet**: Provides granular security control and aligns with Azure best practices. NSG rules can be added externally via `azurerm_network_security_rule` resources.
- **Service endpoints**: Declared per-subnet to minimise blast radius if a subnet is compromised.
- **No default allow rules**: NSGs are created with no custom rules by default — platform-managed default rules apply. Callers add rules as needed.
