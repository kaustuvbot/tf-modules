# Testing Guide

## Overview

This project uses [Terratest](https://terratest.gruntwork.io/) for integration tests. Tests deploy real infrastructure against a live AWS account and validate actual resource attributes.

## Test Matrix

| Test | Module | Time | Cost | Skip Flag |
|------|--------|------|------|-----------|
| `TestVpcHappyPath` | aws/vpc | ~2 min | <$0.01 | — |
| `TestEksSmokeTest` | aws/eks | ~12 min | ~$0.30 | `SKIP_EKS_TESTS=true` |

## Prerequisites

```bash
# Install Go 1.21+
go version

# Install Terraform 1.4+
terraform version

# Configure AWS credentials
aws sts get-caller-identity
```

## Running Tests Locally

```bash
cd tests

# Install Go dependencies
go mod download

# Run all tests (uses default region us-east-1)
go test ./aws/... -v -timeout 30m

# Run only fast tests (skip EKS)
SKIP_EKS_TESTS=true go test ./aws/... -v -timeout 10m

# Run a specific test
go test ./aws/ -run TestVpcHappyPath -v -timeout 10m

# Use a different region
AWS_REGION=eu-west-1 go test ./aws/... -v -timeout 30m
```

## Running Tests in CI

Tests run in the GitHub Actions pipeline with the CI plan role. EKS tests are skipped in CI by default to control costs:

```yaml
- name: Run tests
  env:
    SKIP_EKS_TESTS: "true"
  run: |
    cd tests
    go test ./aws/... -v -timeout 20m
```

Enable EKS tests by removing `SKIP_EKS_TESTS` from the workflow environment. Ensure the CI role has `AmazonEKSFullAccess` or equivalent.

## What Tests Validate

### VPC (`vpc_test.go`)

- VPC created with correct CIDR block
- Correct number of public and private subnets
- Each subnet belongs to the created VPC
- Internet Gateway exists when public subnets are configured
- No NAT Gateway when `enable_nat_gateway = false`
- Required tags present on VPC (`Project`, `Environment`, `ManagedBy`)

### EKS (`eks_test.go`)

- EKS cluster name follows `{project}-{environment}-eks` convention
- Cluster endpoint is non-empty
- Certificate authority data is present
- OIDC provider ARN is set (IRSA enabled)
- Node group IAM role ARN is non-empty

## Test Isolation

Each test run uses a unique 4-digit ID suffix (`test-1234-vpc`) to prevent conflicts between parallel runs. Resources are always destroyed via `defer terraform.Destroy()`.

If a test is interrupted, clean up with:

```bash
terraform -chdir=modules/aws/vpc destroy -auto-approve \
  -var="project=test-1234" \
  -var="environment=dev" \
  -var="vpc_cidr=10.100.0.0/16" \
  # ... other required vars
```

Or use the AWS Console to search for resources tagged `TestRun=1234`.

## Adding New Tests

1. Create `tests/aws/<module>_test.go`
2. Follow the pattern: `InitAndApply` → validate outputs → `defer Destroy`
3. Use `uniqueID(t)` for resource name suffix
4. Add the test to the matrix table in this doc
5. Set a conservative `t.Parallel()` — avoid paralleling EKS tests
