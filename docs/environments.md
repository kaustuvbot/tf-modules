# Environments Guide

## Overview

The `environments/` directory contains per-environment root modules that compose the reusable modules into full infrastructure stacks.

```
environments/
├── dev/        # Development: cost-optimised, open API access
├── staging/    # Staging: mirrors prod configuration but smaller
└── prod/       # Production: hardened, HA, encrypted
```

## Environment Philosophy

| Concern | Dev | Staging | Prod |
|---------|-----|---------|------|
| NAT gateways | Single (cost) | Single | Per-AZ (HA) |
| EKS API access | Public, open | Public + CIDR | Private |
| IMDSv2 | Required | Required | Required |
| Secrets encryption (KMS) | Off | Optional | On |
| VPC flow logs | Off | Optional | On |
| Node instance size | t3.medium | m5.large | m5.large |
| Min node count | 1 | 2 | 2 |

## Deploying an Environment

```bash
cd environments/dev

# Initialise backend (first time)
terraform init \
  -backend-config="bucket=myproject-dev-tfstate-123456789" \
  -backend-config="key=dev/platform/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=myproject-dev-tflock"

# Plan
terraform plan -var="project=myproject"

# Apply
terraform apply -var="project=myproject"
```

## Backend Setup

Before deploying any environment, provision the S3 state bucket and DynamoDB lock table:

```hcl
# bootstrap/main.tf
module "state" {
  source      = "../modules/aws/s3-state"
  bucket_name = "myproject-dev-tfstate-${data.aws_caller_identity.current.account_id}"
}

module "lock" {
  source     = "../modules/aws/dynamodb-lock"
  table_name = "myproject-dev-tflock"
}
```

## Variable Overrides

Each environment ships with sensible defaults in `variables.tf`. Override them with a `terraform.tfvars` file or `-var` flags:

```hcl
# environments/dev/terraform.tfvars
project             = "myproject"
eks_cluster_version = "1.28"
eks_public_access_cidrs = ["10.0.0.0/8"]
```

## CI/CD Integration

The GitHub Actions workflows (`.github/workflows/`) automatically detect which environment changed and run plan/apply against it. Each environment maps to a GitHub Environment with required reviewers for `apply`.

See [the CI workflows](../.github/workflows/) for full details.
