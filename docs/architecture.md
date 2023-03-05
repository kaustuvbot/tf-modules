# Architecture Overview

## Platform Design

This platform follows a layered module architecture:

```
┌─────────────────────────────────┐
│        Environments             │
│    (dev / staging / prod)       │
├─────────────────────────────────┤
│      Cloud Modules              │
│  (aws/vpc, azure/vnet, etc.)    │
├─────────────────────────────────┤
│       Core Modules              │
│   (naming, tagging/labels)      │
└─────────────────────────────────┘
```

### Layers

**Core modules** are cloud-agnostic and provide:
- Consistent naming conventions
- Unified tagging/labels interface
- Shared variable patterns

**Cloud modules** implement provider-specific resources:
- Each module is self-contained with its own variables, outputs, and documentation
- Modules consume core modules for naming and tagging consistency
- Designed for composition, not monolithic stacks

**Environments** compose cloud modules into deployable configurations:
- Separate state per environment
- Environment-specific variable overrides via tfvars
- Common structure across dev, staging, and production

## State Management

- Remote state stored in S3 with DynamoDB locking
- State key pattern: `<environment>/<component>/terraform.tfstate`
- Bootstrap configuration provided for initial setup

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Module structure | Flat per-cloud | Simpler to navigate than deeply nested |
| State backend | S3 + DynamoDB | Industry standard, cost-effective |
| Naming | Module-based | Consistent, testable, reusable |
| Tagging | Core module | Single source of truth for all tags |
