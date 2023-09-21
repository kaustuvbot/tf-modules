# Core Naming Module

Generates consistent resource names and a standard tag map for use across all
cloud modules. This is a foundational module — every other module in the
repository should produce names that follow this convention.

## Naming Convention

```
<project>-<environment>[-<component>][-<suffix>]
```

Examples:
- `myapp-prod` (short_name)
- `myapp-prod-eks` (resource_name with component)
- `myapp-prod-eks-01` (resource_name with component and suffix)

## Usage

```hcl
module "naming" {
  source = "../../modules/core/naming"

  project     = "myapp"
  environment = "prod"
  component   = "eks"
  suffix      = "01"         # optional
  extra_tags  = {
    Team       = "platform"
    CostCenter = "infra"
  }
}

resource "aws_eks_cluster" "this" {
  name = module.naming.resource_name   # "myapp-prod-eks-01"
  tags = module.naming.tags
}
```

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project` | `string` | — | Project name prefix |
| `environment` | `string` | — | Environment (dev, staging, prod) |
| `component` | `string` | `""` | Component or service name (optional) |
| `suffix` | `string` | `""` | Additional suffix for disambiguation (optional) |
| `extra_tags` | `map(string)` | `{}` | Extra tags merged into the tags output |

## Outputs

| Name | Description |
|------|-------------|
| `resource_name` | Full name: `<project>-<environment>[-<component>][-<suffix>]` |
| `short_name` | Short name: `<project>-<environment>` (for constrained contexts) |
| `project` | Project name passed through |
| `environment` | Environment name passed through |
| `tags` | Standard tag map merged with `extra_tags` |

## Tag Output

The `tags` output always includes:

```hcl
{
  Project     = var.project
  Environment = var.environment
  ManagedBy   = "terraform"
  # ...plus any extra_tags
}
```

## Design Notes

- The `short_name` output is useful for resources with strict name length limits (e.g., Azure Key Vault names must be ≤24 characters).
- The `component` segment is optional and should identify the functional role (e.g., `eks`, `vpc`, `monitoring`).
- The `suffix` segment is useful for distinguishing multiple instances of the same component (e.g., `01`, `blue`, `primary`).
