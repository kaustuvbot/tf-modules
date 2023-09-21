# Core Tagging Module

Generates a consistent tag map for all resources in the platform. Provides
both the full merged tag set and the default-only tag set for contexts where
extra tags should not be inherited.

## Usage

```hcl
module "tags" {
  source = "../../modules/core/tagging"

  project     = "myapp"
  environment = "prod"
  extra_tags  = {
    Team       = "platform"
    CostCenter = "infra-001"
  }
}

resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
  tags       = module.tags.tags
}
```

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project` | `string` | — | Project name for tagging |
| `environment` | `string` | — | Environment name (dev, staging, prod) |
| `extra_tags` | `map(string)` | `{}` | Additional tags merged with defaults |

## Outputs

| Name | Description |
|------|-------------|
| `tags` | Full merged tag map (defaults + extra_tags) |
| `default_tags` | Default tags only, without extra_tags |

## Default Tags

Every resource tagged via this module receives:

```hcl
{
  Project     = var.project
  Environment = var.environment
  ManagedBy   = "terraform"
}
```

## Relationship to core/naming

The `core/naming` module also produces a `tags` output using the same
`Project`, `Environment`, and `ManagedBy` keys. Use `core/naming` when you
also need the generated resource name. Use `core/tagging` when you only need
tags without a naming context (e.g., tagging shared infrastructure resources).

## Tag Governance

Required tags enforced by the OPA policy at `policy/required_tags.rego`:
- `Project`
- `Environment`
- `ManagedBy`

Resources missing these tags will cause the `conftest` CI check to fail.
