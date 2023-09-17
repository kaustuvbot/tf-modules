# ADR-002: Module Structure Convention

**Date:** 2023-11-01
**Status:** Accepted

## Context

As the module library grew, we needed a consistent convention for how modules
are structured internally and how they expose their interface to callers.

Options considered:
1. One module per cloud service (fine-grained)
2. One module per logical platform concern (coarse-grained)
3. Layered modules with composition at blueprint level

## Decision

**One module per cloud service**, organized by cloud:
```
modules/
  aws/vpc/
  aws/eks/
  aws/eks-addons/
  azure/vnet/
  azure/aks/
  gcp/vpc/        (planned)
```

Each module exposes:
- `variables.tf` — all inputs with descriptions and validations
- `outputs.tf` — all outputs with descriptions
- `main.tf` — primary resources
- `locals.tf` — computed values (if complex enough to warrant it)
- `data.tf` — data sources (if needed)
- `versions.tf` — provider requirements

## Consequences

**Positive:**
- Easy to find: one concern = one directory
- Composable: callers combine modules for their stack
- Testable: each module has isolated Terratest coverage
- Discoverable: consistent file layout across all modules

**Negative:**
- Callers must wire multiple modules together (solved by platform-blueprint)
- Cross-module outputs must be passed explicitly (verbose but intentional)
