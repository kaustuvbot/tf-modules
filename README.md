# tf-modules

![Terraform Validate](https://github.com/YOUR_ORG/tf-modules/actions/workflows/terraform-validate.yml/badge.svg)
![Terraform Plan](https://github.com/YOUR_ORG/tf-modules/actions/workflows/terraform-plan.yml/badge.svg)

Production-grade Terraform modules for multi-cloud infrastructure.

## Vision

A modular, reusable Terraform platform that provides consistent infrastructure patterns across cloud providers. The goal is to enable rapid, secure, and repeatable deployments for production workloads.

## Module Inventory

### AWS

| Module | Description | Docs |
|--------|-------------|------|
| `modules/aws/vpc` | VPC with public/private subnets, NAT gateway, IGW | — |
| `modules/aws/iam` | GitHub OIDC provider, CI plan/apply roles | — |
| `modules/aws/s3-state` | S3 bucket for Terraform remote state | — |
| `modules/aws/dynamodb-lock` | DynamoDB table for state locking | — |
| `modules/aws/kms` | KMS keys for logs, state, and general use | — |
| `modules/aws/logging` | CloudTrail, AWS Config, S3 log archive | — |
| `modules/aws/eks` | EKS cluster with managed node groups, IRSA, OIDC | — |
| `modules/aws/eks-addons` | ALB controller, ExternalDNS, cert-manager, Prometheus, Loki | — |
| `modules/aws/monitoring` | CloudWatch alarms, SNS, composite alerts | — |
| `modules/aws/budgets` | Cost budgets and anomaly detection | — |

### Azure

| Module | Description | Docs |
|--------|-------------|------|
| `modules/azure/resource-group` | Resource group with standard naming | — |
| `modules/azure/vnet` | VNet with per-subnet NSGs | [azure-networking.md](docs/azure-networking.md) |
| `modules/azure/aks` | AKS cluster with autoscaling, workload identity, user pools | [azure-aks.md](docs/azure-aks.md) |
| `modules/azure/key-vault` | Key Vault with RBAC and purge protection | [azure-security-monitoring.md](docs/azure-security-monitoring.md) |
| `modules/azure/monitoring` | Azure Monitor metric alerts for AKS | [azure-security-monitoring.md](docs/azure-security-monitoring.md) |

## Examples

| Example | Description |
|---------|-------------|
| `examples/aws-complete` | Full AWS stack: VPC → EKS → add-ons → monitoring |
| `examples/azure-complete` | Full Azure stack: RG → VNet → AKS → KV → alerts |

## Design Principles

- **Consistency**: Common `project`/`environment` variable contract and tag standards across all clouds
- **Security by default**: Encryption enabled, least-privilege IAM, private networking where possible
- **Environment parity**: Same module interfaces for dev, staging, and production
- **Progressive complexity**: Start simple, add features incrementally
- **Documentation-first**: Every module includes usage examples and variable documentation

## Project Structure

```
tf-modules/
├── modules/
│   ├── aws/              # AWS modules (VPC, IAM, EKS, ...)
│   └── azure/            # Azure modules (VNet, AKS, ...)
├── examples/
│   ├── aws-complete/     # Full AWS composition example
│   └── azure-complete/   # Full Azure composition example
├── docs/                 # Architecture and design guides
├── policy/               # OPA/Conftest tag enforcement policies
├── tests/
│   ├── aws/              # Terratest for AWS modules
│   └── azure/            # Terratest for Azure modules
└── .github/workflows/    # CI: validate, plan, apply
```

## CI/CD

- **Validate**: `terraform fmt`, `terraform validate`, tfsec, checkov, OPA tag policy
- **Plan**: Per-environment matrix plan with PR comment output
- **Apply**: Sequential apply on merge to `main` with GitHub environment gates

See [docs/](docs/) for full architecture and usage guides.

## License

Apache 2.0 - see [LICENSE](LICENSE) for details.
