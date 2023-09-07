# tf-modules v1.0.0

![Terraform Validate](https://github.com/YOUR_ORG/tf-modules/actions/workflows/terraform-validate.yml/badge.svg)
![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)
![Terraform](https://img.shields.io/badge/terraform-%3E%3D1.4.0-623CE4.svg)

Production-grade Terraform modules for multi-cloud infrastructure. 20 modules across AWS and Azure covering compute, networking, security, and observability.

## Quick Start

```hcl
module "vpc" {
  source      = "github.com/YOUR_ORG/tf-modules//modules/aws/vpc"
  project     = "myapp"
  environment = "production"
  vpc_cidr    = "10.0.0.0/16"
  azs         = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

module "eks" {
  source             = "github.com/YOUR_ORG/tf-modules//modules/aws/eks"
  project            = "myapp"
  environment        = "production"
  kubernetes_version = "1.29"
  subnet_ids         = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.vpc_id
}
```

See [examples/aws-eks-with-addons/](examples/aws-eks-with-addons/) for a complete working composition.

## Module Inventory

### AWS (13 modules)

| Module | Description | Docs |
|--------|-------------|------|
| `modules/aws/vpc` | VPC with public/private subnets, NAT gateway, S3/ECR VPC endpoints | [README](modules/aws/vpc/README.md) |
| `modules/aws/iam` | GitHub OIDC provider, CI plan/apply roles | [README](modules/aws/iam/README.md) |
| `modules/aws/s3-state` | S3 bucket for Terraform remote state with KMS encryption | [README](modules/aws/s3-state/README.md) |
| `modules/aws/dynamodb-lock` | DynamoDB table for state locking with deletion protection | [README](modules/aws/dynamodb-lock/README.md) |
| `modules/aws/kms` | KMS keys for logs, state, and general use | [README](modules/aws/kms/README.md) |
| `modules/aws/logging` | CloudTrail, AWS Config, GuardDuty, S3 log archive | [README](modules/aws/logging/README.md) |
| `modules/aws/monitoring` | CloudWatch alarms, SNS, composite alerts | — |
| `modules/aws/budgets` | Cost budgets and anomaly detection | — |
| `modules/aws/eks` | EKS cluster, managed node groups, IRSA, PSA, cluster autoscaler IRSA | [README](modules/aws/eks/README.md) |
| `modules/aws/eks-addons` | ALB, ExternalDNS, cert-manager, Prometheus, Loki, NTH, Sealed Secrets, Karpenter, EFS CSI | [README](modules/aws/eks-addons/README.md) |
| `modules/aws/ecr` | ECR repositories with lifecycle policies and optional KMS encryption | [README](modules/aws/ecr/README.md) |

### Azure (7 modules)

| Module | Description | Docs |
|--------|-------------|------|
| `modules/azure/resource-group` | Resource group with standard naming and tags | [README](modules/azure/resource-group/README.md) |
| `modules/azure/vnet` | VNet with per-subnet NSGs, DDoS protection, flow logs | [README](modules/azure/vnet/README.md) |
| `modules/azure/aks` | AKS cluster, autoscaling, workload identity, Defender, auto-upgrade | [README](modules/azure/aks/README.md) |
| `modules/azure/key-vault` | Key Vault with RBAC, purge protection, AKS workload identity integration | [README](modules/azure/key-vault/README.md) |
| `modules/azure/monitoring` | Azure Monitor metric alerts for AKS | [README](modules/azure/monitoring/README.md) |
| `modules/azure/container-registry` | ACR with RBAC-only, geo-replication, zone redundancy | [README](modules/azure/container-registry/README.md) |
| `modules/azure/private-dns` | Private DNS zones with VNet links for AKS private clusters | [README](modules/azure/private-dns/README.md) |

### Core (2 modules)

| Module | Description | Docs |
|--------|-------------|------|
| `modules/core/naming` | Consistent resource name generation | [README](modules/core/naming/README.md) |
| `modules/core/tagging` | Unified tag map with required + extra_tags merge | [README](modules/core/tagging/README.md) |

## Examples

| Example | Description |
|---------|-------------|
| `examples/aws-eks-with-addons/` | VPC → EKS → add-ons (NTH, ALB, cert-manager); Helm exec credential |
| `examples/aws-complete/` | Full AWS stack: VPC → EKS → add-ons → monitoring |
| `examples/azure-complete/` | Full Azure stack: RG → VNet → AKS → KV → alerts |

## Design Principles

- **Consistency**: Common `project`/`environment` variable contract and tag standards across all clouds
- **Security by default**: Encryption enabled, least-privilege IAM, private networking, IMDSv2 enforced
- **Environment parity**: Same module interfaces for dev, staging, and production
- **Progressive complexity**: Start simple, add features incrementally through optional variables
- **Documentation-first**: Every module includes usage examples and variable documentation
- **Test coverage**: Terratest smoke tests for every module with skip guards for CI cost control

## Project Structure

```
tf-modules/
├── modules/
│   ├── aws/              # AWS modules (VPC, IAM, EKS, ECR, ...)
│   ├── azure/            # Azure modules (VNet, AKS, ACR, private-dns, ...)
│   └── core/             # Cloud-agnostic (naming, tagging)
├── examples/
│   ├── aws-eks-with-addons/  # EKS + add-ons composition example
│   ├── aws-complete/         # Full AWS composition
│   └── azure-complete/       # Full Azure composition
├── docs/                 # Architecture and design guides
├── policy/               # OPA/Conftest tag enforcement policies
├── tests/
│   ├── aws/              # Terratest for AWS modules
│   └── azure/            # Terratest for Azure modules
└── .github/workflows/    # CI: validate (18-module matrix), plan, apply
```

## Security Hardening

Modules include explicit security controls across all layers:

| Area | Control |
|------|---------|
| AWS S3 state | KMS CMK encryption, public access block |
| AWS DynamoDB lock | Deletion protection |
| AWS KMS | Configurable key rotation, deletion window validation (7–30 days) |
| AWS Logging | GuardDuty, CloudTrail, Config; configurable S3 access log prefix |
| AWS EKS nodes | IMDSv2 enforced; EBS gp3 encrypted root volumes; custom AMI support |
| AWS EKS cluster | Configurable authentication mode; CloudWatch log retention |
| AWS EKS namespace | Pod Security Admission map via `pod_security_standards` |
| AWS EKS ALB | WAFv2 + Shield Advanced via `enable_waf_v2` |
| AWS ECR | Scan-on-push; immutable tags option; KMS encryption |
| Azure AKS | Private cluster; Calico network policy; Microsoft Defender toggle |
| Azure AKS | Auto-upgrade channel; maintenance window; azure_policy_enabled |
| Azure VNet | Deny-all egress NSG per subnet; DDoS protection; flow logs |
| Azure Key Vault | RBAC-only mode; purge protection; soft-delete enforced |
| Azure ACR | Admin account disabled; RBAC-only; Premium geo-replication |

See [docs/aws-security-hardening.md](docs/aws-security-hardening.md) and [docs/azure-security-hardening.md](docs/azure-security-hardening.md).

## CI/CD

- **Validate**: 18-module matrix — `terraform fmt`, `terraform validate` on every push and PR
- **Plan**: Per-environment matrix plan with PR comment output
- **Apply**: Sequential apply on merge to `main` with GitHub environment gates
- **Drift detection**: Scheduled daily plan; opens GitHub issue on drift
- **Pre-commit hooks**: `terraform_fmt`, `terraform_validate`, `terraform_docs`, trailing-whitespace

## Migration Guide

Upgrading from v0.x? See [docs/migration-guide.md](docs/migration-guide.md) for:

- `cluster_version` → `kubernetes_version` rename
- Managed addon versions → `managed_addon_versions` map
- AKS node pool output key changes

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for full release history.

## License

Apache 2.0 — see [LICENSE](LICENSE) for details.
