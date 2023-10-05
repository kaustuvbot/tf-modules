# Azure Private DNS Module

Creates an Azure Private DNS Zone and optional VNet links. Required when
`private_cluster_enabled = true` on the AKS module — private AKS clusters
expose their API server on a private endpoint that only resolves through a
linked private DNS zone.

## Usage

### AKS Private Cluster

```hcl
module "aks" {
  source = "../../modules/azure/aks"
  # ...
  private_cluster_enabled = true
}

module "private_dns" {
  source = "../../modules/azure/private-dns"

  project             = "myapp"
  environment         = "prod"
  resource_group_name = azurerm_resource_group.main.name

  # Azure sets this zone automatically on private AKS clusters.
  # Find it with: az aks show --query privateFqdn
  zone_name = "privatelink.eastus.azmk8s.io"

  vnet_links = {
    hub-vnet  = module.hub_vnet.vnet_id
    spoke-vnet = module.spoke_vnet.vnet_id
  }
}
```

### General-purpose Private DNS

```hcl
module "db_dns" {
  source = "../../modules/azure/private-dns"

  project             = "myapp"
  environment         = "prod"
  resource_group_name = azurerm_resource_group.main.name
  zone_name           = "myapp.internal"

  vnet_links = {
    main-vnet = module.vnet.vnet_id
  }

  # Enable auto-registration for VM hostnames (non-AKS zones only)
  registration_enabled = true
}
```

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project` | `string` | — | Project name (2-24 lowercase alphanum/hyphens) |
| `environment` | `string` | — | Environment: dev, staging, prod |
| `resource_group_name` | `string` | — | Resource group for the DNS zone |
| `zone_name` | `string` | — | DNS zone name (e.g. `privatelink.eastus.azmk8s.io`) |
| `vnet_links` | `map(string)` | `{}` | Map of link name → VNet resource ID |
| `registration_enabled` | `bool` | `false` | Auto-register VM hostnames in zone (not for AKS) |
| `tags` | `map(string)` | `{}` | Additional tags |

## Outputs

| Name | Description |
|------|-------------|
| `zone_id` | Resource ID of the private DNS zone |
| `zone_name` | Name of the zone |
| `vnet_link_ids` | Map of link name → VNet link resource ID |

## AKS Private Cluster Zone Names

Private AKS cluster DNS zone names are region-specific:

| Region | Zone Name |
|--------|-----------|
| East US | `privatelink.eastus.azmk8s.io` |
| West US 2 | `privatelink.westus2.azmk8s.io` |
| West Europe | `privatelink.westeurope.azmk8s.io` |
| North Europe | `privatelink.northeurope.azmk8s.io` |
| UK South | `privatelink.uksouth.azmk8s.io` |

Find the exact zone for an existing private cluster:

```bash
az aks show \
  --resource-group <rg> \
  --name <cluster> \
  --query "privateFqdnZone" -o tsv
```

## Hub-and-Spoke Design

In hub-and-spoke topologies, the DNS zone is typically placed in the hub
resource group and linked to both the hub VNet and all spoke VNets:

```hcl
vnet_links = {
  hub   = module.hub_vnet.vnet_id
  spoke-eastus  = module.spoke_eastus.vnet_id
  spoke-westus2 = module.spoke_westus2.vnet_id
}
```

All linked VNets resolve hostnames in the zone without requiring custom DNS
forwarder configuration.
