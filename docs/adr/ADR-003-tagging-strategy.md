# ADR-003: Mandatory Tagging Strategy

**Date:** 2023-11-01
**Status:** Accepted

## Context

Without consistent tagging, cost attribution, ownership, and automated policy
enforcement become impossible at scale. We needed to define which tags are
mandatory, how they are enforced, and how they map across clouds.

## Decision

**Mandatory tags on all resources:**

| Tag Key | Values | Purpose |
|---|---|---|
| `Project` | any string | Cost attribution per product |
| `Environment` | dev / staging / prod | Environment segregation |
| `ManagedBy` | terraform | Identifies IaC-managed resources |

All modules set these tags via a `local.default_tags` merge pattern:
```hcl
locals {
  default_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
  tags = merge(local.default_tags, var.tags)
}
```

On GCP, tags are implemented as **labels** using the same keys (lowercased).

**Enforcement:**
- OPA/Conftest policy in `policy/` validates mandatory tags on `terraform plan` output
- CI pipeline fails if mandatory tags are missing

## Consequences

**Positive:**
- Automated cost reports by Project and Environment
- Policy-as-code prevents untagged resources reaching production
- Consistent interface across AWS, Azure, GCP modules

**Negative:**
- GCP label keys must be lowercase — modules normalize automatically
- Tag propagation to child resources (e.g., EKS node groups) requires explicit passing
