# Azure Resource Group Module

Creates an Azure Resource Group with consistent naming and tagging. This is
typically the first module deployed and its outputs are passed to all other
Azure modules in the same environment.

## Naming Convention

Resource groups are named: `rg-<project>-<environment>`

## Usage

```hcl
module "rg" {
  source = "../../modules/azure/resource-group"

  project     = "myapp"
  environment = "prod"
  location    = "eastus"

  tags = {
    Team       = "platform"
    CostCenter = "infra-001"
  }
}

# Pass outputs to other modules
module "vnet" {
  source = "../../modules/azure/vnet"

  resource_group_name = module.rg.name
  location            = module.rg.location
  # ...
}
```

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project` | `string` | — | Project name (2–24 lowercase alphanumeric or hyphens) |
| `environment` | `string` | — | Environment: `dev`, `staging`, or `prod` |
| `location` | `string` | `"eastus"` | Azure region for the resource group |
| `tags` | `map(string)` | `{}` | Additional tags merged with defaults |

## Outputs

| Name | Description |
|------|-------------|
| `name` | Name of the resource group (`rg-<project>-<environment>`) |
| `location` | Azure region of the resource group |
| `id` | Resource ID of the resource group |

## Notes

- Resource group names must be globally unique within a subscription.
- Tags applied here are inherited by most resources created within the group
  (when using Azure Policy inheritance), but modules explicitly set their own
  tags using the `tags` variable.
- The resource group is the primary cost boundary — ensure `CostCenter` or
  equivalent tags are set to enable cost allocation reporting.
