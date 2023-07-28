# Platform Conventions

## Variable Contract

All modules in this library share a common variable contract. Consistent naming makes root modules predictable regardless of the target cloud.

### Required Variables (all modules)

| Variable | Type | Allowed values | Description |
|----------|------|----------------|-------------|
| `project` | string | `^[a-z0-9-]{2,24}$` | Short identifier for the workload |
| `environment` | string | `dev`, `staging`, `prod` | Deployment environment |

### Optional Common Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `tags` | `map(string)` | `{}` | Extra tags merged with module defaults |

### Cloud-Specific Variables

| Variable | Cloud | Description |
|----------|-------|-------------|
| `region` | AWS | AWS region (e.g. `us-east-1`) |
| `location` | Azure | Azure region (e.g. `eastus`) |
| `resource_group_name` | Azure | Target resource group (passed in, not created) |

---

## Tagging Standard

Every resource created by a module in this library receives these tags automatically:

| Tag | Value | Description |
|-----|-------|-------------|
| `Project` | `var.project` | Workload identifier |
| `Environment` | `var.environment` | Deployment environment |
| `ManagedBy` | `terraform` | Provenance marker |

Additional tags from `var.tags` are merged on top. Callers must not re-define the three mandatory tags; the module's defaults take precedence.

---

## Naming Patterns

### AWS

| Resource type | Pattern |
|--------------|---------|
| VPC | `{project}-{environment}` |
| EKS cluster | `{project}-{environment}` |
| IAM roles | `{project}-{environment}-{role-suffix}` |
| S3 buckets | `{project}-{environment}-{purpose}-{account-id}` |

### Azure

| Resource type | Pattern |
|--------------|---------|
| Resource Group | `rg-{project}-{environment}` |
| VNet | `vnet-{project}-{environment}` |
| Subnet | `snet-{name}-{environment}` |
| NSG | `nsg-{name}-{environment}` |
| AKS | `aks-{project}-{environment}` |
| Key Vault | `kv-{project}-{environment}` (max 24 chars) |
| Alert | `alert-{resource}-{metric}-{project}-{environment}` |

---

## Composition Pattern

Modules are designed to be composed at the root module level:

```hcl
# environments/prod/main.tf

module "rg" { ... }          # Azure: resource group
module "vnet" { ... }        # Azure: networking
module "aks" { ... }         # Azure: cluster
module "kv" { ... }          # Azure: secrets

# or for AWS:
module "vpc" { ... }
module "eks" { ... }
module "eks_addons" { ... }
```

Avoid cross-module dependencies by passing IDs as inputs (outputs chaining), not by referencing module internals.
