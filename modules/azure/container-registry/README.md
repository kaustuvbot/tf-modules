# Azure Container Registry Module

Creates an Azure Container Registry (ACR) with RBAC-only access (`admin_enabled = false`).

## Naming Convention

ACR names must be globally unique, alphanumeric only, and 5–50 characters.
The module derives the name from `<project><environment>` with hyphens removed:

```
project = "myapp", environment = "prod"  →  name = "myappprod"
```

## Usage

```hcl
module "acr" {
  source = "../../modules/azure/container-registry"

  project             = "myapp"
  environment         = "prod"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus"
  sku                 = "Standard"
}

# Grant AKS kubelet identity pull access to the registry
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = module.acr.registry_id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity_object_id
}
```

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project` | `string` | — | Project name (2-24 lowercase alphanumeric/hyphens) |
| `environment` | `string` | — | Environment: dev, staging, prod |
| `resource_group_name` | `string` | — | Resource group for the registry |
| `location` | `string` | — | Azure region |
| `sku` | `string` | `"Standard"` | Registry tier: Basic, Standard, Premium |
| `public_network_access_enabled` | `bool` | `true` | Allow public network access |
| `zone_redundancy_enabled` | `bool` | `false` | Zone redundancy (Premium only) |
| `georeplications` | `list(object)` | `[]` | Geo-replication regions (Premium only) |
| `tags` | `map(string)` | `{}` | Additional tags |

## Outputs

| Name | Description |
|------|-------------|
| `registry_id` | Resource ID of the registry |
| `registry_name` | Registry name (alphanumeric) |
| `login_server` | Login server URL, e.g. `myappprod.azurecr.io` |
| `resource_group_name` | Resource group containing the registry |

## SKU Comparison

| SKU | Storage | Throughput | Features |
|-----|---------|------------|----------|
| Basic | 10 GB | Low | Dev/test only |
| Standard | 100 GB | Medium | Production default |
| Premium | 500 GB | High | Geo-replication, private endpoints, zone redundancy |

## RBAC Patterns

ACR uses Azure RBAC for access control (`admin_enabled = false`).
Assign roles at the registry scope:

```hcl
# AKS node pool pull access (via kubelet managed identity)
resource "azurerm_role_assignment" "aks_pull" {
  scope                = module.acr.registry_id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity_object_id
}

# CI/CD pipeline push access (via service principal or managed identity)
resource "azurerm_role_assignment" "ci_push" {
  scope                = module.acr.registry_id
  role_definition_name = "AcrPush"
  principal_id         = var.ci_principal_id
}
```

## Geo-Replication (Premium only)

```hcl
module "acr" {
  source      = "../../modules/azure/container-registry"
  project     = "myapp"
  environment = "prod"
  sku         = "Premium"

  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus"

  georeplications = [
    { location = "westus2",       zone_redundancy_enabled = true  },
    { location = "westeurope",    zone_redundancy_enabled = false },
  ]
}
```

## Private Endpoint (Production Hardening)

For `public_network_access_enabled = false`, create a private endpoint and
private DNS zone outside this module:

```hcl
module "acr" {
  # ...
  public_network_access_enabled = false
}

resource "azurerm_private_endpoint" "acr" {
  name                = "acr-pe"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "acr-psc"
    private_connection_resource_id = module.acr.registry_id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }
}
```
