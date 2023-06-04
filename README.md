# tf-modules

![Terraform Validate](https://github.com/YOUR_ORG/tf-modules/actions/workflows/terraform-validate.yml/badge.svg)
![Terraform Plan](https://github.com/YOUR_ORG/tf-modules/actions/workflows/terraform-plan.yml/badge.svg)

Production-grade Terraform modules for multi-cloud infrastructure.

## Vision

A modular, reusable Terraform platform that provides consistent infrastructure patterns across cloud providers. The goal is to enable rapid, secure, and repeatable deployments for production workloads.

## Supported Clouds

| Cloud | Status | Key Modules |
|-------|--------|-------------|
| AWS | In Progress | VPC, IAM/OIDC, EKS, logging, budgets |
| Azure | Planned | Resource Group, VNet, AKS, Key Vault, monitoring |
| GCP | Future | VPC, GKE, IAM, logging |

## Design Principles

- **Consistency**: Common naming, tagging, and output patterns across all clouds
- **Security by default**: Encryption enabled, least-privilege IAM, private networking where possible
- **Environment parity**: Same module interfaces for dev, staging, and production
- **Progressive complexity**: Start simple, add features incrementally
- **Documentation-first**: Every module includes usage examples and variable documentation

## Project Structure

```
tf-modules/
├── modules/          # Reusable Terraform modules
│   ├── core/         # Cloud-agnostic (naming, tagging)
│   ├── aws/          # AWS-specific modules
│   └── azure/        # Azure-specific modules
├── environments/     # Per-environment configurations
├── bootstrap/        # State backend bootstrapping
├── examples/         # Usage examples
├── docs/             # Architecture and design docs
├── scripts/          # Helper scripts (fmt, validate)
└── tests/            # Module tests
```

## Getting Started

> This project is under active development. Module documentation will be added as modules are implemented.

## License

Apache 2.0 - see [LICENSE](LICENSE) for details.
