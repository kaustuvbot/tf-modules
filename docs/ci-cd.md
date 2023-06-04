# CI/CD Pipeline Documentation

## Overview

This project uses GitHub Actions for continuous integration and deployment. Three workflows handle the full lifecycle:

1. **Validate** — format and syntax checks on every PR
2. **Plan** — terraform plan per environment on every PR
3. **Apply** — terraform apply on merge to main, with approval gates

## Workflow Architecture

```
PR opened/updated
  ├── terraform-validate.yml
  │     ├── fmt check
  │     ├── validate (per module, matrix)
  │     └── security scan (tfsec + checkov)
  └── terraform-plan.yml
        └── plan (per environment, matrix)
              └── PR comment with plan output

Merge to main
  └── terraform-apply.yml
        ├── detect changed environments
        └── apply (sequential, with environment protection)
```

## Workflows

### terraform-validate.yml

**Trigger**: PR targeting `main` with changes to `modules/`, `environments/`, `bootstrap/`, `examples/`, or `*.tf`

**Jobs**:
- `fmt`: Runs `terraform fmt -check -recursive -diff`
- `validate`: Matrix job across all modules — runs `terraform init -backend=false` and `terraform validate`
- `security`: Runs tfsec and checkov against `modules/` directory (soft-fail initially)

### terraform-plan.yml

**Trigger**: PR targeting `main` with changes to `environments/`

**Authentication**: OIDC federation using the CI plan role (read-only)

**Jobs**:
- `plan`: Matrix job across environments (dev, staging, prod)
  - Runs `terraform plan`
  - Posts output as PR comment
  - Uploads plan artifact (5-day retention)

### terraform-apply.yml

**Trigger**: Push to `main` with changes to `environments/`

**Authentication**: OIDC federation using the CI apply role (read-write)

**Jobs**:
- `detect-changes`: Determines which environments were modified
- `apply`: Sequential per-environment apply with GitHub environment protection

## Required Secrets

| Secret | Description | Used By |
|--------|-------------|---------|
| `AWS_PLAN_ROLE_ARN` | ARN of the CI plan IAM role | terraform-plan |
| `AWS_APPLY_ROLE_ARN` | ARN of the CI apply IAM role | terraform-apply |

## GitHub Environment Protection

Configure these environments in GitHub repository settings:

| Environment | Recommended Protection |
|-------------|----------------------|
| `dev` | No protection (auto-apply) |
| `staging` | Require 1 reviewer |
| `prod` | Require 2 reviewers + wait timer |

## Security Scanning

Both tfsec and checkov run in **soft-fail mode** during the initial rollout phase. Once baselines are established, switch to hard-fail by removing `soft_fail: true` from the workflow.

### Suppressing False Positives

For tfsec, add inline comments:
```hcl
resource "aws_s3_bucket" "example" {
  #tfsec:ignore:aws-s3-enable-bucket-logging
  bucket = "my-bucket"
}
```

For checkov, use `.checkov.yml`:
```yaml
skip-check:
  - CKV_AWS_18  # S3 bucket logging
```

## Adding New Modules

When adding a new module, update the validate workflow matrix:

```yaml
matrix:
  module:
    - modules/aws/vpc
    - modules/aws/your-new-module  # add here
```

## Debugging Failed Workflows

1. Check the workflow run logs in the Actions tab
2. For plan failures: review the PR comment for error details
3. For auth failures: see [OIDC troubleshooting](aws-iam-oidc.md#troubleshooting)
4. For security scan findings: review the tfsec/checkov output in the job logs
